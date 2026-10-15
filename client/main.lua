local busy = false
local lastRescue = 0
local lastManual = 0
local lastSafe = nil
local lastSafeTick = 0
local underSince = nil

local function inIgnoredZone(coords)
    for i = 1, #Config.IgnoredZones do
        local z = Config.IgnoredZones[i]
        if #(coords - z.coords) <= z.radius then return true end
    end
    return false
end

local function getMovingEntity(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then return veh end
    return ped
end

local function fade(out)
    if Config.FadeMs <= 0 then return end
    local timeout = GetGameTimer() + 2000
    if out then
        DoScreenFadeOut(Config.FadeMs)
        while not IsScreenFadedOut() and GetGameTimer() < timeout do Wait(0) end
    else
        DoScreenFadeIn(Config.FadeMs)
    end
end

local function teleport(dest)
    local ent = getMovingEntity(PlayerPedId())

    fade(true)
    FreezeEntityPosition(ent, true)
    SetEntityCoordsNoOffset(ent, dest.x, dest.y, dest.z, false, false, false)
    SetEntityHeading(ent, dest.w or 0.0)
    SetEntityVelocity(ent, 0.0, 0.0, 0.0)

    local timeout = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ent) and GetGameTimer() < timeout do
        RequestCollisionAtCoord(dest.x, dest.y, dest.z)
        Wait(0)
    end

    FreezeEntityPosition(ent, false)
    fade(false)
end

local function rescue(manual)
    if busy then return end
    busy = true
    lastRescue = GetGameTimer()
    underSince = nil

    local dest = (Config.UseLastSafePosition and lastSafe) or Config.FallbackCoords
    teleport(dest)

    Bridge.Notify(manual and Config.Text.manual_rescued or Config.Text.auto_rescued, 'success')
    busy = false
end

-- Auto detection loop
CreateThread(function()
    while true do
        local wait = Config.CheckIntervalNormal
        local ped = PlayerPedId()

        if not busy and not IsEntityDead(ped) then
            local coords = GetEntityCoords(ped)
            local now = GetGameTimer()

            if coords.z < Config.MinZ and not inIgnoredZone(coords) then
                wait = Config.CheckIntervalUnder
                underSince = underSince or now

                if now - underSince >= Config.ConfirmMs and now - lastRescue >= Config.AutoRescueCooldownMs then
                    rescue(false)
                end
            else
                underSince = nil

                -- Remember where the player last stood safely
                if Config.UseLastSafePosition
                    and now - lastSafeTick >= Config.SafePositionIntervalMs
                    and coords.z > Config.MinZ + 10.0
                    and not IsPedFalling(ped)
                    and not IsEntityInAir(getMovingEntity(ped)) then
                    lastSafeTick = now
                    lastSafe = vector4(coords.x, coords.y, coords.z, GetEntityHeading(ped))
                end
            end
        end

        Wait(wait)
    end
end)

-- Manual command
RegisterCommand(Config.CommandName, function()
    local ped = PlayerPedId()
    local now = GetGameTimer()

    if IsEntityDead(ped) then
        return Bridge.Notify(Config.Text.dead, 'error')
    end
    if busy or now - lastManual < Config.ManualCooldownMs then
        return Bridge.Notify(Config.Text.cooldown, 'error')
    end
    if Config.ManualRequiresLowZ and GetEntityCoords(ped).z > Config.ManualMaxZ then
        return Bridge.Notify(Config.Text.not_stuck, 'error')
    end

    lastManual = now
    rescue(true)
end, false)
