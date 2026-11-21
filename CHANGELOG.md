# Changelog

All notable changes to rsg-voice. Newest first.

## 3.1.1

### Added
- Radio static: squelch burst when a transmission starts/ends and a low hiss while someone transmits on your channel (WebAudio in `html/index.html`). `Config.Radio.Static` (`Enabled`, `Volume`, `Hiss`, `Squelch`, `SelfHiss`).

## 3.1.0

### Added
- Radio channels (audio only). Server exports `JoinRadio(src, freq)`, `LeaveRadio(src)`, `GetPlayerRadio(src)`, `GetRadioMembers(freq)`; client exports `GetRadio()`, `IsRadioTalking()`, `GetRadioTalkKey()`; server event `rsg-voice:server:radioChanged`; local client event `rsg-voice:client:onRadioTalk`.
- `Config.Radio` (`Enabled`, `TalkKey`, `NearbyHear`, `MaxMembers`) and `Config.TalkIcon.RadioColour`.
- HUD `RADIO <freq>` tag, lit green while transmitting. New `ui_radio` locale key (all 11 languages).

### Changed
- Party talk yields to the radio while the radio key is held.

## 3.0.5

### Added
- `Config.AutoDatabase` (default `true`): the database tables are built automatically on start. Set it to `false` to skip the auto-build and import the bundled SQL file manually instead.

### Documentation
- `DOCS.md`: added a generated technical reference (dependencies, database, configuration, exports, callbacks, events, commands, items, locales) with code examples, read straight from the source.
