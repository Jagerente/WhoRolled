local _, ns = ...

local L = ns.L

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local BUTTON_NAME = "WhoRolledMinimapButton"
local BUTTON_SIZE = 31
local EDGE_PADDING = 5
local DIAGONAL_INSET = 10

local SHAPES = {
    ROUND = { true, true, true, true },
    SQUARE = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local button

local function Place(angle)
    local radians = math.rad(angle)
    local x, y = math.cos(radians), math.sin(radians)
    local quadrant = 1
    if x < 0 then quadrant = quadrant + 1 end
    if y > 0 then quadrant = quadrant + 2 end
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local rounded = (SHAPES[shape] or SHAPES.ROUND)[quadrant]
    local halfWidth = Minimap:GetWidth() / 2 + EDGE_PADDING
    local halfHeight = Minimap:GetHeight() / 2 + EDGE_PADDING
    if rounded then
        x, y = x * halfWidth, y * halfHeight
    else
        local diagonalWidth = math.sqrt(2 * halfWidth * halfWidth) - DIAGONAL_INSET
        local diagonalHeight = math.sqrt(2 * halfHeight * halfHeight) - DIAGONAL_INSET
        x = math.max(-halfWidth, math.min(x * diagonalWidth, halfWidth))
        y = math.max(-halfHeight, math.min(y * diagonalHeight, halfHeight))
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function FollowCursor()
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    local angle = math.deg(math.atan2(cursorY / scale - centerY, cursorX / scale - centerX)) % 360
    ns.db.minimap.angle = angle
    Place(angle)
end

local function ShowTooltip(self)
    if self.dragging then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(ns.TITLE, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_LEFT_CLICK, 0.9, 0.9, 0.9)
    GameTooltip:AddLine(L.MINIMAP_RIGHT_CLICK, 0.9, 0.9, 0.9)
    GameTooltip:AddLine(L.MINIMAP_DRAG, 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local function Create()
    button = CreateFrame("Button", BUTTON_NAME, Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.UI.ADDON_ICON)
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            ns.Options.Toggle()
        else
            ns.HistoryWindow.Toggle()
        end
    end)
    button:SetScript("OnMouseDown", function() icon:SetPoint("TOPLEFT", 8, -7) end)
    button:SetScript("OnMouseUp", function() icon:SetPoint("TOPLEFT", 7, -6) end)
    button:SetScript("OnDragStart", function(self)
        self.dragging = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", FollowCursor)
    end)
    button:SetScript("OnDragStop", function(self)
        self.dragging = false
        self:SetScript("OnUpdate", nil)
        icon:SetPoint("TOPLEFT", 7, -6)
    end)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function MinimapButton.Refresh()
    if not Minimap then return end
    if not button then
        if ns.db.minimap.hide then return end
        Create()
    end
    Place(ns.db.minimap.angle)
    button:SetShown(not ns.db.minimap.hide)
end

function MinimapButton.SetShown(shown)
    ns.db.minimap.hide = not shown
    MinimapButton.Refresh()
    ns.Fire("SETTING_CHANGED", "minimap")
end

ns.Listen("LOGIN", MinimapButton.Refresh)
ns.Listen("SETTING_CHANGED", function(key)
    if key == nil then MinimapButton.Refresh() end
end)
