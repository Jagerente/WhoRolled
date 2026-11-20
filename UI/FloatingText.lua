local _, ns = ...

local UI = ns.UI
local L = ns.L
local C = UI.COLORS
local W = ns.Widgets
local Rolls = ns.Rolls

local Float = {}
ns.FloatingText = Float

local MAX_LINES = 8
local LINE_SPACING = 1.25
local FADE_IN = 0.15
local FADE_OUT = 0.4
local SLIDE_TIME = 0.18
local WINNER_SCALE = 1.25
local POP_SCALE = 1.3
local POP_TIME = 0.2
local SPOT_WIDTH, SPOT_HEIGHT = 240, 24
local ITEM_ICON_RATIO = 1.1
local NAMES_IN_LINE = 3
local SETTINGS_PAGE = "float"

local pool = {}
local feed = {}
local spot

local function LineHeight()
    return math.floor(ns.db.floatSize * LINE_SPACING + 0.5)
end

local function ApplyOffset(line, value)
    line:ClearAllPoints()
    line:SetPoint("BOTTOM", spot, "BOTTOM", 0, value)
end

local function Release(line)
    for i = #feed, 1, -1 do
        if feed[i] == line then table.remove(feed, i) end
    end
    line.record, line.playerName, line.state, line.players = nil, nil, nil, nil
    line.anim:Stop()
    UI.StopTween(line)
    line:Hide()
    pool[#pool + 1] = line
end

local function CreateLine()
    local line = CreateFrame("Frame", nil, UIParent)
    line:SetSize(1, 1)
    line.text = line:CreateFontString(nil, "OVERLAY")
    line.text:SetPoint("CENTER")
    line.text:SetWordWrap(false)

    local anim = line:CreateAnimationGroup()
    anim:SetToFinalAlpha(true)
    local fadeIn = anim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetOrder(1)
    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(FADE_OUT)
    fadeOut:SetOrder(1)
    local pop = anim:CreateAnimation("Scale")
    pop:SetOrder(1)
    pop:SetDuration(POP_TIME)
    pop:SetScaleTo(1, 1)
    pop:SetSmoothing("OUT")
    anim:SetScript("OnFinished", function() Release(line) end)
    line.anim, line.fadeIn, line.fadeOut, line.pop = anim, fadeIn, fadeOut, pop
    return line
end

local function Acquire()
    local line = table.remove(pool) or CreateLine()
    line:SetAlpha(1)
    line:SetScale(1)
    line:SetFrameStrata(spot:GetFrameStrata())
    return line
end

local function Configure(line, text, color, big)
    local size = big and math.floor(ns.db.floatSize * WINNER_SCALE + 0.5) or ns.db.floatSize
    line.text:SetFontObject(UI.BoldFont(size, "OUTLINE"))
    line.text:SetTextColor(unpack(color))
    line.text:SetText(text)
    line:SetSize(math.max(1, line.text:GetStringWidth()), size)
    line.fadeIn:SetDuration(FADE_IN)
    line.fadeOut:SetStartDelay(math.max(0, ns.db.floatTime - FADE_OUT))
    local from = big and POP_SCALE or 1
    line.pop:SetScaleFrom(from, from)
end

local function Push()
    local height = LineHeight()
    for index, line in ipairs(feed) do
        UI.Tween(line, index * height, SLIDE_TIME, ApplyOffset)
    end
    while #feed >= MAX_LINES do Release(feed[#feed]) end
end

local function Show(record, text, color, big)
    Push()
    local line = Acquire()
    line.record = record
    Configure(line, text, color, big)
    table.insert(feed, 1, line)
    UI.SnapTween(line, 0, ApplyOffset)
    line:Show()
    line.anim:Restart()
    return line
end

local function Renew(line, text)
    line.text:SetText(text)
    line:SetWidth(math.max(1, line.text:GetStringWidth()))
    line.fadeIn:SetDuration(0)
    line.anim:Restart()
end

local function ItemIcon(record)
    return UI.IconMarkup(record.icon, math.floor(ns.db.floatSize * ITEM_ICON_RATIO + 0.5))
end

local function Pressed(state)
    return Rolls.STATE_RANK[state] ~= nil and state ~= "waiting"
end

local function Wanted(record)
    if not ns.db.floatEnabled then return false end
    return record.quality == nil or record.quality >= ns.db.floatQuality
end

local function ChoiceText(record, line)
    local who
    if #line.players > NAMES_IN_LINE then
        who = ns.Plural(#line.players, "FORMS_PLAYERS")
    else
        local names = {}
        for i, player in ipairs(line.players) do names[i] = UI.ClassText(player.name, player.class) end
        who = table.concat(names, ", ")
    end
    return ItemIcon(record) .. " " .. string.format(L.FLOAT_CHOICE, who, UI.StateText(line.state))
end

local function Forget(record, name)
    for i = #feed, 1, -1 do
        local line = feed[i]
        if line and line.record == record then
            if line.players then
                for j = #line.players, 1, -1 do
                    if line.players[j].name == name then table.remove(line.players, j) end
                end
                if #line.players == 0 then Release(line) else Renew(line, ChoiceText(record, line)) end
            elseif line.playerName == name then
                Release(line)
            end
        end
    end
end

local function FindChoiceLine(record, state)
    for _, line in ipairs(feed) do
        if line.record == record and line.state == state then return line end
    end
end

ns.Listen("ROLL_CHOICE", function(record, player)
    if not Wanted(record) or not ns.db.floatChoices or not Pressed(player.state) then return end
    local line = FindChoiceLine(record, player.state)
    if line then
        line.players[#line.players + 1] = player
        Renew(line, ChoiceText(record, line))
        return
    end
    local players = { player }
    local text = ChoiceText(record, { state = player.state, players = players })
    line = Show(record, text, UI.StateColor(player.state), false)
    line.state, line.players = player.state, players
end)

local function RollText(player)
    if Pressed(player.state) then
        local state = UI.StateText(player.state)
        return player.roll and (state .. " " .. player.roll) or state
    end
    return player.roll and tostring(player.roll) or nil
end

local function WinText(record, player)
    local name = UI.ClassText(player.name, player.class)
    local item = ItemIcon(record) .. " " .. UI.Colorize(record.name or "", UI.QualityColor(record.quality))
    local roll = RollText(player)
    if roll then return string.format(L.FLOAT_WON, name, item, roll) end
    return string.format(L.FLOAT_WON_PLAIN, name, item)
end

ns.Listen("ROLL_WON", function(record, player)
    if not Wanted(record) or not ns.db.floatWinner or not player then return end
    Forget(record, player.name)
    local line = Show(record, WinText(record, player), C.accent, true)
    line.playerName = player.name
end)

local function PlaceSpot()
    local position = ns.db.floatPosition
    spot:ClearAllPoints()
    spot:SetPoint(position.point, UIParent, position.point, position.x, position.y)
end

local function SaveSpot()
    spot:StopMovingOrSizing()
    local point, _, _, x, y = spot:GetPoint()
    local position = ns.db.floatPosition
    position.point, position.x, position.y = point, math.floor(x + 0.5), math.floor(y + 0.5)
    PlaceSpot()
end

local function ShowHandle(shown)
    spot.handle:SetShown(shown)
    spot:EnableMouse(shown)
end

local function CreateSpot()
    spot = CreateFrame("Frame", "WhoRolledFloatingSpot", UIParent)
    spot:SetSize(SPOT_WIDTH, SPOT_HEIGHT)
    spot:SetFrameStrata("MEDIUM")
    spot:SetMovable(true)
    spot:SetClampedToScreen(true)
    spot.handle = CreateFrame("Frame", nil, spot)
    spot.handle:SetAllPoints()
    UI.Fill(spot.handle, C.control)
    local label = UI.Text(spot.handle, UI.TEXT.label, C.muted)
    label:SetPoint("CENTER")
    W.Bind(label, "FLOAT_SPOT_HANDLE")
    W.DragHandle(spot, function() spot:StartMoving() end, SaveSpot)
    spot:SetScript("OnEnter", function(self) W.ShowHint(self, "FLOAT_SPOT_HANDLE_DESC", UI.VerticalAnchor(self)) end)
    spot:SetScript("OnLeave", W.HideHint)
    PlaceSpot()
    ShowHandle(false)
end

function Float.ResetPosition()
    local defaults = ns.DEFAULTS.floatPosition
    local position = ns.db.floatPosition
    position.point, position.x, position.y = defaults.point, defaults.x, defaults.y
    PlaceSpot()
end

function Float.Clear()
    for i = #feed, 1, -1 do Release(feed[i]) end
end

ns.Listen("DB_READY", CreateSpot)
ns.Listen("OPTIONS_PAGE", function(page) ShowHandle(page == SETTINGS_PAGE) end)
ns.Listen("TEST_MODE_CHANGED", function(active)
    if not active then Float.Clear() end
end)
ns.Listen("SETTING_CHANGED", function(key)
    if key == nil then PlaceSpot() end
    if key == "floatEnabled" and not ns.db.floatEnabled then Float.Clear() end
end)
