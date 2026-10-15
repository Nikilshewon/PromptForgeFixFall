Bridge = {}

local function started(res)
    local s = GetResourceState(res)
    return s == 'started' or s == 'starting'
end

local function detect()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if started('qbx_core') then return 'qbox' end
    if started('qb-core') then return 'qbcore' end
    if started('es_extended') then return 'esx' end
    return 'standalone'
end

Bridge.Name = detect()

local core
local function getCore()
    if core then return core end
    if Bridge.Name == 'esx' then
        local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok then core = obj end
    elseif Bridge.Name == 'qbcore' then
        local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok then core = obj end
    end
    return core
end

local typeMap = {
    esx    = { success = 'success', error = 'error', info = 'info' },
    qbcore = { success = 'success', error = 'error', info = 'primary' },
    qbox   = { success = 'success', error = 'error', info = 'inform' },
}

---@param msg string
---@param kind 'success'|'error'|'info'|nil
function Bridge.Notify(msg, kind)
    kind = kind or 'info'
    local mapped = typeMap[Bridge.Name] and typeMap[Bridge.Name][kind] or kind

    if Bridge.Name == 'esx' then
        local c = getCore()
        if c then return c.ShowNotification(msg, mapped) end
    elseif Bridge.Name == 'qbcore' then
        local c = getCore()
        if c then return c.Functions.Notify(msg, mapped) end
    elseif Bridge.Name == 'qbox' then
        local ok = pcall(function() exports.qbx_core:Notify(msg, mapped) end)
        if ok then return end
    end

    -- Standalone / fallback
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end
