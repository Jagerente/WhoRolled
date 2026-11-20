local _, ns = ...

local UI = ns.UI
local L = ns.L
local W = ns.Widgets
local Stats = ns.Stats
local Text = ns.HistoryText
local Rows = ns.HistoryRows
local RowList = ns.RowList

local StatsPage = {}
ns.HistoryStats = StatsPage

local page
local list
local visits = {}
local scope = Stats.ALL

function StatsPage.ScrollToTop()
    if page then page.scroll:ScrollTo(0, false) end
end

local function PickLabel(pick)
    if pick == "none" then return L.STATS_PICK_NONE end
    return UI.StateLabel(pick, Text.ROW_ICON)
end

local function StateHead(state)
    return UI.StateIcon(state, Text.ROW_ICON) or UI.StateText(state)
end

local function AddPicks(result)
    list:Add("heading", L.STATS_PICKS)
    local total = 0
    for _, pick in ipairs(Stats.PICKS) do total = total + result.picks[pick] end
    if total == 0 then
        list:Add("note", L.STATS_NO_PICKS)
        return
    end
    list:Add("tablehead", { cells = { L.STATS_COL_TIMES, L.STATS_COL_WON, L.STATS_COL_RATE } })
    for _, pick in ipairs(Stats.PICKS) do
        local count = result.picks[pick]
        if count > 0 then
            local wins = (pick == "need" or pick == "greed") and result.won[pick] or nil
            list:Add("tablerow", {
                label = PickLabel(pick),
                cells = { count, wins or "", wins and Text.Percent(wins, count) or "" },
            })
        end
    end
end

local function AddPlayers(result)
    if #result.playerList == 0 then return end
    list:Add("heading", L.STATS_PLAYERS)
    list:Add("tablehead", { cells = { StateHead("need"), StateHead("greed"), StateHead("pass"), L.STATS_COL_WON } })
    for _, entry in ipairs(result.playerList) do
        list:Add("playerrow", {
            name = entry.name,
            label = UI.ClassText(entry.name, entry.class),
            cells = { entry.need, entry.greed, entry.pass, entry.won },
        })
    end
end

function StatsPage.Paint(newVisits, newScope)
    visits, scope = newVisits or visits, newScope or scope
    if not page or not page:IsVisible() then return end
    local result = Stats.Compute(visits, scope)
    list:Begin()
    if result.items == 0 then
        list:Add("note", L.STATS_EMPTY)
    else
        AddPicks(result)
        AddPlayers(result)
    end
    list:Finish()
end

local HANDLERS = {
    player = function(name) ns.HistoryWindow.ShowPlayer(name) end,
}

function StatsPage.Create(parent)
    page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page:Hide()
    page.scroll = W.Scroll(page, W.SCROLL_GUTTER)
    page.scroll:SetPoint("TOPLEFT", -Rows.INSET, 0)
    page.scroll:SetPoint("BOTTOMRIGHT", W.SCROLL_GUTTER, 0)
    list = RowList.New(page.scroll, HANDLERS)
    page:SetScript("OnShow", function() StatsPage.Paint() end)
    return page
end
