local _, ns = ...

local L = ns.L
local Rolls = ns.Rolls
local Group = ns.Group

local TestMode = { active = false }
ns.TestMode = TestMode

local ROLL_SECONDS = 20
local CHOICE_STEP = 0.5
local REVEAL_DELAY = 0.6
local NUMBER_STEP = 0.12
local TIE_REROLL_DELAY = 0.9
local ITEM_GAP = 2.6
local CONTEXT_PAUSE = 3
local ROLL_MAX = 100
local TIE_ROLL = 77
local PROTECTED_HIGH, PROTECTED_WIN = 96, 70
local YOU = 1

local CAST = {
    { name = "Arthas", class = "PALADIN" },
    { name = "Jaina", class = "MAGE" },
    { name = "Sylvanas", class = "HUNTER" },
    { name = "Illidan", class = "WARLOCK" },
    { name = "Malfurion", class = "DRUID" },
    { name = "Uther", class = "PALADIN" },
}
local GROUP_SIZE = { trio = 2, party = 4, raid = 6 }

local ITEMS = {
    hand = { id = 11815, quality = 3, name = "Hand of Justice" },
    breadth = { id = 13965, quality = 3, name = "Blackhand's Breadth" },
    felstriker = { id = 12590, quality = 4, name = "Felstriker" },
    book = { id = 13353, quality = 4, name = "Book of the Dead" },
    armbraces = { id = 12936, quality = 3, name = "Battleborn Armbraces" },
    teebu = { id = 1728, quality = 4, name = "Teebu's Blazing Longsword" },
    edward = { id = 2243, quality = 4, name = "Hand of Edward the Odd" },
    custodian = { id = 868, quality = 4, name = "Ardent Custodian" },
    brutality = { id = 18832, quality = 4, name = "Brutality Blade" },
    striker = { id = 17069, quality = 4, name = "Striker's Mark" },
    ring = { id = 18821, quality = 4, name = "Quick Strike Ring" },
}

local function Repeat(pick, count)
    local picks = {}
    for i = 1, count do picks[i] = pick end
    return picks
end

local RING_PICKS = { "pass", "need", "greed", "pass", "need", "pass", "greed" }

local MATRIX = {
    {
        zone = "SAMPLE_ZONE_PARTY", people = "party",
        items = {
            { item = "hand", picks = Repeat("need", 5) },
            { item = "felstriker", picks = { "greed", "need", "greed", "pass", "need" } },
            { item = "breadth", picks = Repeat("greed", 5), rolls = { [YOU] = 99 } },
            { item = "book", picks = { "pass", "greed", "pass", "greed", "pass" } },
            { item = "armbraces", picks = Repeat("pass", 5) },
            { item = "hand", picks = { "pass", "pass", "need", "pass", "pass" } },
            { item = "felstriker", picks = { "pass", "need", "greed", "need", "pass" }, tie = { 2, 4 } },
            { item = "breadth", picks = { "need", "greed", false, "pass", "greed" } },
        },
    },
    {
        zone = "SAMPLE_ZONE_WORLD", people = "trio",
        items = {
            { item = "teebu", picks = { "need", "need", "greed" }, rolls = { [YOU] = 97 } },
            { item = "edward", picks = { "greed", "pass", false } },
            { item = "custodian", picks = Repeat("pass", 3) },
        },
    },
    {
        zone = "SAMPLE_ZONE_RAID", people = "raid",
        items = {
            { item = "brutality", picks = { "pass", "greed", "pass", "need", "pass", "greed", "pass" } },
            { item = "striker", picks = { "greed", "greed", "pass", "greed", "greed", "pass", "greed" } },
            { item = "ring", picks = RING_PICKS, rolls = { [5] = 88 }, winner = 5 },
            { item = "ring", picks = RING_PICKS, rolls = { [5] = PROTECTED_HIGH, [2] = PROTECTED_WIN }, winner = 2 },
            { item = "brutality", picks = { "greed", "need", false, "pass", "greed", false, "pass" } },
        },
    },
}
TestMode.MATRIX = MATRIX

local generation = 0
local contextIndex = 0

local function After(delay, callback)
    local current = generation
    C_Timer.After(delay, function()
        if current == generation and TestMode.active then callback() end
    end)
end

local function ItemLink(item)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(item.id) or nil
    return string.format("|cnIQ%d:|Hitem:%d::::::::60:::::::::|h[%s]|h|r", item.quality, item.id, name or item.name)
end

local function Me()
    local _, class = UnitClass("player")
    return { name = Group.PlayerName() or L.YOU, class = ns.Plain(class) }
end

