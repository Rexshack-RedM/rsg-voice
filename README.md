# rsg-voice

Proximity voice for **RSG Framework (RedM)**, built on RedM's native Mumble voice. It adds selectable voice ranges, a draggable HUD, automatic muting while dead or cuffed, and a server-enforced admin mute.

---

## Features

- **Proximity voice ranges**: Whisper (2.5m), Normal (8m) and Shout (20m), all configurable.
- **Cycle range** with a key (default **Z**) or the `/voice` command.
- **Range ring**: a ground ring briefly shows how far your voice carries when you change range.
- **Always hear shouting**: you hear players out to the largest range, whatever your own range is.
- **Draggable HUD**: a compact indicator shows your range, a talking light and your muted state. Move it with `/voicehud`; each player's position is saved on their own client.
- **Auto-mute** while dead or in last stand, and optionally while cuffed (read from rsg-core metadata).
- **Admin mute**: `/voicemute [id]` mutes on the server, so the player's client can't undo it. Mutes are tied to the player's licence, so they survive a reconnect (they reset when the server restarts).
- **Exports** so other resources (radio, phone and so on) can read or set the range.
- **State bag**: `Player(src).state.voiceRange` holds each player's current range.
- **ox_lib** notifications and locales in 10 languages: en, de, el, es, fr, ja, nl, pl, pt-br, ro.
- Leather & gold themed UI, no vignette.

---

## Requirements

- [rsg-core](https://github.com/Rexshack-RedM/rsg-core)
- [ox_lib](https://github.com/overextended/ox_lib)

> Do **not** run another voice resource (pma-voice, saltychat, etc.) alongside this one. They will fight over voice settings.

---

## Installation

1. Drop the `rsg-voice` folder into your `resources` directory (for example `resources/[rsg]/rsg-voice`).
2. Add the voice settings and the resource to your `server.cfg`, after `rsg-core` and `ox_lib`:

```cfg
# Native voice
setr voice_useNativeAudio true
setr voice_use3dAudio true
setr voice_useSendingRangeOnly true

# Language (en, de, el, es, fr, ja, nl, pl, pt-br, ro)
setr ox:locale en

ensure ox_lib
ensure rsg-core
ensure rsg-voice
```

3. Make sure your admins have the `group.admin` ace so they can use `/voicemute`:

```cfg
add_ace group.admin command allow
add_principal identifier.license:YOUR_LICENSE group.admin
```

4. Restart the server.

---

## Usage

### Players

| Action | How |
|---|---|
| Cycle voice range | Press **Z**, or type `/voice` |
| Move the HUD | Type `/voicehud`, drag the box, then press **ENTER** / **ESC** to save or **R** to reset |

HUD indicators:
- **Bars**: current range (more bars means a larger range)
- **Green dot**: you are talking
- **Red dot and struck-through label**: you are muted

### Admins

| Command | Description |
|---|---|
| `/voicemute [id]` | Toggle a server-enforced voice mute on a player |

---

## Configuration

All settings are in `shared/config.lua`.

```lua
Config.Ranges = {
    { name = 'whisper', range = 2.5 },
    { name = 'normal',  range = 8.0, default = true },
    { name = 'shout',   range = 20.0 },
}
```

| Option | Default | Description |
|---|---|---|
| `Config.Ranges` | see above | Voice ranges in metres. `default = true` sets the starting range. |
| `Config.CycleKey` | `0x26E9DC00` (Z) | Control hash used to cycle range |
| `Config.CycleCommand` | `'voice'` | Command to cycle range |
| `Config.ShowRangeRing` | `true` | Show a ground ring when changing range |
| `Config.RingDuration` | `1500` | How long the ring shows (ms) |
| `Config.RingColour` | white, alpha 90 | RGBA colour of the ring |
| `Config.ShowHud` | `true` | Show the voice HUD |
| `Config.HudEditCommand` | `'voicehud'` | Command to move the HUD |
| `Config.MuteWhenDead` | `true` | Mute while dead or in last stand |
| `Config.MuteWhenCuffed` | `false` | Mute while handcuffed |
| `Config.AdminMuteCommand` | `'voicemute'` | Admin mute command |

### Adding a range

Add an entry to `Config.Ranges`, then add a `range_<name>` key to each file in `locales/`:

```lua
{ name = 'megaphone', range = 40.0 },
```
```json
"range_megaphone": "Megaphone"
```

If a locale key is missing, the HUD shows the raw `name`.

---

## Exports (client)

```lua
-- Current range in metres
local range = exports['rsg-voice']:GetVoiceRange()

-- Set range by its index in Config.Ranges
exports['rsg-voice']:SetVoiceRangeIndex(3)

-- Is the player muted (dead, cuffed or admin)?
local muted = exports['rsg-voice']:IsMuted()
```

### State bag

```lua
-- Server or client
local range = Player(serverId).state.voiceRange
```

---

## Localisation

Locale files are in `locales/*.json`. Set the server language with `setr ox:locale <code>`; players can also pick their own language in ox_lib's settings.

Supported languages: `en`, `de`, `el`, `es`, `fr`, `ja`, `nl`, `pl`, `pt-br`, `ro`.

---

## File structure

```
rsg-voice/
├── client/client.lua
├── server/server.lua
├── server/versionchecker.lua
├── shared/config.lua
├── html/index.html
├── locales/*.json
└── fxmanifest.lua
```
