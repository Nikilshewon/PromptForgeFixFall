# AuraFixFall

Automatically rescues players who fall under the map, with a `/fixfall` command as a manual backup.

**Author:** PromptForge  
**Version:** 2.0.0

## Features

- Auto-detects players falling below the map and teleports them back
- Returns players to their **last safe position** (falls back to configurable coordinates)
- Confirm delay to avoid false triggers
- Smooth screen fade and collision loading so players don't fall twice
- Vehicle support (drivers are teleported with their vehicle)
- Ignored zones for legitimate underground areas (e.g. custom MLOs)
- Manual `/fixfall` command with cooldown and optional low-Z requirement
- Lightweight: relaxed checks when safe, fast checks only when below the map
- Fully editable messages

## Supported Frameworks

| Framework  | Detection        |
|------------|------------------|
| QBox       | `qbx_core`       |
| QBCore     | `qb-core`        |
| ESX        | `es_extended`    |
| Standalone | none of the above |

The framework is detected automatically and is only used for notifications, so there are no hard dependencies. You can force one with `Config.Framework`.

## Installation

1. Download the latest release or clone this repository.
2. Place the `AuraFixFall` folder in your server's `resources` directory.
3. Add this to your `server.cfg`:

```
ensure AuraFixFall
```

4. Adjust `config.lua` to your liking and restart the resource.

## Configuration

All options live in `config.lua`.

| Option | Default | Description |
|--------|---------|-------------|
| `Framework` | `'auto'` | `auto`, `qbox`, `qbcore`, `esx` or `standalone` |
| `MinZ` | `-35.0` | Below this height the player counts as under the map |
| `FallbackCoords` | Legion Square | Used when no safe position is stored |
| `UseLastSafePosition` | `true` | Return players to where they last stood safely |
| `ConfirmMs` | `400` | Time below `MinZ` before a rescue triggers |
| `AutoRescueCooldownMs` | `8000` | Minimum time between auto rescues |
| `FadeMs` | `300` | Screen fade duration (0 to disable) |
| `CommandName` | `'fixfall'` | Manual command name |
| `ManualCooldownMs` | `5000` | Cooldown for the manual command |
| `ManualRequiresLowZ` | `false` | Only allow `/fixfall` when below `ManualMaxZ` |
| `IgnoredZones` | `{}` | Areas where being low is allowed |
| `Text` | - | All notification messages |

### Ignored zone example

```lua
Config.IgnoredZones = {
    { coords = vector3(100.0, 200.0, -60.0), radius = 50.0 },
}
```

## Usage

- **Automatic:** nothing to do. Falling under the map triggers a rescue.
- **Manual:** type `/fixfall` if you get stuck.

## Credits

Created by **PromptForge**.
