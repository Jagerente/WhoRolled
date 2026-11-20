local _, ns = ...

local Rolls = {}
ns.Rolls = Rolls

local STATE_RANK = { need = 1, offspec = 2, transmog = 3, greed = 4, pass = 5, waiting = 6 }
Rolls.STATE_RANK = STATE_RANK

local TICK_SECONDS = 0.1
local OVERDUE_RATIO = 1.5
local SILENT_SECONDS = 180
local HISTORY_LIMIT = 2000

local realStore
local sampleStore
local byKey = {}
local live = {}
local touchedAt = {}
local seenThisSession = {}
local ticker

function Rolls.IsChoice(state)
    return state ~= nil and state ~= "waiting" and state ~= "pass"
end

function Rolls.Records()
    return sampleStore or realStore or {}
end

function Rolls.RealRecords()
    return realStore or {}
end

function Rolls.IsSample()
    return sampleStore ~= nil
end

function Rolls.Live()
    return live
end

function Rolls.FindByKey(key)
    return byKey[key]
end

local QUALITY_FROM_LINK = "|cnIQ(%d+):"
local VIEWER_FIELDS = { [9] = true, [10] = true, [11] = true }

local function ItemKey(itemString)
    local fields, index = {}, 0
    for field in (itemString .. ":"):gmatch("([^:]*):") do
        index = index + 1
        fields[index] = VIEWER_FIELDS[index] and "" or field
    end
    return table.concat(fields, ":")
end

local function QualityFromHex(link)
    local hex = link:match("|c%x%x(%x%x%x%x%x%x)")
    if not hex or not C_Item.GetItemQualityColor then return nil end
    hex = hex:lower()
    for quality = 0, 8 do
        local _, _, _, qualityHex = C_Item.GetItemQualityColor(quality)
        if type(qualityHex) == "string" and qualityHex:lower():sub(-6) == hex then return quality end
    end
end

function Rolls.DescribeItem(link)
    local itemID = tonumber(link:match("item:(%d+)"))
    local quality = C_Item.GetItemQualityByID and ns.Plain(C_Item.GetItemQualityByID(link))
    quality = quality or tonumber(link:match(QUALITY_FROM_LINK)) or QualityFromHex(link)
    local itemString = link:match("|H(item:[^|]+)|h") or link
    return {
        link = link,
        itemKey = ItemKey(itemString),
        itemID = itemID,
        name = link:match("|h%[(.-)%]|h") or link,
        quality = quality,
        icon = itemID and C_Item.GetItemIconByID(itemID) or nil,
    }
end

local function TargetStore(record)
    if record.sample then return sampleStore end
    return realStore
end

local function RemoveLive(record)
    for i = #live, 1, -1 do
        if live[i] == record then table.remove(live, i) end
    end
end

local function TrimStore()
    if not realStore then return end
    local index = 1
    while #realStore > HISTORY_LIMIT and index <= #realStore do
        local record = realStore[index]
        if record.status == "rolling" then
            index = index + 1
        else
            table.remove(realStore, index)
            if record.key then byKey[record.key] = false end
        end
    end
end

local pending = {}

local function FlushChanges()
    if not next(pending) then return end
    wipe(pending)
    ns.Fire("DROPS_CHANGED")
end

function Rolls.Changed(record)
    touchedAt[record] = GetTime()
    seenThisSession[record] = true
    pending[record] = true
    ns.Schedule("WhoRolledDropsChanged", 0, FlushChanges)
end

function Rolls.Now(timer)
    if timer.clock == "history" then
        return ns.Plain(C_LootHistory.GetLootHistoryTime())
    end
    return GetTime()
end

function Rolls.TimeLeft(record)
    local timer = record.timer
    if record.status ~= "rolling" or not timer or not timer.start or not timer.duration or timer.duration <= 0 then return nil end
    local now = Rolls.Now(timer)
    if not now then return nil end
    local left = 1 - (now - timer.start) / timer.duration
    return math.max(0, math.min(1, left)), (now - timer.start) / timer.duration
end

local function IsOverdue(record)
    local _, progress = Rolls.TimeLeft(record)
    if progress then return progress > OVERDUE_RATIO end
    return GetTime() - (touchedAt[record] or GetTime()) > SILENT_SECONDS
end

local function Finish(record, status)
    record.status = status
    RemoveLive(record)
    Rolls.Changed(record)
end

local function Compact(record)
    if record.status == "rolling" then return end
    record.timer = nil
end

function Rolls.End(record)
    if record.status ~= "rolling" then return end
    Finish(record, "ended")
    ns.Fire("ROLL_ENDED", record)
    Compact(record)
end

local function Tick()
    for i = #live, 1, -1 do
        local record = live[i]
        if record and IsOverdue(record) then Rolls.End(record) end
    end
    ns.Fire("ROLL_TICK")
    if #live == 0 and ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function EnsureTicker()
    if ticker or #live == 0 then return end
    ticker = C_Timer.NewTicker(TICK_SECONDS, Tick)
end

