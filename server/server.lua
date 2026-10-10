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
