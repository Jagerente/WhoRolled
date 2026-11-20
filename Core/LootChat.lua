local _, ns = ...

local Rolls = ns.Rolls
local Group = ns.Group
local History = ns.LootHistorySource

local Chat = {}
ns.LootChatSource = Chat

local MATCH_SECONDS = 600
local ENCOUNTER_LINK_PREFIX = "|HlootHistory:"

local TEMPLATES = {
    { "LOOT_ROLL_NEED", "choice", "need" },
    { "LOOT_ROLL_NEED_SELF", "choice", "need", true },
    { "LOOT_ROLL_NEED_SELF_OFF_SPEC", "choice", "offspec", true },
    { "LOOT_ROLL_GREED", "choice", "greed" },
    { "LOOT_ROLL_GREED_SELF", "choice", "greed", true },
    { "LOOT_ROLL_DISENCHANT", "choice", "greed" },
    { "LOOT_ROLL_DISENCHANT_SELF", "choice", "greed", true },
    { "LOOT_ROLL_PASSED", "choice", "pass" },
    { "LOOT_ROLL_PASSED_SELF", "choice", "pass", true },
    { "LOOT_ROLL_PASSED_AUTO", "choice", "pass" },
    { "LOOT_ROLL_PASSED_AUTO_FEMALE", "choice", "pass" },
    { "LOOT_ROLL_PASSED_SELF_AUTO", "choice", "pass", true },
    { "LOOT_ROLL_ROLLED_NEED", "roll", "need" },
    { "LOOT_ROLL_ROLLED_NEED_ROLE_BONUS", "roll", "need" },
    { "LOOT_ROLL_ROLLED_GREED", "roll", "greed" },
    { "LOOT_ROLL_ROLLED_DE", "roll", "greed" },
    { "LOOT_ROLL_ROLLED_TRANSMOG", "roll", "transmog" },
    { "LOOT_ROLL_WON", "won" },
    { "LOOT_ROLL_YOU_WON", "won", nil, true },
    { "LOOT_ROLL_WON_NO_SPAM_NEED", "won", "need" },
    { "LOOT_ROLL_WON_NO_SPAM_NEED_OFF_SPEC", "won", "offspec" },
    { "LOOT_ROLL_WON_NO_SPAM_GREED", "won", "greed" },
    { "LOOT_ROLL_WON_NO_SPAM_DE", "won", "greed" },
    { "LOOT_ROLL_WON_NO_SPAM_TRANSMOGRIFICATION", "won", "transmog" },
    { "LOOT_ROLL_YOU_WON_NO_SPAM_NEED", "won", "need", true },
    { "LOOT_ROLL_YOU_WON_NO_SPAM_NEED_OFF_SPEC", "won", "offspec", true },
    { "LOOT_ROLL_YOU_WON_NO_SPAM_GREED", "won", "greed", true },
    { "LOOT_ROLL_YOU_WON_NO_SPAM_DE", "won", "greed", true },
    { "LOOT_ROLL_YOU_WON_NO_SPAM_TRANSMOG", "won", "transmog", true },
    { "LOOT_ROLL_ALL_PASSED", "allPassed" },
    { "LOOT_ROLL_STARTED", "started" },
}

local MAGIC = "([%^%$%(%)%%%.%[%]%*%+%-%?])"

local function Literal(text)
    return (text:gsub(MAGIC, "%%%1"))
end