function Rolls.Add(fields)
    local record = fields
    record.players = record.players or {}
    record.status = record.status or "rolling"
    record.t = record.t or time()
    local target = TargetStore(record)
    if not target then return nil end
    target[#target + 1] = record
    if record.key then byKey[record.key] = record end
    if record.status == "rolling" then live[#live + 1] = record end
    if not record.sample then TrimStore() end
    Rolls.Changed(record)
    ns.Fire("DROP_ADDED", record)
    EnsureTicker()
    return record
end

function Rolls.Rekey(record, key)
    if record.key then byKey[record.key] = nil end
    record.key = key
    byKey[key] = record
end

function Rolls.FindPlayer(record, name)
    for _, player in ipairs(record.players) do
        if player.name == name then return player end
    end
end

local function EnsurePlayer(record, name)
    local player = Rolls.FindPlayer(record, name)
    if player then return player end
    player = { name = name, state = "waiting" }
    record.players[#record.players + 1] = player
    return player
end

function Rolls.UpdatePlayer(record, update, quiet)
    if not update.name then return end
    local known = Rolls.FindPlayer(record, update.name)
    local player = known or EnsurePlayer(record, update.name)
    local newClass = update.class ~= nil and update.class ~= player.class
    player.class = update.class or player.class
    local chose = update.state ~= nil and update.state ~= "waiting" and update.state ~= player.state
    local rolled = update.roll ~= nil and update.roll ~= player.roll
    if chose then
        player.state = update.state
        player.roll = update.roll
    elseif rolled then
        player.roll = update.roll
    end
    if not quiet and chose then
        ns.Fire("ROLL_CHOICE", record, player)
    elseif not quiet and rolled then
        ns.Fire("ROLL_NUMBER", record, player)
    end
    if chose or rolled or newClass or not known then Rolls.Changed(record) end
    return player
end

function Rolls.SetWinner(record, name, quiet)
    if record.status == "won" and record.winner == name then return end
    record.winner = name
    Finish(record, "won")
    if not quiet then ns.Fire("ROLL_WON", record, Rolls.FindPlayer(record, name)) end
    Compact(record)
end

function Rolls.SetAllPassed(record, quiet)
    if record.status == "passed" then return end
    record.winner = nil
    Finish(record, "passed")
    if not quiet then ns.Fire("ROLL_ALL_PASSED", record) end
    Compact(record)
end

function Rolls.Reopen(record)
    if record.status ~= "ended" then return end
    record.status = "rolling"
    live[#live + 1] = record
    EnsureTicker()
end

function Rolls.CloseUnseen()
    if not realStore then return end
    for _, record in ipairs(realStore) do
        if record.status == "rolling" and not seenThisSession[record] then Rolls.End(record) end
    end
end

function Rolls.Count(record, state)
    local count = 0
    for _, player in ipairs(record.players) do
        if player.state == state then count = count + 1 end
    end
    return count
end

local COUNT_GROUPS = {
    { "need", "offspec" },
    { "greed", "transmog" },
    { "pass" },
}
Rolls.COUNT_GROUPS = COUNT_GROUPS

function Rolls.CountGroup(record, group)
    local count = 0
    for _, state in ipairs(group) do count = count + Rolls.Count(record, state) end
    return count
end

function Rolls.Decided(record)
    local decided = 0
    for _, player in ipairs(record.players) do
        if player.state ~= "waiting" then decided = decided + 1 end
    end
    return decided, #record.players
end

local function ComparePlayers(record)
    return function(a, b)
        local aWon, bWon = a.name == record.winner, b.name == record.winner
        if aWon ~= bWon then return aWon end
        local aRank, bRank = STATE_RANK[a.state] or 9, STATE_RANK[b.state] or 9
        if aRank ~= bRank then return aRank < bRank end
        local aRoll, bRoll = a.roll or -1, b.roll or -1
        if aRoll ~= bRoll then return aRoll > bRoll end
        return a.name < b.name
    end
end

function Rolls.SortedPlayers(record, out)
    out = out or {}
    wipe(out)
    for i, player in ipairs(record.players) do out[i] = player end
    table.sort(out, ComparePlayers(record))
    return out
end

function Rolls.MyPlayer(record)
    return Rolls.FindPlayer(record, ns.Group.PlayerName() or "")
end

function Rolls.BeginSample()
    sampleStore = {}
    ns.Fire("RECORDS_RESET")
end

function Rolls.EndSample()
    if not sampleStore then return end
    for _, record in ipairs(sampleStore) do RemoveLive(record) end
    sampleStore = nil
    ns.Fire("RECORDS_RESET")
end

function Rolls.Clear()
    if not realStore then return end
    for i = #realStore, 1, -1 do
        local record = realStore[i]
        if record.status ~= "rolling" then
            table.remove(realStore, i)
            if record.key then
                byKey[record.key] = false
                ns.charDB.dismissed[record.key] = true
            end
        end
    end
    ns.Fire("RECORDS_RESET")
end

function Rolls.KeepDismissed(present)
    local dismissed = ns.charDB.dismissed
    for key in pairs(dismissed) do
        if not present[key] then dismissed[key] = nil end
    end
end

function Rolls.FindLiveDrop(encounterID, lootListKey, itemKey)
    for i = #live, 1, -1 do
        local record = live[i]
        if not record.sample and record.encounterID == encounterID and record.lootListKey == lootListKey
            and record.itemKey == itemKey then
            return record
        end
    end
end

ns.Listen("DB_READY", function()
    realStore = ns.charDB.drops
    for key in pairs(ns.charDB.dismissed) do byKey[key] = false end
    for _, record in ipairs(realStore) do
        if record.key then byKey[record.key] = record end
        if record.status == "rolling" then live[#live + 1] = record end
        Compact(record)
    end
    TrimStore()
    EnsureTicker()
end)
