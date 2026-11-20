local _, ns = ...

local UI = ns.UI
local L = ns.L
local C = UI.COLORS
local T = UI.TEXT
local W = ns.Widgets
local Rolls = ns.Rolls
local Rows = ns.HistoryRows
local Text = ns.HistoryText

local Recent = {}
ns.RecentWindow = Recent

local MIN_WIDTH, MAX_WIDTH = 240, 520
local MAX_HEIGHT = 2000
local PAD = 10
local HEADER_HEIGHT = 26
local BOTTOM_PAD = 6
local EMPTY_HEIGHT = 22
local GLYPH_HEIGHT, GLYPH_GAP = 12, 6
local CLOSE_SIZE = 20
local GRIP_SIZE = 12
local GRIP_TEXTURE = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-"
local FADE_TIME = 0.16
local HOVER_TIME = 0.15
local RESIZE_TIME = 0.18
local REFRESH_DELAY = 0.15
local CLICK_SLOP = 4
local ROW_HEIGHT = Rows.HEIGHT.drop

local window
local rows = {}
local shown = {}
local hovered = false
local press = {}

local function SavePosition()
    local position = ns.db.windowPosition
    position.point, position.relativePoint = "TOPLEFT", "BOTTOMLEFT"
    position.x, position.y = math.floor(window:GetLeft() + 0.5), math.floor(window:GetTop() + 0.5)
end

local function ApplyPosition()
    local position = ns.db.windowPosition
    window:ClearAllPoints()
    window:SetPoint(position.point, UIParent, position.relativePoint or position.point, position.x, position.y)
end

local function ApplyChrome(_, value)
    window.close:SetAlpha(value)
    window.mineHead:SetAlpha(1 - value)
    window.grip:SetAlpha(ns.db.windowLocked and 0 or value)
end

local function SetHovered(value)
    if hovered == value then return end
    hovered = value
    UI.Tween(window.chrome, value and 1 or 0, HOVER_TIME, ApplyChrome)
end

local function CheckHover()
    SetHovered(window:IsShown() and window:IsMouseOver() == true)
end

local function WatchHover(frame)
    frame:HookScript("OnEnter", function() SetHovered(true) end)
    frame:HookScript("OnLeave", function() ns.Schedule("WhoRolledRecentHover", 0, CheckHover) end)
end

local function OnPressDown(_, button)
    window:Raise()
    if button ~= "LeftButton" then return end
    press.active = true
    press.x, press.y = GetCursorPosition()
    press.moving = not ns.db.windowLocked
    if press.moving then window:StartMoving() end
    W.HideHint(window.header)
end

local function StopMoving()
    if not press.moving then return end
    press.moving = false
    window:StopMovingOrSizing()
    SavePosition()
    ApplyPosition()
end

local function OnPressUp(_, button)
    if button == "RightButton" then
        ns.Options.Toggle()
        return
    end
    if button ~= "LeftButton" or not press.active then return end
    press.active = false
    StopMoving()
    local x, y = GetCursorPosition()
    if math.abs(x - press.x) + math.abs(y - press.y) <= CLICK_SLOP then ns.HistoryWindow.Toggle() end
end

local function MakePressable(frame)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", OnPressDown)
    frame:SetScript("OnMouseUp", OnPressUp)
    WatchHover(frame)
end

local function RowWidth()
    return math.max(1, window:GetWidth() - PAD * 2)
end

local ROW_HANDLERS = {
    open = function(record) ns.HistoryWindow.Open(record) end,
    rightClick = function() ns.Options.Toggle() end,
}

local function CreateRow(index)
    local row = Rows.Create("drop", window, ROW_HANDLERS)
    row:SetPoint("TOPLEFT", PAD, -HEADER_HEIGHT - (index - 1) * ROW_HEIGHT)
    WatchHover(row)
    rows[index] = row
    return row
end

local function TargetHeight()
    local body = #shown > 0 and #shown * ROW_HEIGHT or EMPTY_HEIGHT
    return HEADER_HEIGHT + body + BOTTOM_PAD
