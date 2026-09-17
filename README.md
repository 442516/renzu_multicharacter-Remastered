# renzu_multicharacter-Remastered

A community-maintained continuation of **renzu_multicharacter**.

This project is based on the original resource by **renzu**. The original character-selection UI and general flow are kept as the foundation. The work here focuses on keeping the resource usable on newer FiveM setups and separating framework, appearance, and spawn integrations from the main code.

This is a remaster and maintenance project, not a claim of original authorship.

![image](https://user-images.githubusercontent.com/82306584/204663183-47535b6d-1f4c-4a4a-9bff-7f9132dcd50b.png)

## Features

- ESX, QBCore, and QBox support.
- Automatic framework detection, with manual configuration available.
- Appearance support for:
  - `rcore_clothing`
  - `illenium-appearance`
  - `fivem-appearance`
  - `qb-clothing`
  - `esx_skin`
  - `skinchanger`
- Configurable spawn handling:
  - built-in `renzu_multicharacter` selector
  - `renzu_spawn`
  - `qb-spawn`
  - `qbx_spawn`
  - `none`
- Local intro music through the NUI page.
- Character position saving on relog and disconnect.
- Framework starter items with fallback items.
- Optional logo, camera, and preview animation settings.
- Locale strings in `shared/locale.lua`.
- Nationality data in `shared/nationalities.json`.
- Framework, appearance, and spawn integrations kept in bridge files.

## Original flow

The original character-selection experience remains the main focus of this resource.

Character selection, character creation, deletion, the preview camera, registration, and the general UI flow are intentionally kept close to the original version.

The goal is to modernize the resource without turning it into a completely different multicharacter system.

## Configuration

The main settings are in `config.lua`.

```lua
Config.Framework = 'auto'
Config.Appearance = 'auto'
Config.SpawnSystem = 'renzu_multicharacter'
```

Use `auto` to detect a supported resource that is running, or set a specific value manually.

New characters use `Config.NewCharacterSpawn` when `Config.UseNewCharacterSpawn` is enabled. Set that option to `false` if the selected external spawn system should handle new-character placement instead.

## Spawn systems

The available spawn modes are:

- `renzu_multicharacter` — use the built-in selector.
- `renzu_spawn` — use the standalone `renzu_spawn` resource.
- `qb-spawn` — use QBCore's spawn resource.
- `qbx_spawn` — use the QBox-compatible spawn integration.
- `none` — do not open a spawn selector. The resource fires `renzu_multicharacter:spawnRequested` instead.

The `qbx_spawn` integration should be tested against the exact QBox version used by your server.

## Player states

![image](https://user-images.githubusercontent.com/82306584/204690922-e62e1043-62c1-4393-a918-43131e0a75f2.png)

Character list cards can show a badge for a player's current state (dead, in a vehicle, admin, cuffed, and so on) once that state is set. The `RegisterStates` export from the original resource still works the same way:

```lua
exports.renzu_multicharacter:RegisterStates('invehicle', function()
	if not lib then return end
	lib.onCache('vehicle', function(value)
		LocalPlayer.state:set('invehicle', value and {net = NetworkGetNetworkIdFromEntity(value)} or false, true)
	end)
end, false)
```

## Commands

- `/relog` — return to character selection.
- `/updatecharslots <id> <slots>` — update a player's character-slot count. Permission handling comes from the active framework.

## Requirements

Required:

- `oxmysql`
- One supported framework:
  - `es_extended`
  - `qb-core`
  - `qbx_core`

Use one supported appearance system if appearance creation/loading is enabled.

External spawn resources are only required when selected in `Config.SpawnSystem`.

`qb-apartments` is optional.

## ESX setup

For ESX Legacy, enable multicharacter support in your ESX configuration.

Older ESX databases may also need the character fields used by your setup, such as:

- `skin`
- `firstname`
- `lastname`
- `dateofbirth`
- `sex`
- `height`

Check your existing `users` table before adding anything. Do not add duplicate columns.

## QBCore / QBox setup

QBCore and QBox use their own character data and identifiers.

On QBox, make sure QBox's own character-selection screen is not running at the same time as this resource. Configure QBox to use an external character selector when required by your setup.

## Appearance systems

Appearance handling is separated from the main character-selection code.

When `rcore_clothing` is selected, its appearance data is handled through the rcore bridge rather than being saved as a second framework skin record.

The other supported appearance systems use their own supported skin format and bridge.

If you add another appearance resource, add its implementation under `bridge/appearance/` instead of placing resource-specific calls throughout the main client code.

## Project layout

- `client/main.lua` — main client flow.
- `server/main.lua` — main server flow.
- `bridge/framework/` — framework integrations.
- `bridge/appearance/` — appearance integrations.
- `bridge/spawn/` — spawn integrations.
- `shared/locale.lua` — UI translations.
- `shared/nationalities.json` — nationality list.
- `config_spawns.lua` — built-in spawn locations.
- `web/` — NUI files and local audio.

## Credits

Original resource and concept by **renzu**:

- https://github.com/renzuzu/renzu_multicharacter
- https://forum.cfx.re/t/renzu-spawn-character-spawn-selector/4959467

This repository is a community remaster of the original work. Please keep the original credit and license when modifying or redistributing it.

## License

GNU General Public License v3.0. See `LICENSE` for the full license text.

## About this project

The idea is simple: keep a good old resource alive without changing what made it useful.

The original `renzu_multicharacter` had a clean character-selection flow. This project keeps that foundation and moves the framework, appearance, and spawn-specific work into separate bridges so the resource is easier to maintain over time.
