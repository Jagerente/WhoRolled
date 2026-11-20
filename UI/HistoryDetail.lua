local _, ns = ...

local UI = ns.UI
local C = UI.COLORS
local T = UI.TEXT
local W = ns.Widgets
local Rolls = ns.Rolls
local Text = ns.HistoryText
local Rows = ns.HistoryRows

local Detail = {}
ns.HistoryDetail = Detail

local DETAIL_ICON = 36
local SECTION_GAP = 10
local TIMER_HEIGHT = 2
local PLAYER_INSET = 6

local page
local record
local sortedPlayers = {}

local PLAYER_HANDLERS = {
    player = function(name) ns.HistoryWindow.ShowPlayer(name) end,
}

function Detail.Selected()
    return record
end

function Detail.SetRecord(value)
    if record == value then return end
    record = value
    if page then page.scroll:ScrollTo(0, false) end
end

local function CreateItem(parent)
    local item = CreateFrame("Button", nil, parent)
    item:SetPoint("TOPLEFT")
    item:SetPoint("RIGHT")
    item:SetHeight(DETAIL_ICON)
    item.icon = item:CreateTexture(nil, "ARTWORK")
    item.icon:SetSize(DETAIL_ICON, DETAIL_ICON)
    item.icon:SetPoint("LEFT")
    item.name = UI.BoldText(item, T.body, C.text)
    item.name:SetPoint("TOPLEFT", item.icon, "TOPRIGHT", 10, -1)
    item.name:SetPoint("RIGHT")
    item.name:SetJustifyH("LEFT")
    item.source = UI.Text(item, T.label, C.muted)
    item.source:SetPoint("BOTTOMLEFT", item.icon, "BOTTOMRIGHT", 10, 1)
    item.source:SetPoint("RIGHT")
    item.source:SetJustifyH("LEFT")
    item:SetScript("OnEnter", function(self) Rows.ShowItemTooltip(self, record) end)
    item:SetScript("OnLeave", W.HideHint)
    item:SetScript("OnClick", function() Rows.HandleItemClick(record) end)
    return item
end

local function CreateEmpty(parent)
    local empty = UI.Text(parent, T.body, C.muted)
    empty:SetPoint("TOPLEFT")
    empty:SetPoint("RIGHT")
    empty:SetJustifyH("LEFT")
    empty:SetWordWrap(true)
    W.Bind(empty, "DETAIL_EMPTY")
    return empty
end

function Detail.Create(parent, width)
    page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.width = width
    page.empty = CreateEmpty(page)
    page.body = CreateFrame("Frame", nil, page)
    page.body:SetAllPoints()
    local body = page.body
    page.item = CreateItem(body)

    page.status = UI.Text(body, T.body, C.text)
    page.status:SetPoint("TOPLEFT", page.item, "BOTTOMLEFT", 0, -SECTION_GAP)
    page.status:SetPoint("RIGHT")
    page.status:SetJustifyH("LEFT")

    page.timer = body:CreateTexture(nil, "ARTWORK")
    page.timer:SetColorTexture(unpack(C.accent))
    page.timer:SetHeight(TIMER_HEIGHT)
    page.timer:SetPoint("TOPLEFT", page.status, "BOTTOMLEFT", 0, -5)

    page.totals = UI.Text(body, T.label, C.muted)
    page.totals:SetPoint("TOPLEFT", page.status, "BOTTOMLEFT", 0, -SECTION_GAP)
    page.totals:SetPoint("RIGHT")
    page.totals:SetJustifyH("LEFT")
    page.totals:SetWordWrap(true)

    page.divider = UI.Line(body)
    page.scroll = W.Scroll(body, W.SCROLL_GUTTER)
    page.scroll:SetPoint("TOPLEFT", page.divider, "BOTTOMLEFT", 0, -6)
    page.scroll:SetPoint("BOTTOMRIGHT", W.SCROLL_GUTTER, 0)
    page.rows = {}
    return page
end

local function PlaceDivider(totalsShown)
    local anchor = totalsShown and page.totals or page.status
    page.divider:ClearAllPoints()
    page.divider:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -SECTION_GAP)
    page.divider:SetPoint("RIGHT", page, "RIGHT")
end

function Detail.Tick()
    if not page or not record or not page:IsVisible() then return end
    Rows.PaintTimer(page.timer, record, page.width)
end

local function PaintPlayers()
    Rolls.SortedPlayers(record, sortedPlayers)
    local content = page.scroll.content
    local height = Rows.HEIGHT.player
    for index, player in ipairs(sortedPlayers) do
        local row = page.rows[index]
        if not row then
            row = Rows.Create("player", content, PLAYER_HANDLERS)
            row:SetPoint("TOPLEFT", content, "TOPLEFT", PLAYER_INSET, -(index - 1) * height)
            row:SetPoint("RIGHT", content, "RIGHT", -PLAYER_INSET, 0)
            page.rows[index] = row
        end
        row:Paint(record, player)
        row:Show()
    end
    for index = #sortedPlayers + 1, #page.rows do page.rows[index]:Hide() end
    content:SetHeight(math.max(1, #sortedPlayers * height))
end

function Detail.Paint()
    if not page then return end
    page.empty:SetShown(record == nil)
    page.body:SetShown(record ~= nil)
    if not record then return end
    Rows.SetIcon(page.item.icon, record.icon)
    page.item.name:SetText(record.name)
    page.item.name:SetTextColor(UI.QualityColor(record.quality))
    page.item.source:SetText(Text.Source(record))
    page.status:SetText(Text.Status(record))
    local totals = Text.Totals(record)
    page.totals:SetText(totals)
    page.totals:SetShown(totals ~= "")
    PlaceDivider(totals ~= "")
    Detail.Tick()
    PaintPlayers()
end
