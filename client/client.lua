local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

local Ranges      = Config.Ranges
local rangeCount  = #Ranges
local currentIdx  = 1
local maxRange    = 0.0
local stateMute   = false -- dead / last stand / cuffed
local adminMute   = false
local ringUntil   = 0
local loaded      = false

for i, r in ipairs(Ranges) do
    if r.default then currentIdx = i end
    if r.range > maxRange then maxRange = r.range end
end

local isTalking = MumbleIsPlayerTalking or NetworkIsPlayerTalking

local function isMuted() return stateMute or adminMute end

local function rangeLabel(i)
    local key = 'range_' .. Ranges[i].name
    local txt = locale(key)
    return (txt and txt ~= key) and txt or Ranges[i].name
end

local function notify(key, nType, ...)
    lib.notify({ title = locale('notify_title'), description = locale(key, ...), type = nType, duration = 3000 })
end

local function sendHud()
    if not Config.ShowHud then return end
    SendNUIMessage({
        action = 'update',
        show   = loaded,
        label  = rangeLabel(currentIdx),
        index  = currentIdx,
        total  = rangeCount,
        muted  = isMuted(),
    })
end

local function applyVoice()
    local range = Ranges[currentIdx].range
    MumbleSetAudioInputDistance(isMuted() and 0.0 or range)
    MumbleSetTalkerProximity(range)
    MumbleSetAudioOutputDistance(maxRange) -- always hear shouting players
    LocalPlayer.state:set('voiceRange', range, true)
    sendHud()
end

local function setRange(i, showFeedback)
    if not Ranges[i] then return end
    currentIdx = i
    applyVoice()
    if showFeedback then
        if Config.ShowRangeRing then ringUntil = GetGameTimer() + Config.RingDuration end
        notify('cl_range_set', 'inform', rangeLabel(i))
    end
end

local function cycleRange()
    if not loaded then return end
    if isMuted() then return notify('cl_muted', 'error') end
    setRange(currentIdx % rangeCount + 1, true)
end

local function refreshStateMute(md)
    md = md or {}
    local should = (Config.MuteWhenDead and (md.isdead or md.inlaststand))
        or (Config.MuteWhenCuffed and md.ishandcuffed) or false
    if should ~= stateMute then
        stateMute = should
        applyVoice()
    end
end

local function init()
    loaded = true
    adminMute = lib.callback.await('rsg-voice:server:isMuted', false) or false
    stateMute = false
    refreshStateMute((RSGCore.Functions.GetPlayerData() or {}).metadata)
    setRange(currentIdx, false)
    if Config.ShowHud then
        SendNUIMessage({ action = 'locale', hint = locale('cl_hud_hint') })
    end
end

---------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------
RegisterCommand(Config.CycleCommand, cycleRange, false)

RegisterCommand(Config.HudEditCommand, function()
    if not Config.ShowHud or not loaded then return end
    sendHud()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'edit' })
end, false)

RegisterNUICallback('closeEdit', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

---------------------------------------------------------------------
-- Events
---------------------------------------------------------------------
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    init()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    loaded = false
    sendHud()
end)

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(data)
    if loaded then refreshStateMute(data and data.metadata) end
end)

RegisterNetEvent('rsg-voice:client:adminMute', function(state)
    if GetInvokingResource() then return end -- only accept from server
    adminMute = state == true
    applyVoice()
    notify(adminMute and 'cl_admin_muted' or 'cl_admin_unmuted', adminMute and 'error' or 'success')
end)

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() and LocalPlayer.state.isLoggedIn then init() end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)

---------------------------------------------------------------------
-- Threads
---------------------------------------------------------------------
-- Key input + range ring (per-frame only while logged in)
CreateThread(function()
    while true do
        if loaded then
            if IsControlJustReleased(0, Config.CycleKey) then cycleRange() end
            if GetGameTimer() < ringUntil then
                local c   = GetEntityCoords(cache.ped)
                local d   = Ranges[currentIdx].range * 2.0
                local col = Config.RingColour
                Citizen.InvokeNative(0x2A32FAA57B937173, 0x94FDAE17, c.x, c.y, c.z - 0.95,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, d, d, 0.25, col.r, col.g, col.b, col.a,
                    false, false, 2, false, nil, nil, false)
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Talking indicator (no need to poll every frame)
if Config.ShowHud then
    CreateThread(function()
        local last
        while true do
            if loaded then
                local t = isTalking(cache.playerId)
                local talking = t == true or t == 1
                if talking ~= last then
                    last = talking
                    SendNUIMessage({ action = 'talking', state = talking })
                end
                Wait(100)
            else
                last = nil
                Wait(500)
            end
        end
    end)
end

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------
exports('GetVoiceRange', function() return Ranges[currentIdx].range end)
exports('SetVoiceRangeIndex', function(i) setRange(tonumber(i), false) end)
exports('IsMuted', isMuted)
