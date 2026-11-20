local ADDON, ns = ...

ns.ADDON = ADDON
ns.TITLE = "WhoRolled"
ns.VERSION = C_AddOns.GetAddOnMetadata(ADDON, "Version") or "dev"

local issecretvalue = issecretvalue

function ns.IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

function ns.Plain(value)
    if ns.IsSecret(value) then return nil end
    return value
end

local function Dispatch(handlers)
    return function(_, event, ...)
        local list = handlers[event]
        for i = 1, #list do
            list[i](...)
        end
    end
end

local eventFrame = CreateFrame("Frame")
local eventHandlers = {}
eventFrame:SetScript("OnEvent", Dispatch(eventHandlers))

function ns.RegisterEvent(event, handler)
    local list = eventHandlers[event]
    if not list then
        if not pcall(eventFrame.RegisterEvent, eventFrame, event) then return false end
        list = {}
        eventHandlers[event] = list
    end
    list[#list + 1] = handler
    return true
end

local unitFrames = {}

function ns.RegisterUnitEvent(event, unit, handler)
    local frame = unitFrames[unit]
    if not frame then
        frame = CreateFrame("Frame")
        frame.handlers = {}
        frame:SetScript("OnEvent", Dispatch(frame.handlers))
        unitFrames[unit] = frame
    end
    local list = frame.handlers[event]
    if not list then
        list = {}
        frame.handlers[event] = list
        frame:RegisterUnitEvent(event, unit)
    end
    list[#list + 1] = handler
end

local listeners = {}

function ns.Listen(message, handler)
    local list = listeners[message]
    if not list then
        list = {}
        listeners[message] = list
    end
    list[#list + 1] = handler
end

function ns.Fire(message, ...)
    local list = listeners[message]
    if not list then return end
    for i = 1, #list do
        list[i](...)
    end
end

local scheduled = {}

function ns.Schedule(key, delay, callback)
    if scheduled[key] then return end
    scheduled[key] = true
    C_Timer.After(delay, function()
        scheduled[key] = nil
        callback()
    end)
end

ns.RegisterEvent("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    ns.Fire("INIT")
end)

ns.RegisterEvent("PLAYER_LOGIN", function()
    ns.Fire("LOGIN")
end)
