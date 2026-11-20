local _, ns = ...

local L = {}
ns.L = L

local STRINGS = {}

STRINGS.enUS = {
    NAV_FLOAT = "Floating text",
    NAV_WINDOW = "Windows",
    NAV_GENERAL = "General",
    NAV_ABOUT = "About",

    PREVIEW = "Preview",
    PREVIEW_DESC = "Plays example rolls in a loop so you can tune the floating text and the windows. Nothing is saved.",

    STATE_NEED = "Need",
    STATE_OFFSPEC = "Need (off-spec)",
    STATE_TRANSMOG = "Transmog",
    STATE_GREED = "Greed",
    STATE_PASS = "Pass",
    STATE_WAITING = "Waiting",
    STATE_NO_ANSWER = "Didn't pick",

    FLOAT_CHOICE = "%s: %s",
    FLOAT_WON = "%s won %s (%s)",
    FLOAT_WON_PLAIN = "%s won %s",
    FORMS_PLAYERS = "player|players",
    FLOAT_SPOT_HANDLE = "Floating text",
    FLOAT_SPOT_HANDLE_DESC = "Drag to move.",

    FILTER_ALL = "All",
    FILTER_PICKED = "Picked",
    FILTER_WON = "Won",
    TAB_ROLLS = "Rolls",
    TAB_STATS = "Stats",
    GROUP_DAYS = "Days",
    GROUP_PLACES = "Places",
    TODAY = "Today",
    YESTERDAY = "Yesterday",
    WEEKDAYS = "Sun|Mon|Tue|Wed|Thu|Fri|Sat",
    DATE_FORMAT_YEAR = "%m/%d/%Y",
    FORMS_ITEMS = "item|items",
    FORMS_VISITS = "visit|visits",
    SUMMARY_WON = "won %d",
    SCOPE_ALL = "All rolls",
    STATS_PICKS = "Your picks",
    STATS_COL_TIMES = "Times",
    STATS_COL_WON = "Won",
    STATS_COL_RATE = "Win %",
    STATS_PICK_NONE = "Didn't pick",
    STATS_NO_PICKS = "You didn't take part in these rolls.",
    STATS_PLAYERS = "Players",
    STATS_EMPTY = "No rolls here yet.",
    SEARCH = "Search",
    HISTORY_TITLE = "Roll history",
    DETAIL_EMPTY = "Select a roll to see who picked what and who won.",
    RECENT_TITLE = "Rolls",
    RECENT_TITLE_PREVIEW = "Rolls (preview)",
    RECENT_EMPTY = "No rolls yet.",
    RECENT_HINT = "Click: roll history\nRight-click: settings\nDrag: move",
    EMPTY = "No rolls yet. Items show up here when your group rolls on loot.",
    EMPTY_FILTER = "Nothing matches this filter.",
    SAMPLE_NOTE = "Preview: example rolls, nothing is saved.",
    UNKNOWN_ZONE = "Unknown place",
    TIME_FORMAT = "%H:%M",
    DATE_FORMAT = "%m/%d",
    ROW_YOU = "You",
    ROW_ENDED = "No result",
    ROW_WAITING = "%d waiting",
    ROW_NO_ANSWER = "%d didn't pick",
    ROW_NO_CHOICES = "Nobody picked yet",

    STATUS_ROLLING = "Rolling, %d of %d picked",
    STATUS_WON = "%s won with %s",
    STATUS_WON_PLAIN = "%s won",
    STATUS_ALL_PASSED = "Everyone passed",
    STATUS_ENDED = "Ended, the game sent no result",
    MARK_TIE = "reroll",
    MARK_PROTECTED = "has a copy",

    YOU = "You",
    SAMPLE_ZONE_PARTY = "Blackrock Spire",
    SAMPLE_ZONE_RAID = "Molten Core",
    SAMPLE_ZONE_WORLD = "Stranglethorn Vale",

    FLOAT_ENABLED = "Show floating text",
    SECTION_FLOAT_WHAT = "What to show",
    FLOAT_CHOICES = "Players' picks",
    FLOAT_CHOICES_DESC = "Need, Greed or Pass with the player's name the moment they press it. Off: only the winner.",
    FLOAT_WINNER = "Winner",
    FLOAT_WINNER_DESC = "A larger gold line: who won the item and with what, for example Need 87.",
    FLOAT_QUALITY = "Items of this quality and better",
    QUALITY_2 = "Uncommon",
    QUALITY_3 = "Rare",
    QUALITY_4 = "Epic",
    SECTION_LOOK = "Look",
    FLOAT_SIZE = "Text size",
    FLOAT_TIME = "Time on screen",
    SECONDS_FORMAT = "%d s",
    RECENTER_SPOT = "Move the text back",

    SECTION_WINDOW = "Rolls window",
    WINDOW_MODE = "Show the window",
    WINDOW_MODE_always = "Always",
    WINDOW_MODE_group = "In a group",
    WINDOW_MODE_manual = "On command",
    WINDOW_MODE_EXPLAIN = "Always and In a group bring the window back with each new roll. On command: only /wroll window opens it.",
    WINDOW_ROWS = "Rolls in the window",
    LOCKED = "Lock the window",
    WINDOW_OPACITY = "Background opacity",
    RECENTER_WINDOW = "Move the window back",
    SECTION_HISTORY = "Roll history",
    OPEN_HISTORY = "Open roll history",
    HISTORY_EXPLAIN = "History is saved per character, the last 2000 items.",
    CLEAR_HISTORY = "Clear history",
    CLEAR_HISTORY_CONFIRM = "Click again to clear this character's history",

    SECTION_BEHAVIOR = "Behavior",
    MINIMAP_BUTTON = "Minimap button",
    MINIMAP_LEFT_CLICK = "Click: roll history",
    MINIMAP_RIGHT_CLICK = "Right-click: settings",
    MINIMAP_DRAG = "Drag: move around the minimap",
    LANGUAGE = "Language",
    LANGUAGE_auto = "Game",
    LANGUAGE_enUS = "English",
    LANGUAGE_ruRU = "Русский",
    RESET = "Reset all settings",
    RESET_CONFIRM = "Click again to reset everything",

    SETTINGS_DESC = "Shows who picked Need, Greed or Pass, what they rolled and who won, and keeps every roll in a history window.",
    SETTINGS_OPEN = "Open settings",

    ABOUT_AUTHOR = "Author",
    ABOUT_SHAPESHIFT = "Click to shapeshift",
    ABOUT_WEBSITE = "Website",
    ABOUT_COPY = "Copy",
    ABOUT_COPY_HINT = "Press Ctrl+C",
    ABOUT_COMMAND = "Chat commands",
    ABOUT_COMMAND_HISTORY = "Opens or closes the roll history",
    ABOUT_COMMAND_WINDOW = "Shows or hides the rolls window",
    ABOUT_COMMAND_OPTIONS = "Opens this window",
    ABOUT_COMMAND_TEST = "Turns the preview on or off",
    ABOUT_FONT_CREDIT = "Fira Sans font, SIL Open Font License 1.1.",
}

