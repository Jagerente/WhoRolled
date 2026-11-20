local _, ns = ...

local UI = ns.UI
local L = ns.L
local C = UI.COLORS
local T = UI.TEXT
local W = ns.Widgets
local Rolls = ns.Rolls
local Stats = ns.Stats
local Text = ns.HistoryText
local Nav = ns.HistoryNav
local List = ns.HistoryList
local Detail = ns.HistoryDetail
local StatsPage = ns.HistoryStats

local Window = {}
ns.HistoryWindow = Window

local MIN_WIDTH, MIN_HEIGHT = 880, 460
local MAX_WIDTH, MAX_HEIGHT = 1800, 1200
local MARGIN = 16
local HEADER_HEIGHT = 46
local GLYPH_HEIGHT, GLYPH_GAP = 16, 8
local HEADER_BUTTON = 22
local GEAR_TEXTURE = "Interface\\WorldMap\\GEAR_64GREY"
local GRIP_SIZE = 14
local GRIP_TEXTURE = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-"
local NAV_WIDTH, DETAIL_WIDTH = 220, 310
local PANE_GAP = 14
local PANE_PAD = 10
local PANE_TONE = { 1, 1, 1, 0.025 }
local TITLE_BLOCK = 50
local SUBTITLE_GAP = 6
local TAB_WIDTH = 170
local TITLE_TAB_GAP = 12
local FADE_TIME = 0.16
local PAGE_FADE = 0.12
local REFRESH_DELAY = 0.15

local TABS = {
    { value = "rolls", key = "TAB_ROLLS" },
    { value = "stats", key = "TAB_STATS" },
}

local window
local scope = Stats.ALL
local visits = {}
local visitsStale = true
local visitsCount = -1

function Window.IsShown()
    return window ~= nil and window:IsShown() and not window.closing
end

local function VisitOf(record)
    for _, visit in ipairs(visits) do
        for _, each in ipairs(visit.records) do
            if each == record then return visit end
        end
    end
end

local function ScopeHasVisits()
    if scope.kind == "all" then return true end
    for _, visit in ipairs(visits) do
        if Stats.VisitInScope(visit, scope) then return true end
    end
    return false
end

local function PaintTitle()
    window.scopeTitle:SetText(Text.ScopeTitle(scope))
    local items, count, wins = Stats.Tally(visits, scope)
    window.scopeSummary:SetText(items > 0 and Text.ScopeSummary(scope, items, count, wins) or L.STATS_EMPTY)
end

local function NewestInScope()
    for _, visit in ipairs(visits) do
        if Stats.VisitInScope(visit, scope) then return visit.records[1] end
    end
end

local function FirstRecord()
    return List.FirstRecord() or NewestInScope()
end

local function KeepSelection()
    local selected = Detail.Selected()
    if selected and VisitOf(selected) then return end
    Detail.SetRecord(FirstRecord())
end

local function RefreshVisits()
    local records = Rolls.Records()
    if not visitsStale and #records == visitsCount then return false end
    visits = Stats.Visits(records)
    visitsStale, visitsCount = false, #records
    return true
end

local function Rebuild(full)
    if RefreshVisits() then full = true end
    if full and not ScopeHasVisits() then scope = Stats.ALL end
    PaintTitle()
    if full then Nav.Paint(visits, scope) end
    List.Paint(visits, scope)
    StatsPage.Paint(visits, scope)
    if full or not Detail.Selected() then KeepSelection() end
    Detail.Paint()
end

local function PaintTab(animate)
    local stats = ns.db.historyTab == "stats"
    local show, hide = stats and window.statsPage or window.listPage, stats and window.listPage or window.statsPage
    hide:Hide()
    if animate then UI.FadeIn(show, PAGE_FADE) else show:Show() end
    window.tabs:Refresh(animate)
end

function Window.SetTab(value)
    if ns.db.historyTab == value then return end
    ns.db.historyTab = value
    if not window then return end
    PaintTab(true)
    StatsPage.Paint(visits, scope)
end

local FOREIGN_SCOPE = { days = "place", places = "day" }

function Window.SetGrouping(value)
    ns.db.historyGrouping = value
    if not window then return end
    if scope.kind == FOREIGN_SCOPE[value] then
        Window.SelectScope(Stats.ALL)
    else
        Nav.Paint(visits, scope)
    end
