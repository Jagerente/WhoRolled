local _, ns = ...

local UI = ns.UI
local L = ns.L
local C = UI.COLORS
local T = UI.TEXT
local W = ns.Widgets
local Rolls = ns.Rolls
local Text = ns.HistoryText

local Rows = {}
ns.HistoryRows = Rows

Rows.HEIGHT = {
    session = 28, drop = 42, note = 42, nav = 26, player = 22,
    heading = 30, tablehead = 20, tablerow = 22, playerrow = 22,
}
Rows.INDENT = 12

local DROP_ICON = 28
local PICK_COLUMN = 56
local ICON_CROP = 0.07
local TIMER_HEIGHT = 2
local TOGGLE_WIDTH = 14
local CHOICE_COLUMN, ROLL_COLUMN = 104, 34
local MARK_GAP = 6
local TABLE_COLUMN = 44
local TABLE_CELLS = 4
local WINNER_FILL = { 0.902, 0.698, 0.282, 0.14 }
local FALLBACK_ICON = 134400
local FILL_OVERHANG = 6
local SELECTED_BAR = 2
Rows.INSET = FILL_OVERHANG

function Rows.SetIcon(texture, icon)
    texture:SetTexture(icon or FALLBACK_ICON)
    texture:SetTexCoord(ICON_CROP, 1 - ICON_CROP, ICON_CROP, 1 - ICON_CROP)
end

function Rows.PaintTimer(bar, record, width)
    local left = Rolls.TimeLeft(record)
    if not left then
        bar:Hide()
        return
    end
    bar:SetWidth(math.max(1, width * left))
    bar:Show()
end

function Rows.ShowItemTooltip(owner, record)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(record.link)
    GameTooltip:Show()
end

function Rows.HandleItemClick(record)
    if IsModifiedClick() and HandleModifiedItemClick then
        HandleModifiedItemClick(record.link)
        return true
    end
    return false
end

local function NewRow(parent, kind, button)
    local row = CreateFrame(button and "Button" or "Frame", nil, parent)
    row.kind = kind
    row:SetHeight(Rows.HEIGHT[kind])
    return row
end

local function LeftText(row, size, color, bold)
    local text = bold and UI.BoldText(row, size, color) or UI.Text(row, size, color)
    text:SetJustifyH("LEFT")
    return text
end

local function RightText(row, size, color)
    local text = UI.Text(row, size, color)
    text:SetJustifyH("RIGHT")
    return text
end

local function AddSelection(row)
    row.selectedFill = row:CreateTexture(nil, "BORDER")
    row.selectedFill:SetColorTexture(unpack(C.selected))
    row.selectedFill:SetPoint("TOPLEFT", -FILL_OVERHANG, 0)
    row.selectedFill:SetPoint("BOTTOMRIGHT", FILL_OVERHANG, 0)
    row.selectedBar = row:CreateTexture(nil, "ARTWORK")
    row.selectedBar:SetColorTexture(unpack(C.accent))
    row.selectedBar:SetWidth(SELECTED_BAR)
    row.selectedBar:SetPoint("TOPLEFT", -FILL_OVERHANG, 0)
    row.selectedBar:SetPoint("BOTTOMLEFT", -FILL_OVERHANG, 0)
    function row:SetSelected(selected)
        self.selectedFill:SetShown(selected)
        self.selectedBar:SetShown(selected)
    end
    row:SetSelected(false)
end

local function CreateSession(parent)
    local row = NewRow(parent, "session")
    row.time = RightText(row, T.label, C.muted)
    row.time:SetPoint("BOTTOMRIGHT", 0, 6)
    row.zone = LeftText(row, T.label, C.muted, true)
    row.zone:SetPoint("BOTTOMLEFT", 0, 6)
    row.zone:SetPoint("RIGHT", row.time, "LEFT", -8, 0)
    function row:Paint(visit)
        self.zone:SetText(Text.Zone(visit.zone))
        self.time:SetText(Text.When(visit.first))
    end
    return row
end

local function CreateNote(parent)
    local row = NewRow(parent, "note")
    row.text = LeftText(row, T.label, C.muted)
    row.text:SetPoint("TOPLEFT", 0, -8)
    row.text:SetPoint("RIGHT")
    row.text:SetWordWrap(true)
    function row:Paint(text)
        self.text:SetText(text)
    end
    return row
