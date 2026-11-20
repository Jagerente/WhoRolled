local _, ns = ...

local L = ns.L
local W = ns.Widgets
local Stats = ns.Stats
local Text = ns.HistoryText
local RowList = ns.RowList

local Nav = {}
ns.HistoryNav = Nav

local LIST_GAP = 10
local SEGMENT_HEIGHT = 22

local GROUPINGS = {
    { value = "days", key = "GROUP_DAYS" },
    { value = "places", key = "GROUP_PLACES" },
}

local page
local list
local items = {}
local itemCount = 0
local expanded = {}
local visits = {}
local scope = Stats.ALL
local selectedId = "all"

local function CountRecords(group)
    return (Stats.Tally(group))
end

local function IsOpen(id, default)
    local state = expanded[id]
    if state == nil then return default end
    return state
end

local function Add(label, count, depth, itemScope, expandable, open)
    itemCount = itemCount + 1
    local item = items[itemCount] or {}
    items[itemCount] = item
    item.label, item.count, item.depth, item.scope = label, count, depth, itemScope
    item.id = Stats.ScopeId(itemScope)
    item.expandable, item.expanded, item.selected = expandable == true, open == true, item.id == selectedId
    list:Add("nav", item)
end

local function VisitInDay(visit)
    return Text.Clock(visit.first) .. " " .. Text.Zone(visit.zone)
end

local function VisitInPlace(visit)
    return Text.Day(visit.first) .. ", " .. Text.Clock(visit.first)
end

local function AddVisits(group, label)
    for _, visit in ipairs(group) do Add(label(visit), #visit.records, 1, Stats.VisitScope(visit)) end
end

local function BuildDays()
    for index, day in ipairs(Stats.Days(visits)) do
        local dayScope = Stats.DayScope(day)
        local holdsSelection = scope.kind == "visit" and scope.day == day.key
        local open = IsOpen(Stats.ScopeId(dayScope), index == 1 or holdsSelection)
        Add(Text.Day(day.t), CountRecords(day.visits), 0, dayScope, true, open)
        if open then AddVisits(day.visits, VisitInDay) end
    end
end

local function BuildPlaces()
    for index, place in ipairs(Stats.Places(visits)) do
        local placeScope = Stats.PlaceScope(place.zone)
        local holdsSelection = scope.kind == "visit" and scope.zone == place.zone
        local open = IsOpen(Stats.ScopeId(placeScope), index == 1 or holdsSelection)
        Add(Text.Zone(place.zone), CountRecords(place.visits), 0, placeScope, true, open)
        if open then AddVisits(place.visits, VisitInPlace) end
    end
end

local function Build()
    itemCount = 0
    list:Begin()
    Add(L.SCOPE_ALL, CountRecords(visits), 0, Stats.ALL)
    if ns.db.historyGrouping == "places" then BuildPlaces() else BuildDays() end
    list:Finish()
end

function Nav.Paint(newVisits, newScope)
    if not page then return end
    visits, scope = newVisits or visits, newScope or scope
    selectedId = Stats.ScopeId(scope)
    page.grouping:Refresh(false)
    Build()
end

function Nav.Reveal(target)
    if target.kind == "visit" then
        expanded[Stats.ScopeId({ kind = "day", day = target.day })] = true
        expanded[Stats.ScopeId(Stats.PlaceScope(target.zone))] = true
    elseif target.kind ~= "all" then
        expanded[Stats.ScopeId(target)] = true
    end
end

function Nav.Entries()
    return list and list:Entries() or {}
end

local function Select(data)
    if data.expandable and data.selected then
        expanded[data.id] = not data.expanded
        Build()
        return
    end
    if data.expandable then expanded[data.id] = true end
    ns.HistoryWindow.SelectScope(data.scope)
end
Nav.Select = Select

function Nav.Create(parent, width)
    page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.grouping = W.Segmented(page, width, {
        count = #GROUPINGS,
        get = function() return ns.db.historyGrouping end,
        set = function(value) ns.HistoryWindow.SetGrouping(value) end,
        items = function()
            local items = {}
            for i, item in ipairs(GROUPINGS) do items[i] = { value = item.value, text = L[item.key] } end
            return items
        end,
    })
    page.grouping:SetPoint("TOPLEFT")
    local scroll = W.Scroll(page, W.SCROLL_GUTTER)
    scroll:SetPoint("TOPLEFT", -ns.HistoryRows.INSET, -SEGMENT_HEIGHT - LIST_GAP)
    scroll:SetPoint("BOTTOMRIGHT", W.SCROLL_GUTTER, 0)
    list = RowList.New(scroll, { select = Select })
    return page
end