end

function Window.Select(record)
    Detail.SetRecord(record)
    if not window then return end
    Detail.Paint()
    List.Repaint()
    List.Reveal(record)
end

function Window.SelectScope(newScope)
    scope = newScope or Stats.ALL
    Nav.Reveal(scope)
    if not window then return end
    List.ScrollToTop()
    StatsPage.ScrollToTop()
    Rebuild(true)
    Window.Select(FirstRecord())
end

local function ApplyGeometry()
    local position = ns.db.historyPosition
    window:ClearAllPoints()
    window:SetPoint(position.point, UIParent, position.relativePoint or position.point, position.x, position.y)
    window:SetSize(ns.db.historyWidth, ns.db.historyHeight)
end

local function SaveGeometry()
    window:StopMovingOrSizing()
    local position = ns.db.historyPosition
    position.point, position.relativePoint = "TOPLEFT", "BOTTOMLEFT"
    position.x, position.y = math.floor(window:GetLeft() + 0.5), math.floor(window:GetTop() + 0.5)
    ns.db.historyWidth = math.floor(window:GetWidth() + 0.5)
    ns.db.historyHeight = math.floor(window:GetHeight() + 0.5)
    ApplyGeometry()
end

local function CreateHeader()
    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    W.DragHandle(header, function() window:StartMoving() end, SaveGeometry)

    local glyph = UI.AddonGlyph(header, GLYPH_HEIGHT)
    glyph:SetPoint("LEFT", MARGIN, 0)
    local title = UI.BoldText(header, T.title, C.text)
    title:SetPoint("LEFT", glyph, "RIGHT", GLYPH_GAP, 0)
    W.Bind(title, "HISTORY_TITLE")

    local close = W.GlyphButton(header, HEADER_BUTTON, "×", nil, function() Window.Hide() end)
    close:SetPoint("RIGHT", -MARGIN + 6, 0)
    local gear = W.IconButton(header, HEADER_BUTTON - 6, GEAR_TEXTURE, nil, function() ns.Options.Toggle() end)
    gear:SetPoint("RIGHT", close, "LEFT", -6, 0)
end

local function CreatePane(width, side)
    local inset = side == "LEFT" and MARGIN or -MARGIN
    local pane = CreateFrame("Frame", nil, window)
    pane:SetWidth(width)
    pane:SetPoint("TOP" .. side, inset, -HEADER_HEIGHT)
    pane:SetPoint("BOTTOM" .. side, inset, MARGIN)
    UI.Fill(pane, PANE_TONE)
    local inner = CreateFrame("Frame", nil, pane)
    inner:SetPoint("TOPLEFT", PANE_PAD, -PANE_PAD)
    inner:SetPoint("BOTTOMRIGHT", -PANE_PAD, PANE_PAD)
    return pane, inner
end

local function CreateTabs(parent)
    return W.Segmented(parent, TAB_WIDTH, {
        count = #TABS,
        get = function() return ns.db.historyTab end,
        set = function(value) Window.SetTab(value) end,
        items = function()
            local items = {}
            for i, item in ipairs(TABS) do items[i] = { value = item.value, text = L[item.key] } end
            return items
        end,
    })
end

local function CreateMiddle(navPane, detailPane)
    local middle = CreateFrame("Frame", nil, window)
    middle:SetPoint("TOPLEFT", navPane, "TOPRIGHT", PANE_GAP, 0)
    middle:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMLEFT", -PANE_GAP, 0)

    window.tabs = CreateTabs(middle)
    window.tabs:SetPoint("TOPRIGHT")
    window.scopeTitle = UI.BoldText(middle, T.title, C.text)
    window.scopeTitle:SetPoint("TOPLEFT", 0, -2)
    window.scopeTitle:SetPoint("RIGHT", window.tabs, "LEFT", -TITLE_TAB_GAP, 0)
    window.scopeTitle:SetJustifyH("LEFT")
    window.scopeSummary = UI.Text(middle, T.label, C.muted)
    window.scopeSummary:SetPoint("TOPLEFT", window.scopeTitle, "BOTTOMLEFT", 0, -SUBTITLE_GAP)
    window.scopeSummary:SetPoint("TOPRIGHT", window.scopeTitle, "BOTTOMRIGHT", TITLE_TAB_GAP + TAB_WIDTH, -SUBTITLE_GAP)
    window.scopeSummary:SetJustifyH("LEFT")

    local content = CreateFrame("Frame", nil, middle)
    content:SetPoint("TOPLEFT", 0, -TITLE_BLOCK)
    content:SetPoint("BOTTOMRIGHT")
    window.listPage = List.Create(content)
    window.statsPage = StatsPage.Create(content)
