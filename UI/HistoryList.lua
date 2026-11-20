local _, ns = ...

local UI = ns.UI
local L = ns.L
local C = UI.COLORS
local T = UI.TEXT
local W = ns.Widgets
local Rolls = ns.Rolls
local Group = ns.Group
local Stats = ns.Stats
local RowList = ns.RowList

local List = {}
ns.HistoryList = List

local TOOLBAR_HEIGHT = 22
local TOOLBAR_GAP = 6
local COLUMN_HEAD_HEIGHT = 14
local FILTER_WIDTH = 150
local FILTER_GAP = 8

local FILTERS = {
    { value = "all", key = "FILTER_ALL" },
    { value = "picked", key = "FILTER_PICKED" },
    { value = "won", key = "FILTER_WON" },
}

local page
local list
local filter = "all"
local search = ""
local focus
local visits = {}
local scope = Stats.ALL

local lowerNames = setmetatable({}, { __mode = "k" })

local function LowerName(player)
    local cached = lowerNames[player]
    if cached and cached.source == player.name then return cached.lower end
    cached = { source = player.name, lower = player.name:lower() }
    lowerNames[player] = cached
    return cached.lower
end

local function FindFocus()
    if search == "" then return nil end
    for _, visit in ipairs(visits) do
        for _, record in ipairs(visit.records) do
            for _, player in ipairs(record.players) do
                if LowerName(player) == search then return player end
            end
        end
    end
end

local function ColumnOwner()
    return focus and focus.name or Group.PlayerName() or ""
end

local function PassesFilter(record)
    if filter == "all" then return true end
    local player = Rolls.FindPlayer(record, ColumnOwner())
    if not player then return false end
    if filter == "picked" then return Rolls.IsChoice(player.state) end
    return record.status == "won" and record.winner == player.name
end

local function Matches(record)
    if not PassesFilter(record) then return false end
    if search == "" then return true end
    if focus then return Rolls.FindPlayer(record, focus.name) ~= nil end
    if (record.name or ""):lower():find(search, 1, true) then return true end
    for _, player in ipairs(record.players) do
        if LowerName(player):find(search, 1, true) then return true end
    end
    return false
end

local function AddVisit(visit, withHeader)
    local found = false
    for _, record in ipairs(visit.records) do
        if Matches(record) then
            if withHeader and not found then list:Add("session", visit) end
            list:Add("drop", record)
            found = true
        end
    end
    return found
end

local function PaintColumnHead()
    local own = not focus or focus.name == Group.PlayerName()
    page.columnHead:SetText(own and L.ROW_YOU or UI.ClassText(focus.name, focus.class))
end

local function Build()
    if not list then return end
    focus = FindFocus()
    PaintColumnHead()
    list:Begin()
    if Rolls.IsSample() then list:Add("note", L.SAMPLE_NOTE) end
    local withHeaders = scope.kind ~= "visit"
    local found = false
    for _, visit in ipairs(visits) do
        if Stats.VisitInScope(visit, scope) and AddVisit(visit, withHeaders) then found = true end
    end
    if not found then list:Add("note", #Rolls.Records() > 0 and L.EMPTY_FILTER or L.EMPTY) end
    list:Finish()
end

function List.Paint(newVisits, newScope)
    visits, scope = newVisits or visits, newScope or scope
    Build()
end

function List.ScrollToTop()
    if page then page.scroll:ScrollTo(0, false) end
end

function List.Repaint()
    if list then list:Repaint() end
end

function List.Reveal(record)
    if list then list:Reveal(record) end
end

function List.FirstRecord()
    for _, entry in ipairs(List.Entries()) do
        if entry.kind == "drop" then return entry.data end
    end
end

function List.Contains(record)
    for _, entry in ipairs(List.Entries()) do
        if entry.data == record then return true end
    end
    return false
end

function List.Entries()
    return list and list:Entries() or {}
end

function List.SetFilter(value)
    filter = value
    if page then page.filter:Refresh(true) end
    Build()
end

function List.SetSearch(value)
    search = strtrim(value or ""):lower()
    Build()
end

function List.SearchFor(text)
    if not page then return end
    page.search:SetText(text)
    page.search:ClearFocus()
end

function List.ClearFilters()
    filter = "all"
    search = ""
    if not page then return end
    page.filter:Refresh(false)
    page.search:SetText("")
    page.search:ClearFocus()
end

function List.Tick()
    if not page or not page:IsVisible() then return end
    for _, row in ipairs(list:Rows()) do
        if row.kind == "drop" then row:PaintTimer() end
    end
end

local function CreateFilter(parent)
    return W.Segmented(parent, FILTER_WIDTH, {
        count = #FILTERS,
        get = function() return filter end,
        set = function(value) List.SetFilter(value) end,
        items = function()
            local items = {}
            for i, item in ipairs(FILTERS) do items[i] = { value = item.value, text = L[item.key] } end
            return items
        end,
    })
end

local HANDLERS = {
    open = function(record) ns.HistoryWindow.Select(record) end,
    selected = function(record) return record == ns.HistoryDetail.Selected() end,
    column = function() return focus and focus.name end,
}

function List.Create(parent)
    page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.filter = CreateFilter(page)
    page.filter:SetPoint("TOPRIGHT")
    page.search = W.SearchBox(page, "SEARCH", List.SetSearch)
    page.search:SetPoint("TOPLEFT")
    page.search:SetPoint("RIGHT", page.filter, "LEFT", -FILTER_GAP, 0)
    page.columnHead = UI.Text(page, T.caption, C.muted)
    page.columnHead:SetPoint("TOPRIGHT", -ns.HistoryRows.INSET, -TOOLBAR_HEIGHT - TOOLBAR_GAP)
    page.scroll = W.Scroll(page, W.SCROLL_GUTTER)
    page.scroll:SetPoint("TOPLEFT", -ns.HistoryRows.INSET, -TOOLBAR_HEIGHT - TOOLBAR_GAP - COLUMN_HEAD_HEIGHT)
    page.scroll:SetPoint("BOTTOMRIGHT", W.SCROLL_GUTTER, 0)
    list = RowList.New(page.scroll, HANDLERS)
    page:SetScript("OnShow", Build)
    return page
end