local function Compile(format)
    local parts, fields, literal = { "^" }, {}, 0
    local position, sequence = 1, 0
    while position <= #format do
        local start, finish, index, kind = format:find("%%(%d*)%$?([sd])", position)
        local escaped = format:find("%%%%", position)
        if escaped and (not start or escaped < start) then
            parts[#parts + 1] = Literal(format:sub(position, escaped - 1)) .. "%%"
            literal = literal + escaped - position + 1
            position = escaped + 2
        elseif start then
            parts[#parts + 1] = Literal(format:sub(position, start - 1))
            literal = literal + start - position
            if index == "" then
                sequence = sequence + 1
                index = sequence
            else
                index = tonumber(index)
            end
            parts[#parts + 1] = kind == "d" and "(%-?%d+)" or "(.-)"
            fields[#fields + 1] = { index = index, kind = kind }
            position = finish + 1
        else
            parts[#parts + 1] = Literal(format:sub(position))
            literal = literal + #format - position + 1
            position = #format + 1
        end
    end
    parts[#parts + 1] = "$"
    return table.concat(parts), fields, literal
end

local compiled = {}

local function Build()
    wipe(compiled)
    for _, entry in ipairs(TEMPLATES) do
        local format = _G[entry[1]]
        if type(format) == "string" and format ~= "" then
            local pattern, fields, literal = Compile(format)
            compiled[#compiled + 1] = {
                pattern = pattern, fields = fields, literal = literal,
                kind = entry[2], state = entry[3], self = entry[4],
                linked = format:sub(1, #ENCOUNTER_LINK_PREFIX) == ENCOUNTER_LINK_PREFIX,
            }
        end
    end
    table.sort(compiled, function(a, b) return a.literal > b.literal end)
end
Chat.Build = Build

local function CleanName(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]*:", ""):gsub("|r", "")
    text = text:match("|h%[?(.-)%]?|h") or text
    return Group.ShortName(strtrim(text))
end

local function IsSingleItemLink(text)
    local _, links = text:gsub("|Hitem:", "")
    return links == 1 and text:match("^|c.-|r$") ~= nil
end

local function Read(template, captures)
    local event = { kind = template.kind, state = template.state }
    for i, field in ipairs(template.fields) do
        local value = captures[i]
        if field.kind == "d" then
            if template.linked and field.index == 1 then
                event.linkID = tonumber(value)
            else
                event.roll = tonumber(value)
            end
        elseif value:find("|Hitem:", 1, true) then
            event.link = value
        else
            event.name = CleanName(value)
        end
    end
    if template.self then event.name = Group.PlayerName() end
    return event
end

function Chat.Parse(text)
    for _, template in ipairs(compiled) do
        local captures = { text:match(template.pattern) }
        if captures[1] then
            local event = Read(template, captures)
            if event.link and (template.kind ~= "started" or IsSingleItemLink(event.link)) then
                return event
            end
        end
    end
end

local function SameDrop(record, linkID)
    if record.source == "chat" then return record.linkID == nil or linkID == nil or record.linkID == linkID end
    return History.LinkFits(linkID, record.encounterID, record.lootListKey)
end

local function Matches(record, event, itemKey)
    if record.sample or record.itemKey ~= itemKey or not SameDrop(record, event.linkID) then return false end
    return time() - record.t < MATCH_SECONDS
end

local function FindRecord(event, itemKey)
    local fallback
    for _, record in ipairs(Rolls.Live()) do
        if Matches(record, event, itemKey) then
            if event.kind ~= "choice" or not event.name then return record end
            local player = Rolls.FindPlayer(record, event.name)
            if not player or player.state == "waiting" then return record end
            fallback = fallback or record
        end
    end
    return fallback
end

local function HistoryCovers(event, itemKey)
    local records = Rolls.RealRecords()
    for i = #records, 1, -1 do
        local record = records[i]
        if record.source == "history" and Matches(record, event, itemKey) then return true end
    end
    return false
end

local function SeedWaiters(record)
    for _, name in ipairs(Group.Members()) do
        Rolls.UpdatePlayer(record, { name = name, class = Group.ClassOf(name) }, true)
    end
end

local function NewRecord(event)
    local fields = Rolls.DescribeItem(event.link)
    fields.source = "chat"
    fields.linkID = event.linkID
    fields.zone = ns.LootHistorySource.Zone()
    local record = Rolls.Add(fields)
    if record then SeedWaiters(record) end
    return record
end

local function Handle(event)
    local itemKey = Rolls.DescribeItem(event.link).itemKey
    if HistoryCovers(event, itemKey) then return end
    local record = FindRecord(event, itemKey)
    if record and record.source ~= "chat" then return end
    record = record or NewRecord(event)
    if not record then return end
    if event.kind == "choice" or event.kind == "roll" then
        Rolls.UpdatePlayer(record, { name = event.name, class = Group.ClassOf(event.name), state = event.state, roll = event.roll })
    elseif event.kind == "won" then
        if event.roll then
            Rolls.UpdatePlayer(record, { name = event.name, class = Group.ClassOf(event.name), state = event.state, roll = event.roll })
        end
        Rolls.SetWinner(record, event.name)
    elseif event.kind == "allPassed" then
        Rolls.SetAllPassed(record)
    end
end

local function OnLootMessage(text)
    if ns.IsSecret(text) or type(text) ~= "string" then return end
    local event = Chat.Parse(text)
    if event then Handle(event) end
end

ns.Listen("LOGIN", function()
    Build()
    ns.RegisterEvent("CHAT_MSG_LOOT", OnLootMessage)
end)
