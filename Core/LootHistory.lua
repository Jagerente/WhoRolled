local _, ns = ...

local Rolls = ns.Rolls
local Group = ns.Group
local Plain = ns.Plain

local Source = {}
ns.LootHistorySource = Source

local TRASH_ENCOUNTER = 0
local RESCAN_DELAY = 0.5
local ADOPT_SECONDS = 120

local STATE_BY_ENUM = {}

local function BuildStateMap()
    local states = Enum and Enum.EncounterLootDropRollState
    if not states then return end
    local names = {
        NeedMainSpec = "need", NeedOffSpec = "offspec", Transmog = "transmog",
        Greed = "greed", NoRoll = "waiting", Pass = "pass",
    }
    for enumName, state in pairs(names) do
        if states[enumName] ~= nil then STATE_BY_ENUM[states[enumName]] = state end
    end
end

local function Available()
    return C_LootHistory ~= nil and C_LootHistory.GetSortedInfoForDrop ~= nil
end

local function DropKey(encounterID, lootListKey, startTime)
    return encounterID .. ":" .. lootListKey .. ":" .. tostring(startTime or 0)
end

local function CurrentZone()
    local inInstance = IsInInstance()
    if inInstance then
        local name = GetInstanceInfo()
        if name and name ~= "" then return name end
    end
    return GetRealZoneText and GetRealZoneText() or nil
end
Source.Zone = CurrentZone

local function EncounterName(encounterID)
    if encounterID == TRASH_ENCOUNTER or not C_LootHistory.GetInfoForEncounter then return nil end
    local info = C_LootHistory.GetInfoForEncounter(encounterID)
    return info and Plain(info.encounterName) or nil
end

local function LinkFits(linkID, encounterID, lootListKey)
    return linkID == nil or linkID == encounterID or linkID == lootListKey
end
Source.LinkFits = LinkFits

local function FindChatOrphan(encounterID, lootListKey, itemKey)
    local now = time()
    local records = Rolls.RealRecords()
    for i = #records, 1, -1 do
        local record = records[i]
        if now - record.t >= ADOPT_SECONDS then return nil end
        if record.source == "chat" and not record.sample and record.itemKey == itemKey
            and LinkFits(record.linkID, encounterID, lootListKey) then
            return record
        end
    end
end

local function ForgetChatWaiters(record, info)
    local listed = {}
    for _, rollInfo in ipairs(info.rollInfos) do
        local name = Group.ShortName(Plain(rollInfo.playerName))
        if name then listed[name] = true end
    end
    for i = #record.players, 1, -1 do
        local player = record.players[i]
        if player.state == "waiting" and not listed[player.name] then table.remove(record.players, i) end
    end
end

local function NewRecord(encounterID, info, key)
    local fields = Rolls.DescribeItem(info.itemHyperlink)
    fields.key = key
    fields.source = "history"
    fields.encounterID = encounterID
    fields.lootListKey = info.lootListKey
    fields.encounterName = EncounterName(encounterID)
    fields.zone = CurrentZone()
    fields.timer = { clock = "history", start = Plain(info.startTime), duration = Plain(info.duration) }
    return Rolls.Add(fields)
end

local function Adopt(record, key, encounterID, lootListKey, info)
    Rolls.Rekey(record, key)
    record.source = "history"
    record.linkID = nil
    record.encounterID = encounterID
    record.lootListKey = lootListKey
    record.timer = { clock = "history", start = Plain(info.startTime), duration = Plain(info.duration) }
    return record
end

