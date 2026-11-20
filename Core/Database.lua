local _, ns = ...

local DEFAULTS = {
    locale = "auto",
    floatEnabled = true,
    floatChoices = true,
    floatWinner = true,
    floatQuality = 2,
    floatSize = 15,
    floatTime = 3,
    floatPosition = { point = "CENTER", x = -360, y = 100 },
    windowMode = "always",
    windowRows = 5,
    windowLocked = false,
    windowOpacity = 92,
    windowPosition = { point = "TOPRIGHT", relativePoint = "RIGHT", x = -60, y = 240 },
    windowWidth = 300,
    historyGrouping = "days",
    historyTab = "rolls",
    historyPosition = { point = "CENTER", x = 0, y = 20 },
    historyWidth = 960,
    historyHeight = 620,
    minimap = { hide = false, angle = 360 },
    lastPage = "float",
}

local CHAR_DEFAULTS = {
    drops = {},
    dismissed = {},
}

ns.DEFAULTS = DEFAULTS

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = ApplyDefaults(type(target[key]) == "table" and target[key] or {}, value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

local function DropRetired(target, defaults)
    for key in pairs(target) do
        if defaults[key] == nil then target[key] = nil end
    end
    return target
end

ns.Listen("INIT", function()
    WhoRolledDB = ApplyDefaults(DropRetired(WhoRolledDB or {}, DEFAULTS), DEFAULTS)
    WhoRolledCharDB = ApplyDefaults(WhoRolledCharDB or {}, CHAR_DEFAULTS)
    ns.db = WhoRolledDB
    ns.charDB = WhoRolledCharDB
    ns.Fire("DB_READY")
end)

function ns.Set(key, value)
    if ns.db[key] == value then return end
    ns.db[key] = value
    ns.Fire("SETTING_CHANGED", key, value)
end

function ns.ResetSettings()
    wipe(ns.db)
    ApplyDefaults(ns.db, DEFAULTS)
    ns.Fire("SETTING_CHANGED")
end