end

local function CreateNav(parent, handlers)
    local row = NewRow(parent, "nav", true)
    W.RowHover(row)
    AddSelection(row)
    row.toggle = UI.Text(row, T.body, C.muted)
    row.count = RightText(row, T.label, C.muted)
    row.count:SetPoint("RIGHT")
    row.label = LeftText(row, T.body, C.text)
    function row:Paint(data)
        self.data = data
        local indent = data.depth * Rows.INDENT
        self.toggle:ClearAllPoints()
        self.toggle:SetPoint("LEFT", indent, 0)
        self.toggle:SetText(data.expandable and (data.expanded and "–" or "+") or "")
        self.label:ClearAllPoints()
        self.label:SetPoint("LEFT", indent + TOGGLE_WIDTH, 0)
        self.label:SetPoint("RIGHT", self.count, "LEFT", -8, 0)
        self.label:SetText(data.label)
        self.label:SetTextColor(unpack((data.depth == 0 or data.selected) and C.text or C.muted))
        self.count:SetText(data.count)
        self:SetSelected(data.selected)
    end
    row:SetScript("OnClick", function(self) handlers.select(self.data) end)
    return row
end

local function CreateDrop(parent, handlers)
    local row = NewRow(parent, "drop", true)
    W.RowHover(row)
    AddSelection(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(DROP_ICON, DROP_ICON)
    row.icon:SetPoint("LEFT")
    row.pick = RightText(row, T.label, C.text)
    row.pick:SetPoint("RIGHT")
    row.pick:SetWidth(PICK_COLUMN)
    row.name = LeftText(row, T.body, C.text)
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 1)
    row.name:SetPoint("RIGHT", -PICK_COLUMN - 8, 0)
    row.sub = LeftText(row, T.label, C.muted)
    row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, -1)
    row.sub:SetPoint("RIGHT", -PICK_COLUMN - 8, 0)
    row.timer = row:CreateTexture(nil, "ARTWORK")
    row.timer:SetColorTexture(unpack(C.accent))
    row.timer:SetHeight(TIMER_HEIGHT)
    row.timer:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, -5)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if handlers.rightClick then handlers.rightClick(self.record) end
            return
        end
        if Rows.HandleItemClick(self.record) then return end
        handlers.open(self.record)
    end)
    row:HookScript("OnEnter", function(self) Rows.ShowItemTooltip(self, self.record) end)
    row:HookScript("OnLeave", W.HideHint)

    function row:Paint(record)
        local changed = self.record ~= record
        self.record = record
        if changed and GameTooltip:IsOwned(self) then Rows.ShowItemTooltip(self, record) end
        Rows.SetIcon(self.icon, record.icon)
        self.name:SetText(record.name)
        self.name:SetTextColor(UI.QualityColor(record.quality))
        self.sub:SetText(Text.RowWinner(record))
        self.pick:SetText(Text.RowPick(record, handlers.column and handlers.column()) or "")
        self:SetSelected(handlers.selected ~= nil and handlers.selected(record))
        self:PaintTimer()
    end
    function row:PaintTimer()
        Rows.PaintTimer(self.timer, self.record, self:GetWidth() - DROP_ICON - 8)
    end
    return row
end

local function CreatePlayer(parent, handlers)
    local row = NewRow(parent, "player", true)
    W.RowHover(row)
    row.fill = row:CreateTexture(nil, "BACKGROUND")
    row.fill:SetColorTexture(unpack(WINNER_FILL))
    row.fill:SetPoint("TOPLEFT", -6, 0)
    row.fill:SetPoint("BOTTOMRIGHT", 6, 0)
    row.roll = RightText(row, T.body, C.text)
    row.roll:SetPoint("RIGHT")
    row.roll:SetWidth(ROLL_COLUMN)
    row.choice = LeftText(row, T.body, C.text)
    row.choice:SetPoint("RIGHT", row.roll, "LEFT", -8, 0)
    row.choice:SetWidth(CHOICE_COLUMN)
    row.name = LeftText(row, T.body, C.text)
    row.name:SetPoint("LEFT")
    row.mark = LeftText(row, T.caption, C.muted)
    row.mark:SetPoint("LEFT", row.name, "RIGHT", MARK_GAP, 0)
    row.mark:SetPoint("RIGHT", row.choice, "LEFT", -8, 0)
    row.mark:SetWordWrap(false)
    function row:Paint(record, player)
        local won = record.winner == player.name
        self.player = player
        self.fill:SetShown(won)
        self.name:SetText(player.name)
        self.name:SetTextColor(UI.ClassColor(player.class))
        self.mark:SetText(Text.PlayerMark(record, player) or "")
        self.choice:SetText(Text.PlayerState(record, player))
        self.choice:SetTextColor(unpack(UI.StateColor(player.state)))
        self.roll:SetText(player.roll or "")
        self.roll:SetTextColor(unpack(won and C.accent or C.text))
    end
    row:SetScript("OnClick", function(self) handlers.player(self.player.name) end)
    return row