end

local function CreateGrip()
    local grip = CreateFrame("Button", nil, window)
    grip:SetSize(GRIP_SIZE, GRIP_SIZE)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture(GRIP_TEXTURE .. "Up")
    grip:SetHighlightTexture(GRIP_TEXTURE .. "Highlight")
    grip:SetPushedTexture(GRIP_TEXTURE .. "Down")
    grip:SetScript("OnMouseDown", function()
        SaveGeometry()
        window:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", SaveGeometry)
end

local function CreateWindow()
    window = CreateFrame("Frame", "WhoRolledHistory", UIParent)
    window:SetFrameStrata("MEDIUM")
    window:SetToplevel(true)
    window:SetMovable(true)
    window:SetResizable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    if window.SetResizeBounds then window:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT) end
    window:Hide()
    UI.Fill(window, C.window)
    tinsert(UISpecialFrames, window:GetName())
    window:SetScript("OnMouseDown", function(self) self:Raise() end)
    window:HookScript("OnHide", function(self) self.closing = false end)

    CreateHeader()
    local navPane, navInner = CreatePane(NAV_WIDTH, "LEFT")
    Nav.Create(navInner, NAV_WIDTH - PANE_PAD * 2)
    local detailPane, detailInner = CreatePane(DETAIL_WIDTH, "RIGHT")
    Detail.Create(detailInner, DETAIL_WIDTH - PANE_PAD * 2)
    CreateMiddle(navPane, detailPane)
    CreateGrip()
    ApplyGeometry()
    PaintTab(false)
end

function Window.Show()
    if not window then CreateWindow() end
    if Window.IsShown() then return end
    window.closing = false
    UI.FadeIn(window, FADE_TIME)
    window:Raise()
    Rebuild(true)
end

function Window.Hide()
    if not Window.IsShown() then return end
    window.closing = true
    UI.FadeOut(window, FADE_TIME)
end

function Window.Toggle()
    if Window.IsShown() then Window.Hide() else Window.Show() end
end

local function RevealRecord(record)
    local visit = VisitOf(record)
    if visit and not Stats.VisitInScope(visit, scope) then
        scope = Stats.ALL
        Rebuild(true)
    end
    if not List.Contains(record) then
        List.ClearFilters()
        Rebuild(true)
    end
    Window.Select(record)
end

function Window.Open(record)
    Window.Show()
    window:Raise()
    if not record then return end
    Window.SetTab("rolls")
    RevealRecord(record)
end

function Window.ShowPlayer(name)
    Window.SetTab("rolls")
    List.SearchFor(name)
end

local function RefreshNow()
    if not window or not window:IsShown() then return end
    Rebuild()
end

local function Refresh()
    ns.Schedule("WhoRolledHistoryRefresh", REFRESH_DELAY, RefreshNow)
end

ns.Listen("DROPS_CHANGED", Refresh)

ns.Listen("DROP_ADDED", function()
    visitsStale = true
end)

ns.Listen("RECORDS_RESET", function()
    visitsStale = true
    scope = Stats.ALL
    Detail.SetRecord(nil)
    if window and window:IsShown() then Rebuild(true) end
end)

ns.Listen("ROLL_TICK", function()
    if not window or not window:IsShown() then return end
    List.Tick()
    Detail.Tick()
end)

ns.Listen("SETTING_CHANGED", function(key)
    if not window then return end
    if key == nil then
        ApplyGeometry()
        PaintTab(false)
    end
    if key == nil or key == "locale" then Rebuild(true) end
end)

ns.Listen("LOCALE_CHANGED", function()
    if window and window:IsShown() then Rebuild(true) end
end)
