local isOpen = false
local winCache = {}

local function notify(msg, kind)
    lib.notify({ title = 'Vehicle Control', description = msg, type = kind or 'inform', position = 'top' })
end

local function currentVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetVehicleClass(veh) == 13 then return nil, ped end
    return veh, ped
end

local function takeControl(veh)
    if NetworkHasControlOfEntity(veh) then return true end
    local timeout = GetGameTimer() + 500
    NetworkRequestControlOfEntity(veh)
    while not NetworkHasControlOfEntity(veh) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfEntity(veh)
    end
    return NetworkHasControlOfEntity(veh)
end

local function clamp(n, lo, hi) return math.max(lo, math.min(hi, n)) end

-- Fuel: ox_fuel (Qbox default) keeps it in the `fuel` state bag, fall back to native tank level
local function getFuel(veh)
    local f = Entity(veh).state.fuel
    if f then return clamp(math.floor(f + 0.5), 0, 100) end
    local cap = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fPetrolTankVolume')
    if cap and cap > 0 then
        return clamp(math.floor(GetVehicleFuelLevel(veh) / cap * 100 + 0.5), 0, 100)
    end
    return 0
end

local function getEngineHealth(veh)
    return clamp(math.floor(GetVehicleEngineHealth(veh) / 10 + 0.5), 0, 100)
end

-- Windows are tracked as a bitmask (no native getter for rolled state)
local function getWinMask(veh)
    local m = winCache[veh]
    if m == nil then
        m = Entity(veh).state.fvc_win or 0
        winCache[veh] = m
    end
    return m
end

local function isWinDown(veh, i) return (getWinMask(veh) & (1 << i)) ~= 0 end

local function setWin(veh, i, down)
    local m = getWinMask(veh)
    if down then m = m | (1 << i) else m = m & ~(1 << i) end
    winCache[veh] = m
    Entity(veh).state:set('fvc_win', m, true)
    if down then RollDownWindow(veh, i) else RollUpWindow(veh, i) end
end

local function snapshot(veh, ped)
    local doors, valid, wins, seats = {}, {}, {}, {}
    for i = 0, 5 do
        valid[i + 1] = GetIsDoorValid(veh, i) and true or false
        doors[i + 1] = valid[i + 1] and GetVehicleDoorAngleRatio(veh, i) > 0.05
    end
    for i = 0, 3 do
        wins[i + 1] = isWinDown(veh, i)
    end
    local count = GetVehicleModelNumberOfSeats(GetEntityModel(veh))
    for seat = -1, count - 2 do
        local occupant = GetPedInVehicleSeat(veh, seat)
        seats[#seats + 1] = {
            index = seat,
            mine = occupant == ped,
            occupied = occupant ~= 0 and occupant ~= ped,
        }
    end
    return {
        fuel = getFuel(veh),
        health = getEngineHealth(veh),
        engine = GetIsVehicleEngineRunning(veh),
        isDriver = GetPedInVehicleSeat(veh, -1) == ped,
        doors = doors,
        valid = valid,
        windows = wins,
        seats = seats,
    }
end

local function push()
    local veh, ped = currentVehicle()
    if not veh then return end
    SendNUIMessage({ action = 'update', data = snapshot(veh, ped) })
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
end

local function openMenu()
    local veh = currentVehicle()
    if not veh then return notify('You need to be in a vehicle', 'error') end
    if isOpen then return end

    for handle in pairs(winCache) do
        if not DoesEntityExist(handle) then winCache[handle] = nil end
    end

    isOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true) -- cursor always on, keyboard still drives the car
    SendNUIMessage({ action = 'open' })
    push()

    CreateThread(function()
        local nextPush = 0
        while isOpen do
            DisableControlAction(0, 199, true) -- ESC closes the panel instead of the pause menu
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 1, true) -- no camera movement while the cursor is up
            DisableControlAction(0, 2, true)
            if IsDisabledControlJustPressed(0, 200) then closeMenu() break end
            if not currentVehicle() then closeMenu() break end

            local now = GetGameTimer()
            if now >= nextPush then
                push()
                nextPush = now + Config.UpdateInterval
            end
            Wait(0)
        end
    end)
