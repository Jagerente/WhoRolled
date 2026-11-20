local _, ns = ...

local Rows = ns.HistoryRows

local RowList = {}
ns.RowList = RowList

local REVEAL_MARGIN = 8
local INSET = Rows.INSET

local Methods = {}

function Methods:Begin()
    self.count = 0
end

function Methods:Add(kind, data, indent)
    local last = self.entries[self.count]
    self.count = self.count + 1
    local entry = self.entries[self.count] or {}
    entry.kind, entry.data, entry.indent = kind, data, indent or 0
    entry.y = last and (last.y + last.height) or 0
    entry.height = Rows.HEIGHT[kind]
    self.entries[self.count] = entry
end

function Methods:Finish()
    for i = #self.entries, self.count + 1, -1 do self.entries[i] = nil end
    local last = self.entries[self.count]
    self.scroll.content:SetHeight(last and (last.y + last.height) or 1)
    self:Repaint()
end

function Methods:Repaint()
    self.dirty = true
    self:Layout()
end

function Methods:Layout()
    local scroll = self.scroll
    if not scroll:IsVisible() then return end
    local pool = self.pool
    pool:Begin()
    local top = scroll:GetVerticalScroll()
    local bottom = top + scroll:GetHeight()
    local width = scroll.content:GetWidth() - INSET * 2
    local dirty = self.dirty
    for _, entry in ipairs(self.entries) do
        if entry.y + entry.height >= top and entry.y <= bottom then
            local row = pool:Take(entry.kind, entry.data)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scroll.content, "TOPLEFT", INSET + entry.indent, -entry.y)
            row:SetWidth(math.max(1, width - entry.indent))
            if dirty or row.listData ~= entry.data then
                row:Paint(entry.data)
                row.listData = entry.data
            end
        end
    end
    pool:Finish()
    self.dirty = false
end

function Methods:Entries()
    return self.entries
end

function Methods:Rows()
    return self.pool.active
end

function Methods:Reveal(data)
    for _, entry in ipairs(self.entries) do
        if entry.data == data then
            local scroll = self.scroll
            local top = scroll:GetVerticalScroll()
            local height = scroll:GetHeight()
            if entry.y < top then
                scroll:ScrollTo(entry.y - REVEAL_MARGIN, true)
            elseif entry.y + entry.height > top + height then
                scroll:ScrollTo(entry.y + entry.height - height + REVEAL_MARGIN, true)
            end
            return
        end
    end
end

local MT = { __index = Methods }

function RowList.New(scroll, handlers)
    local list = setmetatable({ scroll = scroll, entries = {}, count = 0, pool = Rows.NewPool(scroll.content, handlers) }, MT)
    scroll:HookScript("OnVerticalScroll", function() list:Layout() end)
    scroll:HookScript("OnSizeChanged", function() list:Repaint() end)
    return list
end