end

local function CreateHeading(parent)
    local row = NewRow(parent, "heading")
    row.text = LeftText(row, T.heading, C.accent, true)
    row.text:SetPoint("BOTTOMLEFT", 0, 6)
    function row:Paint(text)
        self.text:SetText(text)
    end
    return row
end

local function TableColumns(row, size, color)
    row.cells = {}
    local anchor
    for index = 1, TABLE_CELLS do
        local cell = RightText(row, size, color)
        if anchor then cell:SetPoint("RIGHT", anchor, "LEFT") else cell:SetPoint("RIGHT") end
        cell:SetWidth(TABLE_COLUMN)
        row.cells[index] = cell
        anchor = cell
    end
    row.label = LeftText(row, size, color)
    row.label:SetPoint("LEFT")
    function row:Paint(data)
        self.label:SetText(data.label or "")
        local count = #data.cells
        for index, cell in ipairs(self.cells) do
            local value = data.cells[count - index + 1]
            cell:SetText(value ~= nil and tostring(value) or "")
        end
        self.label:SetPoint("RIGHT", self.cells[math.max(1, count)], "LEFT", -8, 0)
    end
end

local function CreateTableHead(parent)
    local row = NewRow(parent, "tablehead")
    TableColumns(row, T.caption, C.muted)
    return row
end

local function CreateTableRow(parent)
    local row = NewRow(parent, "tablerow")
    TableColumns(row, T.body, C.text)
    return row
end

local function CreatePlayerRow(parent, handlers)
    local row = NewRow(parent, "playerrow", true)
    W.RowHover(row)
    TableColumns(row, T.body, C.text)
    local paint = row.Paint
    function row:Paint(data)
        self.playerName = data.name
        paint(self, data)
    end
    row:SetScript("OnClick", function(self) handlers.player(self.playerName) end)
    return row
end

local FACTORIES = {
    session = CreateSession,
    note = CreateNote,
    nav = CreateNav,
    drop = CreateDrop,
    player = CreatePlayer,
    heading = CreateHeading,
    tablehead = CreateTableHead,
    tablerow = CreateTableRow,
    playerrow = CreatePlayerRow,
}

function Rows.Create(kind, parent, handlers)
    return FACTORIES[kind](parent, handlers)
end

function Rows.NewPool(parent, handlers)
    local pool = { parent = parent, handlers = handlers, free = {}, active = {}, keep = {} }

    function pool:Begin()
        for i = 1, #self.active do
            local row = self.active[i]
            self.keep[row.kind] = self.keep[row.kind] or {}
            table.insert(self.keep[row.kind], row)
            self.active[i] = nil
        end
    end

    local function TakeKept(kept, data)
        if not kept then return nil end
        if data ~= nil then
            for i, row in ipairs(kept) do
                if row.listData == data then return table.remove(kept, i) end
            end
        end
        return table.remove(kept, 1)
    end

    function pool:Take(kind, data)
        local free = self.free[kind]
        local row = TakeKept(self.keep[kind], data) or (free and table.remove(free))
        if not row then row = Rows.Create(kind, self.parent, self.handlers) end
        self.active[#self.active + 1] = row
        row:Show()
        return row
    end

    function pool:Finish()
        for kind, kept in pairs(self.keep) do
            self.free[kind] = self.free[kind] or {}
            for i = #kept, 1, -1 do
                kept[i]:Hide()
                table.insert(self.free[kind], kept[i])
                kept[i] = nil
            end
        end
    end

    return pool
end