end

local function ApplyHeight(_, value)
    window:SetHeight(value)
end

local function Paint(animate)
    local records = Rolls.Records()
    wipe(shown)
    for i = #records, math.max(1, #records - ns.db.windowRows + 1), -1 do shown[#shown + 1] = records[i] end
    local width = RowWidth()
    local anyMine = false
    for index, record in ipairs(shown) do
        local row = rows[index] or CreateRow(index)
        row:SetWidth(width)
        row:Show()
        row:Paint(record)
        anyMine = anyMine or Text.RowPick(record) ~= nil
    end
    for index = #shown + 1, #rows do rows[index]:Hide() end
    window.empty:SetShown(#shown == 0)
    window.mineHead:SetShown(anyMine)
    window.title:SetText(Rolls.IsSample() and L.RECENT_TITLE_PREVIEW or L.RECENT_TITLE)
    if animate then
        UI.Tween(window.sizer, TargetHeight(), RESIZE_TIME, ApplyHeight)
    else
        UI.SnapTween(window.sizer, TargetHeight(), ApplyHeight)
    end
end

local function ApplySettings()
    ApplyPosition()
    window:SetWidth(ns.db.windowWidth)
    window.background:SetAlpha(ns.db.windowOpacity / 100)
    window.grip:SetShown(not ns.db.windowLocked)
    ApplyChrome(window.chrome, window.chrome.tweenValue or 0)
end

local function SaveWidth()
    window:StopMovingOrSizing()
    ns.db.windowWidth = math.floor(window:GetWidth() + 0.5)
    SavePosition()
    ApplyPosition()
    Paint(false)
end

local function CreateGrip()
    local grip = CreateFrame("Button", nil, window)
    grip:SetSize(GRIP_SIZE, GRIP_SIZE)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture(GRIP_TEXTURE .. "Up")
    grip:SetHighlightTexture(GRIP_TEXTURE .. "Highlight")
    grip:SetPushedTexture(GRIP_TEXTURE .. "Down")
    grip:SetScript("OnMouseDown", function()
        SavePosition()
        ApplyPosition()
        window:StartSizing("RIGHT")
    end)
    grip:SetScript("OnMouseUp", SaveWidth)
    WatchHover(grip)
    window.grip = grip
end

local function CreateHeader()
    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER_HEIGHT)
    MakePressable(header)
    header:HookScript("OnEnter", function(self) W.ShowHint(self, "RECENT_HINT", UI.VerticalAnchor(self)) end)
    header:HookScript("OnLeave", W.HideHint)
    window.header = header

    local glyph = UI.AddonGlyph(header, GLYPH_HEIGHT)
    glyph:SetPoint("LEFT", PAD, 0)
    window.title = UI.BoldText(header, T.label, C.muted)
    window.title:SetPoint("LEFT", glyph, "RIGHT", GLYPH_GAP, 0)

    window.close = W.GlyphButton(header, CLOSE_SIZE, "×", nil, function() Recent.Hide() end)
    window.close:SetPoint("RIGHT", -4, 0)
    WatchHover(window.close)
    window.mineHead = UI.Text(header, T.caption, C.muted)
    window.mineHead:SetPoint("BOTTOMRIGHT", -PAD, 2)
    W.Bind(window.mineHead, "ROW_YOU")
end

local function CreateEmpty()
    window.empty = UI.Text(window, T.label, C.muted)
    window.empty:SetPoint("TOPLEFT", PAD, -HEADER_HEIGHT - 2)
    window.empty:SetPoint("RIGHT", -PAD, 0)
    window.empty:SetJustifyH("LEFT")
    W.Bind(window.empty, "RECENT_EMPTY")
end