end

local function toggleEngine()
    local veh, ped = currentVehicle()
    if not veh then return notify('You need to be in a vehicle', 'error') end
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        return notify('Only the driver can use the ignition', 'error')
    end
    local turnOn = not GetIsVehicleEngineRunning(veh)
    if turnOn and GetVehicleEngineHealth(veh) <= 0.0 then
        return notify('The engine is dead', 'error')
    end
    takeControl(veh)
    Entity(veh).state:set('fvc_engine', turnOn, true)
    SetVehicleUndriveable(veh, not turnOn)
    SetVehicleEngineOn(veh, turnOn, false, true)
end

-- Keeps the engine off after entering a vehicle the driver switched off
CreateThread(function()
    while true do
        local sleep = 500
        local veh, ped = currentVehicle()
        if veh and GetPedInVehicleSeat(veh, -1) == ped then
            sleep = 100
            if Entity(veh).state.fvc_engine == false and GetIsVehicleEngineRunning(veh) then
                SetVehicleEngineOn(veh, false, true, true)
                SetVehicleUndriveable(veh, true)
            end
        end
        Wait(sleep)
    end
end)

-- NUI callbacks
RegisterNUICallback('close', function(_, cb) cb('ok') closeMenu() end)

RegisterNUICallback('engine', function(_, cb)
    cb('ok')
    toggleEngine()
    Wait(150)
    push()
end)

RegisterNUICallback('door', function(data, cb)
    cb('ok')
    local veh = currentVehicle()
    local i = tonumber(data.index)
    if not veh or not i or not GetIsDoorValid(veh, i) then return end
    takeControl(veh)
    if GetVehicleDoorAngleRatio(veh, i) > 0.05 then
        SetVehicleDoorShut(veh, i, false)
    else
        SetVehicleDoorOpen(veh, i, false, false)
    end
    Wait(100)
    push()
end)

RegisterNUICallback('window', function(data, cb)
    cb('ok')
    local veh = currentVehicle()
    local i = tonumber(data.index)
    if not veh or not i or i < 0 or i > 3 then return end
    takeControl(veh)
    setWin(veh, i, not isWinDown(veh, i))
    push()
end)

RegisterNUICallback('windowsAll', function(_, cb)
    cb('ok')
    local veh = currentVehicle()
    if not veh then return end
    takeControl(veh)
    local anyUp = false
    for i = 0, 3 do
        if GetIsDoorValid(veh, i) and not isWinDown(veh, i) then anyUp = true break end
    end
    for i = 0, 3 do
        if GetIsDoorValid(veh, i) then setWin(veh, i, anyUp) end
    end
    push()
end)

RegisterNUICallback('seat', function(data, cb)
    cb('ok')
    local veh, ped = currentVehicle()
    local seat = tonumber(data.seat)
    if not veh or not seat then return end
    if GetPedInVehicleSeat(veh, seat) == ped then return end
    if not IsVehicleSeatFree(veh, seat, false) then
        return notify('That seat is taken', 'error')
    end
    local wasRunning = GetIsVehicleEngineRunning(veh)
    SetPedIntoVehicle(ped, veh, seat)
    if wasRunning then SetVehicleEngineOn(veh, true, true, true) end
    Wait(100)
    push()
end)

-- Commands / keybinds
RegisterCommand(Config.Command, function()
    if isOpen then closeMenu() else openMenu() end
end, false)
RegisterKeyMapping(Config.Command, 'Vehicle control panel', 'keyboard', Config.DefaultKey)

RegisterCommand(Config.EngineCommand, toggleEngine, false)
if Config.EngineKey and Config.EngineKey ~= '' then
    RegisterKeyMapping(Config.EngineCommand, 'Toggle vehicle engine', 'keyboard', Config.EngineKey)
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)