STRINGS.ruRU = {
    NAV_FLOAT = "Всплывающий текст",
    NAV_WINDOW = "Окна",
    NAV_GENERAL = "Общие",
    NAV_ABOUT = "Об аддоне",

    PREVIEW = "Превью",
    PREVIEW_DESC = "Проигрывает примеры роллов по кругу, чтобы настроить всплывающий текст и окна. Ничего не сохраняется.",

    STATE_NEED = "Need",
    STATE_OFFSPEC = "Need (оффспек)",
    STATE_TRANSMOG = "Трансмог",
    STATE_GREED = "Greed",
    STATE_PASS = "Pass",
    STATE_WAITING = "Думает",
    STATE_NO_ANSWER = "Без выбора",

    FLOAT_CHOICE = "%s: %s",
    FLOAT_WON = "%s забирает %s (%s)",
    FLOAT_WON_PLAIN = "%s забирает %s",
    FORMS_PLAYERS = "игрок|игрока|игроков",
    FLOAT_SPOT_HANDLE = "Всплывающий текст",
    FLOAT_SPOT_HANDLE_DESC = "Перетащите, чтобы передвинуть.",

    FILTER_ALL = "Все",
    FILTER_PICKED = "Выбор",
    FILTER_WON = "Победы",
    TAB_ROLLS = "Роллы",
    TAB_STATS = "Статистика",
    GROUP_DAYS = "Дни",
    GROUP_PLACES = "Места",
    TODAY = "Сегодня",
    YESTERDAY = "Вчера",
    WEEKDAYS = "вс|пн|вт|ср|чт|пт|сб",
    DATE_FORMAT_YEAR = "%d.%m.%Y",
    FORMS_ITEMS = "вещь|вещи|вещей",
    FORMS_VISITS = "заход|захода|заходов",
    SUMMARY_WON = "выиграно %d",
    SCOPE_ALL = "Все роллы",
    STATS_PICKS = "Ваш выбор",
    STATS_COL_TIMES = "Раз",
    STATS_COL_WON = "Побед",
    STATS_COL_RATE = "% побед",
    STATS_PICK_NONE = "Без выбора",
    STATS_NO_PICKS = "Вы не участвовали в этих роллах.",
    STATS_PLAYERS = "Игроки",
    STATS_EMPTY = "Здесь пока нет роллов.",
    SEARCH = "Поиск",
    HISTORY_TITLE = "История роллов",
    DETAIL_EMPTY = "Выберите ролл, чтобы увидеть, кто что выбрал и кто выиграл.",
    RECENT_TITLE = "Роллы",
    RECENT_TITLE_PREVIEW = "Роллы (превью)",
    RECENT_EMPTY = "Роллов пока нет.",
    RECENT_HINT = "ЛКМ: история роллов\nПКМ: настройки\nПеретащите, чтобы передвинуть",
    EMPTY = "Роллов пока нет. Вещи появятся здесь, когда группа начнёт роллить добычу.",
    EMPTY_FILTER = "Под этот фильтр ничего не подходит.",
    SAMPLE_NOTE = "Превью: примеры роллов, ничего не сохраняется.",
    UNKNOWN_ZONE = "Неизвестное место",
    TIME_FORMAT = "%H:%M",
    DATE_FORMAT = "%d.%m",
    ROW_YOU = "Вы",
    ROW_ENDED = "Без результата",
    ROW_WAITING = "думают: %d",
    ROW_NO_ANSWER = "без выбора: %d",
    ROW_NO_CHOICES = "Пока никто не выбрал",

    STATUS_ROLLING = "Идёт ролл, выбрали %d из %d",
    STATUS_WON = "Победитель: %s, %s",
    STATUS_WON_PLAIN = "Победитель: %s",
    STATUS_ALL_PASSED = "Все отказались",
    STATUS_ENDED = "Закончился, игра не прислала результат",
    MARK_TIE = "переброс",
    MARK_PROTECTED = "копия уже есть",

    YOU = "Вы",
    SAMPLE_ZONE_PARTY = "Пик Черной горы",
    SAMPLE_ZONE_RAID = "Огненные Недра",
    SAMPLE_ZONE_WORLD = "Тернистая долина",

    FLOAT_ENABLED = "Показывать всплывающий текст",
    SECTION_FLOAT_WHAT = "Что показывать",
    FLOAT_CHOICES = "Кто что выбрал",
    FLOAT_CHOICES_DESC = "Need, Greed или Pass с именем игрока в момент нажатия. Выключено: только победитель.",
    FLOAT_WINNER = "Победитель",
    FLOAT_WINNER_DESC = "Крупная золотая строка: кто забрал вещь и с чем, например Need 87.",
    FLOAT_QUALITY = "Вещи этого качества и выше",
    QUALITY_2 = "Необычные",
    QUALITY_3 = "Редкие",
    QUALITY_4 = "Эпические",
    SECTION_LOOK = "Вид",
    FLOAT_SIZE = "Размер текста",
    FLOAT_TIME = "Время на экране",
    SECONDS_FORMAT = "%d с",
    RECENTER_SPOT = "Вернуть текст на место",

    SECTION_WINDOW = "Окно роллов",
    WINDOW_MODE = "Показывать окно",
    WINDOW_MODE_always = "Всегда",
    WINDOW_MODE_group = "В группе",
    WINDOW_MODE_manual = "По команде",
    WINDOW_MODE_EXPLAIN = "«Всегда» и «В группе» возвращают окно с каждым новым роллом. «По команде»: окно открывает только /wroll window.",
    WINDOW_ROWS = "Роллов в окне",
    LOCKED = "Закрепить окно",
    WINDOW_OPACITY = "Непрозрачность фона",
    RECENTER_WINDOW = "Вернуть окно на место",
    SECTION_HISTORY = "История роллов",
    OPEN_HISTORY = "Открыть историю роллов",
    HISTORY_EXPLAIN = "История хранится отдельно для каждого персонажа, последние 2000 вещей.",
    CLEAR_HISTORY = "Очистить историю",
    CLEAR_HISTORY_CONFIRM = "Нажмите ещё раз, чтобы очистить историю персонажа",

    SECTION_BEHAVIOR = "Поведение",
    MINIMAP_BUTTON = "Кнопка у миникарты",
    MINIMAP_LEFT_CLICK = "ЛКМ: история роллов",
    MINIMAP_RIGHT_CLICK = "ПКМ: настройки",
    MINIMAP_DRAG = "Перетащите, чтобы передвинуть",
    LANGUAGE = "Язык",
    LANGUAGE_auto = "Как в игре",
    LANGUAGE_enUS = "English",
    LANGUAGE_ruRU = "Русский",
    RESET = "Сбросить все настройки",
    RESET_CONFIRM = "Нажмите ещё раз, чтобы сбросить всё",

    SETTINGS_DESC = "Показывает, кто выбрал Need, Greed или Pass, сколько выбросил и кто выиграл, и хранит все роллы в окне истории.",
    SETTINGS_OPEN = "Открыть настройки",

    ABOUT_AUTHOR = "Автор",
    ABOUT_SHAPESHIFT = "Нажмите, чтобы сменить облик",
    ABOUT_WEBSITE = "Сайт",
    ABOUT_COPY = "Копировать",
    ABOUT_COPY_HINT = "Нажмите Ctrl+C",
    ABOUT_COMMAND = "Команды в чате",
    ABOUT_COMMAND_HISTORY = "Открывает или закрывает историю роллов",
    ABOUT_COMMAND_WINDOW = "Показывает или прячет окно роллов",
    ABOUT_COMMAND_OPTIONS = "Открывает это окно",
    ABOUT_COMMAND_TEST = "Включает или выключает превью",
    ABOUT_FONT_CREDIT = "Шрифт Fira Sans, лицензия SIL Open Font License 1.1.",
}

