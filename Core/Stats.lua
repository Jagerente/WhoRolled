local _, ns = ...

local Rolls = ns.Rolls
local Group = ns.Group

local Stats = {}
ns.Stats = Stats

local VISIT_GAP_SECONDS = 1800
local PICK_OF_STATE = { need = "need", offspec = "need", greed = "greed", transmog = "greed", pass = "pass", waiting = "none" }
Stats.PICKS = { "need", "greed", "pass", "none" }

function Stats.DayKey(t)
    return date("%Y-%m-%d", t)
end

local function JoinsVisit(visit, record)
    return visit.zone == record.zone and visit.first - record.t <= VISIT_GAP_SECONDS
end

function Stats.Visits(records, accept)
    local visits, visit = {}, nil
    for i = #records, 1, -1 do
        local record = records[i]
        if not accept or accept(record) then
            if not visit or not JoinsVisit(visit, record) then
                visit = { zone = record.zone, first = record.t, records = {} }
                visits[#visits + 1] = visit
            end
            visit.first = record.t
            visit.records[#visit.records + 1] = record
        end
    end
    for _, each in ipairs(visits) do
        each.id = (each.zone or "") .. "@" .. each.first
        each.day = Stats.DayKey(each.first)
    end
    return visits
end

function Stats.Days(visits)
    local days, byKey = {}, {}
    for _, visit in ipairs(visits) do
        local day = byKey[visit.day]
        if not day then
            day = { key = visit.day, t = visit.first, visits = {} }
            byKey[visit.day] = day
            days[#days + 1] = day
        end
        day.visits[#day.visits + 1] = visit
    end
    return days
end

function Stats.Places(visits)
    local places, byZone = {}, {}
    for _, visit in ipairs(visits) do
        local zone = visit.zone or ""
        local place = byZone[zone]
        if not place then
            place = { zone = visit.zone, visits = {} }
            byZone[zone] = place
            places[#places + 1] = place
        end
        place.visits[#place.visits + 1] = visit
    end
    return places
end

local ALL = { kind = "all" }
Stats.ALL = ALL

function Stats.DayScope(day)
    return { kind = "day", day = day.key, t = day.t }
end

function Stats.PlaceScope(zone)
    return { kind = "place", zone = zone }
end

function Stats.VisitScope(visit)
    return { kind = "visit", visit = visit.id, zone = visit.zone, t = visit.first, day = visit.day }
end

function Stats.ScopeId(scope)
    if scope.kind == "day" then return "d:" .. scope.day end
    if scope.kind == "place" then return "p:" .. (scope.zone or "") end
    if scope.kind == "visit" then return "v:" .. scope.visit end
    return "all"
end

function Stats.VisitInScope(visit, scope)
    local kind = scope.kind
    if kind == "day" then return visit.day == scope.day end
    if kind == "place" then return visit.zone == scope.zone end
    if kind == "visit" then return visit.id == scope.visit end
    return true
end

local function IsMyWin(record, me)
    return record.status == "won" and me ~= nil and record.winner == me
end

function Stats.Tally(visits, scope)
    local items, count, wins = 0, 0, 0
    local me = Group.PlayerName()
    for _, visit in ipairs(visits) do
        if not scope or Stats.VisitInScope(visit, scope) then
            count = count + 1
            items = items + #visit.records
            for _, record in ipairs(visit.records) do
                if IsMyWin(record, me) then wins = wins + 1 end
            end
        end
    end
    return items, count, wins
end

local function NewResult()
    local result = { items = 0, picks = {}, won = {}, players = {}, playerList = {} }
    for _, pick in ipairs(Stats.PICKS) do
        result.picks[pick] = 0
        result.won[pick] = 0
    end
    return result
end

local function PlayerEntry(result, name, class)
    local entry = result.players[name]
    if not entry then
        entry = { name = name, need = 0, greed = 0, pass = 0, won = 0 }
        result.players[name] = entry
        result.playerList[#result.playerList + 1] = entry
    end
    entry.class = entry.class or class
    return entry
end

local function AddPlayers(result, record)
    for _, player in ipairs(record.players) do
        local pick = PICK_OF_STATE[player.state]
        if pick and pick ~= "none" then
            local entry = PlayerEntry(result, player.name, player.class)
            entry[pick] = entry[pick] + 1
        end
    end
    if record.status == "won" and record.winner then
        local winner = Rolls.FindPlayer(record, record.winner)
        local entry = PlayerEntry(result, record.winner, winner and winner.class)
        entry.won = entry.won + 1
    end
end

local function AddMine(result, record, mine, me)
    local pick = PICK_OF_STATE[mine.state]
    if not pick or (pick == "none" and record.status == "rolling") then return end
    result.picks[pick] = result.picks[pick] + 1
    if IsMyWin(record, me) then result.won[pick] = result.won[pick] + 1 end
end

local function ComparePlayers(a, b)
    if a.need ~= b.need then return a.need > b.need end
    if a.won ~= b.won then return a.won > b.won end
    return a.name < b.name
end

function Stats.Compute(visits, scope)
    local me = Group.PlayerName()
    local result = NewResult()
    for _, visit in ipairs(visits) do
        if not scope or Stats.VisitInScope(visit, scope) then
            for _, record in ipairs(visit.records) do
                result.items = result.items + 1
                local mine = me and Rolls.FindPlayer(record, me)
                if mine then AddMine(result, record, mine, me) end
                AddPlayers(result, record)
            end
        end
    end
    table.sort(result.playerList, ComparePlayers)
    return result
end
