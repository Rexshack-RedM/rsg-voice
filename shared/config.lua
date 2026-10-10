Config = {}

-- Voice ranges (metres). The entry with default = true is used on spawn.
Config.Ranges = {
    { name = 'whisper', range = 2.5 },
    { name = 'normal',  range = 8.0, default = true },
    { name = 'shout',   range = 20.0 },
}

Config.CycleKey     = 0xA5BDCD3C -- RIGHTBRACKET
Config.CycleCommand = 'voice'

-- Ground ring shown when changing range
Config.ShowRangeRing = true
Config.RingDuration  = 1500
Config.RingColour    = { r = 255, g = 255, b = 255, a = 90 }

-- HUD
Config.ShowHud        = true
Config.HudEditCommand = 'voicehud' -- drag the HUD box to move it

-- Auto-mute (rsg-core metadata)
Config.MuteWhenDead   = true
Config.MuteWhenCuffed = false

-- Admin mute (server-enforced)
Config.AdminMuteCommand = 'voicemute'