local function Resolve(encounterID, info)
    local link = Plain(info.itemHyperlink)
    local lootListKey = Plain(info.lootListKey)
    if not link or not lootListKey then return nil end
    local key = DropKey(encounterID, lootListKey, Plain(info.startTime))
    local known = Rolls.FindByKey(key)
    if known ~= nil then return known or nil end
    local itemKey = Rolls.DescribeItem(link).itemKey
    local moved = Rolls.FindLiveDrop(encounterID, lootListKey, itemKey)
    if moved then return Adopt(moved, key, encounterID, lootListKey, info) end
    local orphan = FindChatOrphan(encounterID, lootListKey, itemKey)
    if orphan then
        Adopt(orphan, key, encounterID, lootListKey, info)
        ForgetChatWaiters(orphan, info)
        return orphan
    end
    return NewRecord(encounterID, info, key)
end
Source.DropKey = DropKey

local function ApplyPlayers(record, info, quiet)
    for _, rollInfo in ipairs(info.rollInfos) do
        Rolls.UpdatePlayer(record, {
            name = Group.ShortName(Plain(rollInfo.playerName)),
            class = Plain(rollInfo.playerClass),
            state = STATE_BY_ENUM[Plain(rollInfo.state)],
            roll = Plain(rollInfo.roll),
        }, quiet)
    end
end

local function ApplyResult(record, info, quiet)
    local tie = Plain(info.isTied) == true
    if tie ~= (record.tie == true) then
        record.tie = tie
        Rolls.Changed(record)
    end
    local winner = info.winner and Group.ShortName(Plain(info.winner.playerName))
    if winner then
        if record.status == "ended" then Rolls.Reopen(record) end
        Rolls.SetWinner(record, winner, quiet)
    elseif Plain(info.allPassed) then
        if record.status == "ended" then Rolls.Reopen(record) end
        Rolls.SetAllPassed(record, quiet)
    end
end

local function Apply(encounterID, info, quiet)
    if type(info) ~= "table" or type(info.rollInfos) ~= "table" then return end
    local record = Resolve(encounterID, info)
    if not record then return end
    ApplyPlayers(record, info, quiet)
    ApplyResult(record, info, quiet)
    return record
end
Source.Apply = Apply

local function ReadDrop(encounterID, lootListKey)
    encounterID, lootListKey = Plain(encounterID), Plain(lootListKey)
    if not encounterID or not lootListKey then return end
    Apply(encounterID, C_LootHistory.GetSortedInfoForDrop(encounterID, lootListKey), false)
end

local function ScanEncounter(encounterID, quiet, present)
    local drops = C_LootHistory.GetSortedDropsForEncounter(encounterID)
    if type(drops) ~= "table" then return end
    for _, info in ipairs(drops) do
        local lootListKey = Plain(info.lootListKey)
        if present and lootListKey then present[DropKey(encounterID, lootListKey, Plain(info.startTime))] = true end
        Apply(encounterID, info, quiet)
    end
end

local function EncounterIDs()
    local ids = { TRASH_ENCOUNTER }
    local infos = C_LootHistory.GetAllEncounterInfos and C_LootHistory.GetAllEncounterInfos()
    if type(infos) == "table" then
        for _, info in ipairs(infos) do
            local id = Plain(info.encounterID)
            if id and id ~= TRASH_ENCOUNTER then ids[#ids + 1] = id end
        end
    end
    return ids
end

function Source.ScanAll(quiet)
    local present = {}
    if not Available() then return present end
    for _, encounterID in ipairs(EncounterIDs()) do
        ScanEncounter(encounterID, quiet, present)
    end
    return present
end

local function RescanSoon()
    ns.Schedule("WhoRolledRescan", RESCAN_DELAY, function() Source.ScanAll(false) end)
end

ns.Listen("INIT", BuildStateMap)

ns.Listen("LOGIN", function()
    if Available() then
        ns.RegisterEvent("LOOT_HISTORY_UPDATE_DROP", ReadDrop)
        ns.RegisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER", function(encounterID)
            encounterID = Plain(encounterID)
            if encounterID then ScanEncounter(encounterID, false) end
        end)
        ns.RegisterEvent("START_LOOT_ROLL", RescanSoon)
    end
    Rolls.KeepDismissed(Source.ScanAll(true))
    Rolls.CloseUnseen()
end)