ns.LANGUAGES = { "auto", "enUS", "ruRU" }

local PLURAL_RULES = {
    enUS = function(count) return count == 1 and 1 or 2 end,
    ruRU = function(count)
        local lastDigit, lastTwo = count % 10, count % 100
        if lastDigit == 1 and lastTwo ~= 11 then return 1 end
        if lastDigit >= 2 and lastDigit <= 4 and (lastTwo < 12 or lastTwo > 14) then return 2 end
        return 3
    end,
}
local pluralRule = PLURAL_RULES.enUS
local splitForms = {}

local function Forms(text)
    local forms = splitForms[text]
    if not forms then
        forms = { strsplit("|", text) }
        splitForms[text] = forms
    end
    return forms
end

function ns.Plural(count, key)
    local forms = Forms(L[key])
    return count .. " " .. (forms[pluralRule(count)] or forms[#forms])
end

function ns.ListOf(key)
    return Forms(L[key])
end

local function Resolve(choice)
    if choice and STRINGS[choice] then return choice end
    local gameLocale = GetLocale()
    return STRINGS[gameLocale] and gameLocale or "enUS"
end

function ns.ApplyLanguage(choice)
    local code = Resolve(choice)
    pluralRule = PLURAL_RULES[code] or PLURAL_RULES.enUS
    wipe(L)
    for key, text in pairs(STRINGS.enUS) do
        L[key] = text
    end
    if code ~= "enUS" then
        for key, text in pairs(STRINGS[code]) do
            L[key] = text
        end
    end
    ns.Fire("LOCALE_CHANGED")
end

ns.ApplyLanguage("auto")

ns.Listen("DB_READY", function()
    ns.ApplyLanguage(ns.db.locale)
end)

ns.Listen("SETTING_CHANGED", function(key)
    if key == "locale" or key == nil then
        ns.ApplyLanguage(ns.db.locale)
    end
end)
