local _, ns = ...

local UI = ns.UI
local L = ns.L
local C = UI.COLORS
local Rolls = ns.Rolls

local Text = {}
ns.HistoryText = Text

local ROW_ICON = 14
local COUNT_GAP = "   "
local RAID_SIZE = 5
local SECONDS_PER_DAY = 86400
Text.ROW_ICON = ROW_ICON

local function SameDay(a, b)
    return date("%Y%m%d", a) == date("%Y%m%d", b)
end

function Text.Clock(t)
    return date(L.TIME_FORMAT, t)
end

function Text.Day(t)
    local now = time()
    if SameDay(t, now) then return L.TODAY end
    if SameDay(t, now - SECONDS_PER_DAY) then return L.YESTERDAY end
    local weekday = ns.ListOf("WEEKDAYS")[date("*t", t).wday]
    local format = date("%Y", t) == date("%Y", now) and L.DATE_FORMAT or L.DATE_FORMAT_YEAR
    return weekday .. " " .. date(format, t)
end

function Text.When(t)
    if SameDay(t, time()) then return Text.Clock(t) end
    return Text.Day(t) .. ", " .. Text.Clock(t)
end

function Text.Zone(zone)
    return zone or L.UNKNOWN_ZONE
end

function Text.Percent(part, whole)
    if whole <= 0 then return "" end
    return string.format("%d%%", math.floor(part / whole * 100 + 0.5))
end

function Text.RollText(player)
    if not player then return "" end
    local state = UI.StateText(player.state)
    if player.roll then return state .. " " .. player.roll end
    return state
end

function Text.Winner(record)
    local player = Rolls.FindPlayer(record, record.winner or "")
    return UI.ClassText(record.winner or "", player and player.class), player
end

function Text.Counts(record)
    local parts = {}
    for _, group in ipairs(Rolls.COUNT_GROUPS) do
        local count = Rolls.CountGroup(record, group)
        if count > 0 then
            local label = UI.StateIcon(group[1], ROW_ICON) or UI.StateText(group[1])
            parts[#parts + 1] = label .. " " .. count
        end
    end
    local waiting = Rolls.Count(record, "waiting")
    if waiting > 0 then
        local key = record.status == "rolling" and L.ROW_WAITING or L.ROW_NO_ANSWER
        parts[#parts + 1] = string.format(key, waiting)
    end
    if #parts == 0 then return L.ROW_NO_CHOICES end
    return table.concat(parts, COUNT_GAP)
end

function Text.PlayerState(record, player)
    if player.state == "waiting" and record.status ~= "rolling" then return L.STATE_NO_ANSWER end
    return UI.StateLabel(player.state, ROW_ICON)
end

function Text.PlayerMark(record, player)
    if record.status ~= "won" then return nil end
    if player.name == record.winner then return record.tie and L.MARK_TIE or nil end
    local winner = Rolls.FindPlayer(record, record.winner or "")
    if winner and winner.roll and player.roll and player.state == winner.state and player.roll > winner.roll then
        return L.MARK_PROTECTED
    end
end

function Text.Status(record)
    if record.status == "rolling" then
        return string.format(L.STATUS_ROLLING, Rolls.Decided(record))
    elseif record.status == "won" then
        local name, player = Text.Winner(record)
        if player and player.state ~= "waiting" then return string.format(L.STATUS_WON, name, Text.RollText(player)) end
        return string.format(L.STATUS_WON_PLAIN, name)
    elseif record.status == "passed" then
        return L.STATUS_ALL_PASSED
    end
    return L.STATUS_ENDED
end

function Text.Source(record)
    local parts = {}
    if record.zone then parts[#parts + 1] = record.zone end
    if record.encounterName then parts[#parts + 1] = record.encounterName end
    parts[#parts + 1] = Text.When(record.t)
    return table.concat(parts, ", ")
end

function Text.Totals(record)
    if #record.players > RAID_SIZE then return Text.Counts(record) end
    return ""
end

function Text.ShortResult(player, rollColor)
    local icon = UI.StateIcon(player.state, ROW_ICON) or UI.StateText(player.state)
    if not player.roll then return icon end
    return icon .. " " .. UI.Colorize(tostring(player.roll), unpack(rollColor))
end

function Text.RowWinner(record)
    if record.status == "rolling" then
        return Text.Counts(record)
    elseif record.status == "passed" then
        return L.STATUS_ALL_PASSED
    elseif record.status ~= "won" then
        return L.ROW_ENDED
    end
    local name, player = Text.Winner(record)
    if not player or player.state == "waiting" then return name end
    return name .. "  " .. Text.ShortResult(player, C.accent)
end

function Text.RowPick(record, name)
    local player
    if name then player = Rolls.FindPlayer(record, name) else player = Rolls.MyPlayer(record) end
    if not player or player.state == "waiting" then return nil end
    local won = record.status == "won" and record.winner == player.name
    return Text.ShortResult(player, won and C.accent or C.text)
end

function Text.ScopeTitle(scope)
    if scope.kind == "day" then return Text.Day(scope.t) end
    if scope.kind == "place" or scope.kind == "visit" then return Text.Zone(scope.zone) end
    return L.SCOPE_ALL
end

function Text.ScopeSummary(scope, items, visits, wins)
    local parts = { ns.Plural(items, "FORMS_ITEMS") }
    if scope.kind == "visit" then table.insert(parts, 1, Text.Day(scope.t) .. " " .. Text.Clock(scope.t)) end
    if visits > 1 then parts[#parts + 1] = ns.Plural(visits, "FORMS_VISITS") end
    if wins > 0 then parts[#parts + 1] = string.format(L.SUMMARY_WON, wins) end
    return table.concat(parts, ", ")
end