local function CreateWindow()
    window = CreateFrame("Frame", "WhoRolledWindow", UIParent)
    window:SetFrameStrata("MEDIUM")
    window:SetToplevel(true)
    window:SetMovable(true)
    window:SetResizable(true)
    window:SetClampedToScreen(true)
    if window.SetResizeBounds then window:SetResizeBounds(MIN_WIDTH, 1, MAX_WIDTH, MAX_HEIGHT) end
    window:Hide()
    window.background = UI.Fill(window, { C.window[1], C.window[2], C.window[3], 1 })
    window.chrome, window.sizer = {}, {}
    MakePressable(window)
    window:HookScript("OnHide", function()
        press.active = false
        StopMoving()
        SetHovered(false)
    end)
    window:SetScript("OnSizeChanged", function(self, width)
        if self.paintedWidth == width then return end
        self.paintedWidth = width
        local rowWidth = RowWidth()
        for _, row in ipairs(rows) do
            row:SetWidth(rowWidth)
            if row:IsShown() then row:PaintTimer() end
        end
    end)

    CreateHeader()
    CreateEmpty()
    CreateGrip()
    UI.SnapTween(window.chrome, 0, ApplyChrome)
    ApplySettings()
    Paint(false)
end

function Recent.Rows()
    return shown
end

function Recent.IsShown()
    return window ~= nil and window:IsShown() and not window.closing
end

function Recent.Show()
    if not window then CreateWindow() end
    if Recent.IsShown() then return end
    window.closing = false
    Paint(false)
    UI.FadeIn(window, FADE_TIME)
end

function Recent.Hide()
    if not Recent.IsShown() then return end
    window.closing = true
    UI.FadeOut(window, FADE_TIME)
end

function Recent.Toggle()
    if Recent.IsShown() then Recent.Hide() else Recent.Show() end
end

function Recent.ResetPosition()
    local defaults = ns.DEFAULTS
    local position, default = ns.db.windowPosition, defaults.windowPosition
    position.point, position.relativePoint, position.x, position.y = default.point, default.relativePoint, default.x, default.y
    ns.db.windowWidth = defaults.windowWidth
    if window then
        ApplySettings()
        Paint(false)
    end
end

local function RefreshNow()
    if not window or not window:IsShown() then return end
    Paint(true)
end

local function Refresh()
    ns.Schedule("WhoRolledRecentRefresh", REFRESH_DELAY, RefreshNow)
end

local function ShouldAutoShow()
    local mode = ns.db.windowMode
    if mode == "always" then return true end
    if mode == "group" then return IsInGroup() end
    return false
end

ns.Listen("LOGIN", function()
    if ShouldAutoShow() then Recent.Show() end
end)

local wasGrouped = false

ns.Listen("GROUP_CHANGED", function()
    local grouped = IsInGroup()
    if grouped and not wasGrouped and ns.db.windowMode == "group" then Recent.Show() end
    wasGrouped = grouped
end)

ns.Listen("DROP_ADDED", function(record)
    if ns.db.windowMode ~= "manual" and not record.sample then Recent.Show() end
end)

ns.Listen("DROPS_CHANGED", Refresh)
ns.Listen("RECORDS_RESET", RefreshNow)

local openedForPreview = false

ns.Listen("TEST_MODE_CHANGED", function(active)
    if active then
        openedForPreview = not Recent.IsShown()
        Recent.Show()
    elseif openedForPreview then
        openedForPreview = false
        if not ShouldAutoShow() then Recent.Hide() end
    end
end)

ns.Listen("ROLL_TICK", function()
    if not window or not window:IsShown() then return end
    for index = 1, #shown do rows[index]:PaintTimer() end
end)

local WINDOW_KEYS = { windowLocked = true, windowOpacity = true, windowWidth = true }

ns.Listen("SETTING_CHANGED", function(key)
    if not window then return end
    if key == nil or WINDOW_KEYS[key] then ApplySettings() end
    if key == "windowMode" and ShouldAutoShow() then Recent.Show() end
    if (key == nil or key == "windowMode") and not ShouldAutoShow() and not ns.TestMode.active then Recent.Hide() end
    if key == nil or key == "windowRows" or key == "locale" then RefreshNow() end
end)

ns.Listen("LOCALE_CHANGED", RefreshNow)
