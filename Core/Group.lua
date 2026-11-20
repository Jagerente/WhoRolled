local _, ns = ...

local Group = {}
ns.Group = Group

local MAX_RAID = 40
local MAX_PARTY = 4

local unitByName = {}
local dirty = true

function Group.ShortName(name)
    if type(name) ~= "string" then return nil end
    return (name:match("^([^%-%s]+)")) or name
end

local function Remember(unit)
    local name = Group.ShortName(ns.Plain(UnitName(unit)))
    if name then unitByName[name] = unit end
end

local function Rebuild()
    wipe(unitByName)
    Remember("player")
    if IsInRaid() then
        for i = 1, MAX_RAID do
            if UnitExists("raid" .. i) then Remember("raid" .. i) end
        end
    elseif IsInGroup() then
        for i = 1, MAX_PARTY do
            if UnitExists("party" .. i) then Remember("party" .. i) end
        end
    end
    dirty = false
end

local function UnitOf(name)
    if dirty then Rebuild() end
    return unitByName[Group.ShortName(name) or ""]
end

function Group.ClassOf(name)
    local unit = UnitOf(name)
    if not unit then return nil end
    local _, class = UnitClass(unit)
    return ns.Plain(class)
end

function Group.Members()
    if dirty then Rebuild() end
    local names = {}
    for name in pairs(unitByName) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function Group.PlayerName()
    return Group.ShortName(ns.Plain(UnitName("player")))
end

local function MarkDirty()
    dirty = true
    ns.Fire("GROUP_CHANGED")
end

ns.RegisterEvent("GROUP_ROSTER_UPDATE", MarkDirty)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", MarkDirty)