local function People(kind)
    local people = { Me() }
    for i = 1, GROUP_SIZE[kind] do people[#people + 1] = CAST[i] end
    return people
end

local function NumberPool(below, reserved)
    local used = {}
    for _, number in pairs(reserved) do used[number] = true end
    return function()
        local number
        repeat number = math.random(below - 1) until not used[number]
        used[number] = true
        return number
    end
end

local function LowestPlanned(spec)
    local lowest = ROLL_MAX
    for _, number in pairs(spec.rolls or {}) do lowest = math.min(lowest, number) end
    if spec.tie then lowest = math.min(lowest, TIE_ROLL) end
    return lowest
end

local function TopRank(record)
    local best
    for _, player in ipairs(record.players) do
        local rank = Rolls.IsChoice(player.state) and Rolls.STATE_RANK[player.state]
        if rank and (not best or rank < best) then best = rank end
    end
    return best
end

local function Rollers(record)
    local rollers, top = {}, TopRank(record)
    for _, player in ipairs(record.players) do
        if Rolls.IsChoice(player.state) and Rolls.STATE_RANK[player.state] == top then rollers[#rollers + 1] = player end
    end
    return rollers
end

local function Highest(players)
    local best
    for _, player in ipairs(players) do
        if player.roll and (not best or player.roll > best.roll) then best = player end
    end
    return best
end

local function Finish(record, people, spec)
    local winner = spec.winner and Rolls.FindPlayer(record, people[spec.winner].name) or Highest(Rollers(record))
    if winner then
        Rolls.SetWinner(record, winner.name)
    else
        Rolls.SetAllPassed(record)
    end
end

local function Reroll(record, people, spec)
    local tied = { Rolls.FindPlayer(record, people[spec.tie[1]].name), Rolls.FindPlayer(record, people[spec.tie[2]].name) }
    local draw = NumberPool(ROLL_MAX, { TIE_ROLL })
    record.tie = true
    for index, player in ipairs(tied) do
        local roll = draw()
        After(index * NUMBER_STEP, function() Rolls.UpdatePlayer(record, { name = player.name, roll = roll }) end)
    end
    After((#tied + 1) * NUMBER_STEP, function() Finish(record, people, spec) end)
end

local function PlannedRoll(people, spec, player, draw)
    for index, person in ipairs(people) do
        if person.name == player.name then
            if spec.tie and (index == spec.tie[1] or index == spec.tie[2]) then return TIE_ROLL end
            if spec.rolls and spec.rolls[index] then return spec.rolls[index] end
        end
    end
    return draw()
end

local function Reveal(record, people, spec)
    local rollers = Rollers(record)
    local draw = NumberPool(LowestPlanned(spec), spec.rolls or {})
    for index, player in ipairs(rollers) do
        local roll = PlannedRoll(people, spec, player, draw)
        After(index * NUMBER_STEP, function() Rolls.UpdatePlayer(record, { name = player.name, roll = roll }) end)
    end
    local done = (#rollers + 1) * NUMBER_STEP
    if spec.tie then
        After(done + TIE_REROLL_DELAY, function() Reroll(record, people, spec) end)
    else
        After(done, function() Finish(record, people, spec) end)
    end
end

local function NewSampleRecord(item, people, zoneKey)
    local fields = Rolls.DescribeItem(ItemLink(item))
    fields.quality = item.quality
    fields.sample = true
    fields.source = "sample"
    fields.zone = L[zoneKey]
    fields.timer = { clock = "game", start = GetTime(), duration = ROLL_SECONDS }
    local record = Rolls.Add(fields)
    for _, person in ipairs(people) do
        Rolls.UpdatePlayer(record, { name = person.name, class = person.class }, true)
    end
    return record
end

local function PlayItem(start, context, spec, people)
    local picked = #people * CHOICE_STEP
    After(start, function()
        local record = NewSampleRecord(ITEMS[spec.item], people, context.zone)
        for index, person in ipairs(people) do
            local pick = spec.picks[index]
            if pick then
                After(index * CHOICE_STEP, function() Rolls.UpdatePlayer(record, { name = person.name, class = person.class, state = pick }) end)
            end
        end
        After(picked + REVEAL_DELAY, function() Reveal(record, people, spec) end)
    end)
    local tieTime = spec.tie and (TIE_REROLL_DELAY + 3 * NUMBER_STEP) or 0
    return start + picked + REVEAL_DELAY + (#people + 1) * NUMBER_STEP + tieTime
end

local function PlayContext(context)
    local people = People(context.people)
    local finish = 0
    for index, spec in ipairs(context.items) do
        finish = math.max(finish, PlayItem((index - 1) * ITEM_GAP, context, spec, people))
    end
    return finish
end

local function PlayNext()
    contextIndex = contextIndex % #MATRIX + 1
    local duration = PlayContext(MATRIX[contextIndex])
    After(duration + CONTEXT_PAUSE, PlayNext)
end

local function SetActive(active)
    if TestMode.active == active then return end
    TestMode.active = active
    generation = generation + 1
    if active then
        Rolls.BeginSample()
        contextIndex = 0
        ns.Fire("TEST_MODE_CHANGED", true)
        PlayNext()
    else
        Rolls.EndSample()
        ns.Fire("TEST_MODE_CHANGED", false)
    end
end

function TestMode.Start()
    SetActive(true)
end

function TestMode.Stop()
    SetActive(false)
end

function TestMode.Toggle()
    SetActive(not TestMode.active)
end

ns.Listen("DROP_ADDED", function(record)
    if TestMode.active and not record.sample then TestMode.Stop() end
end)
