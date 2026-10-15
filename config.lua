Config = {}

-- 'auto' detects qbx_core > qb-core > es_extended, otherwise standalone.
-- Or force one: 'qbox' | 'qbcore' | 'esx' | 'standalone'
Config.Framework = 'auto'

-- Player is considered "under the map" below this Z value
Config.MinZ = -35.0

-- Used when no last safe position is stored
Config.FallbackCoords = vector4(195.17, -933.77, 30.69, 144.0)

-- Return the player to the last place they were safely standing (falls back to FallbackCoords)
Config.UseLastSafePosition = true
Config.SafePositionIntervalMs = 2000

-- Check intervals (ms): relaxed when safe, fast when below MinZ
Config.CheckIntervalNormal = 400
Config.CheckIntervalUnder = 75

-- Player must stay below MinZ this long before the auto rescue fires (avoids false triggers)
Config.ConfirmMs = 400
Config.AutoRescueCooldownMs = 8000

-- Screen fade during teleport (0 to disable)
Config.FadeMs = 300

-- Manual command
Config.CommandName = 'fixfall'
Config.ManualCooldownMs = 5000
Config.ManualRequiresLowZ = false
Config.ManualMaxZ = -10.0

-- Areas where being below MinZ is legitimate (e.g. custom underground MLOs)
-- { coords = vector3(x, y, z), radius = 50.0 }
Config.IgnoredZones = {}

Config.Text = {
    auto_rescued   = 'You fell under the map and were teleported back.',
    manual_rescued = 'You have been teleported to a safe position.',
    not_stuck      = 'You do not appear to be stuck.',
    cooldown       = 'Please wait before using this again.',
    dead           = 'You cannot use this while dead.',
}
