lib.locale()

-- Keyed by license so a mute survives reconnects
local muted = {}

local function getLicense(src)
    return GetPlayerIdentifierByType(src, 'license')
end

local function serverNotify(src, key, nType, ...)
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('notify_title'), description = locale(key, ...), type = nType, duration = 4000,
    })
end

local function applyMute(src, state)
    MumbleSetPlayerMuted(src, state) -- enforced server-side, client can't bypass
    TriggerClientEvent('rsg-voice:client:adminMute', src, state)
end

lib.addCommand(Config.AdminMuteCommand, {
    help = locale('sv_cmd_help'),
    params = { { name = 'id', type = 'playerId', help = locale('sv_cmd_id') } },
    restricted = 'group.admin',
}, function(source, args)
    local target = args.id
    local license = target and getLicense(target)
    if not license then return serverNotify(source, 'sv_invalid_player', 'error') end

    local state = not muted[license]
    muted[license] = state or nil
    applyMute(target, state)
    serverNotify(source, state and 'sv_muted' or 'sv_unmuted', 'inform', GetPlayerName(target))
end)

lib.callback.register('rsg-voice:server:isMuted', function(src)
    local license = getLicense(src)
    local state = license and muted[license] or false
    if state then MumbleSetPlayerMuted(src, true) end
    return state
end)

---------------------------------------------------------------------
-- Riding party
---------------------------------------------------------------------
if not Config.Party.Enabled then return end

local RSGCore = exports['rsg-core']:GetCoreObject()
local P       = Config.Party
local parties = {}   -- [partyId] = { leader = src, members = { src, ... } }
local playerParty = {} -- [src] = partyId
local invites = {}   -- [targetSrc] = { party = partyId, from = src, expires = os.time() }
local nextId  = 0

local function charName(src)
    local p = RSGCore.Functions.GetPlayer(src)
    local ci = p and p.PlayerData.charinfo
    if ci and ci.firstname then return ('%s %s'):format(ci.firstname, ci.lastname or '') end
    return GetPlayerName(src) or ('#' .. src)
end

local function memberIndex(party, src)
    for i, m in ipairs(party.members) do if m == src then return i end end
end

local function partyPayload(id)
    local party = parties[id]
    if not party then return nil end
    local list = {}
    for _, m in ipairs(party.members) do
        list[#list + 1] = { id = m, name = charName(m), leader = m == party.leader }
    end
    return { id = id, leader = party.leader, members = list, max = P.MaxMembers }
end

local function syncParty(id)
    local party = parties[id]
    if not party then return end
    local data = partyPayload(id)
    for _, m in ipairs(party.members) do
        TriggerClientEvent('rsg-voice:client:partyUpdate', m, data)
    end
end

local function removeFromParty(src, kicked)
    local id = playerParty[src]
    local party = id and parties[id]
    if not party then return end
    local idx = memberIndex(party, src)
    if idx then table.remove(party.members, idx) end
    playerParty[src] = nil
    TriggerClientEvent('rsg-voice:client:partyUpdate', src, nil)
    if GetPlayerName(src) then
        serverNotify(src, kicked and 'sv_party_kicked' or 'sv_party_left', kicked and 'error' or 'inform')
    end

    if #party.members <= 1 then
        -- party of one is disbanded
        for _, m in ipairs(party.members) do
            playerParty[m] = nil
            TriggerClientEvent('rsg-voice:client:partyUpdate', m, nil)
            serverNotify(m, 'sv_party_disbanded', 'inform')
        end
        parties[id] = nil
        return
    end
    if party.leader == src then party.leader = party.members[1] end
    syncParty(id)
end

local function isNear(a, b)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if pa == 0 or pb == 0 then return false end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb)) <= P.InviteRange
end

lib.callback.register('rsg-voice:server:getParty', function(src)
    local list = {}
    local myParty = playerParty[src]
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if id ~= src and isNear(src, id) and (not myParty or playerParty[id] ~= myParty) then
            list[#list + 1] = { id = id, name = charName(id), busy = playerParty[id] ~= nil }
        end
    end
    return { party = myParty and partyPayload(myParty) or nil, nearby = list, me = src }
end)

RegisterNetEvent('rsg-voice:server:partyInvite', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == src or not GetPlayerName(target) then return end
    if not isNear(src, target) then return serverNotify(src, 'sv_party_too_far', 'error') end
    if playerParty[target] then return serverNotify(src, 'sv_party_busy', 'error') end

    local id = playerParty[src]
    if id and parties[id].leader ~= src then return serverNotify(src, 'sv_party_not_leader', 'error') end
    if id and #parties[id].members >= P.MaxMembers then return serverNotify(src, 'sv_party_full', 'error') end
    if not id then
        nextId = nextId + 1
        id = nextId
        parties[id] = { leader = src, members = { src } }
        playerParty[src] = id
        syncParty(id)
    end

    invites[target] = { party = id, from = src, expires = os.time() + P.InviteTimeout }
    TriggerClientEvent('rsg-voice:client:partyInvite', target, charName(src), P.InviteTimeout)
    serverNotify(src, 'sv_party_invited', 'inform', charName(target))
end)

RegisterNetEvent('rsg-voice:server:partyRespond', function(accept)
    local src = source
    local inv = invites[src]
    invites[src] = nil
    if not inv then return end
    local party = parties[inv.party]
    if not party or os.time() > inv.expires then return serverNotify(src, 'sv_party_expired', 'error') end
    if not accept then return serverNotify(inv.from, 'sv_party_declined', 'inform', charName(src)) end
    if playerParty[src] then return end
    if #party.members >= P.MaxMembers then return serverNotify(src, 'sv_party_full', 'error') end

    party.members[#party.members + 1] = src
    playerParty[src] = inv.party
    for _, m in ipairs(party.members) do
        if m ~= src then serverNotify(m, 'sv_party_joined', 'success', charName(src)) end
    end
    syncParty(inv.party)
end)

RegisterNetEvent('rsg-voice:server:partyKick', function(target)
    local src = source
    target = tonumber(target)
    local id = playerParty[src]
    if not id or parties[id].leader ~= src or target == src or playerParty[target] ~= id then return end
    removeFromParty(target, true)
end)

RegisterNetEvent('rsg-voice:server:partyLeave', function()
    removeFromParty(source, false)
end)

AddEventHandler('playerDropped', function()
    local src = source
    invites[src] = nil
    removeFromParty(src, false)
end)

AddEventHandler('RSGCore:Server:OnPlayerUnload', function(src)
    invites[src] = nil
    removeFromParty(src, false)
end)
