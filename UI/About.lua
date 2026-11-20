local _, ns = ...

local UI = ns.UI
local L = ns.L
local C = UI.COLORS
local T = UI.TEXT
local W = ns.Widgets

local About = {}
ns.About = About

local AUTHOR = "Jagerente"
local AUTHOR_CLASS = "DRUID"
local WEBSITE = "https://jagerente.dev"
local DRUID_FORMS = { 5487, 768, 783, 1066, 24858 }
local COMMANDS = {
    { "/wroll", "ABOUT_COMMAND_HISTORY" },
    { "/wroll window", "ABOUT_COMMAND_WINDOW" },
    { "/wroll options", "ABOUT_COMMAND_OPTIONS" },
    { "/wroll test", "ABOUT_COMMAND_TEST" },
}

local SECTION_GAP = 10
local PORTRAIT_SIZE = 36
local PORTRAIT_TEXT_GAP = 12
local SHIFT_FADE_TIME = 0.1
local SPELL_ICON_CROP = 0.08
local FIELD_HEIGHT, FIELD_LABEL_HEIGHT, FIELD_INSET = 22, 18, 8
local COMMAND_ROW_HEIGHT = 22
local COMMAND_COLUMN = 112

local function CreatePortrait(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    local art = W.Circle(button, "ARTWORK")
    art:SetAllPoints()
    button.form = 0

    local function Paint()
        local spell = DRUID_FORMS[button.form]
        if spell then
            art:SetTexture(C_Spell.GetSpellTexture(spell))
            art:SetTexCoord(SPELL_ICON_CROP, 1 - SPELL_ICON_CROP, SPELL_ICON_CROP, 1 - SPELL_ICON_CROP)
        else
            art:SetTexCoord(0, 1, 0, 1)
            UI.SetClassIcon(art, AUTHOR_CLASS)
        end
    end

    local function ShowTooltip(self)
        local spell = DRUID_FORMS[self.form]
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if spell then
            GameTooltip:SetSpellByID(spell)
        else
            GameTooltip:SetText(UI.ClassName(AUTHOR_CLASS), UI.ClassColor(AUTHOR_CLASS))
        end
        GameTooltip:AddLine(L.ABOUT_SHAPESHIFT, unpack(C.muted))
        GameTooltip:Show()
    end

    local fade = { tweenValue = 1 }
    local function ApplyFade(_, value) art:SetAlpha(value) end
    button:SetScript("OnClick", function(self)
        self.form = (self.form + 1) % (#DRUID_FORMS + 1)
        UI.Tween(fade, 0, SHIFT_FADE_TIME, ApplyFade, function()
            Paint()
            UI.Tween(fade, 1, SHIFT_FADE_TIME, ApplyFade)
            if GameTooltip:IsOwned(self) then ShowTooltip(self) end
        end)
    end)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", W.HideHint)
    Paint()
    return button
end

local function BuildAuthor(content, width)
    local frame = CreateFrame("Frame", nil, content)
    frame:SetSize(width, PORTRAIT_SIZE)
    local portrait = CreatePortrait(frame)
    portrait:SetPoint("LEFT")

    local name = UI.BoldText(frame, T.title, C.text)
    name:SetPoint("LEFT", portrait, "RIGHT", PORTRAIT_TEXT_GAP, 0)
    name:SetText(AUTHOR)
    name:SetTextColor(UI.ClassColor(AUTHOR_CLASS))
    return frame
end

local function BuildWebsite(content, width)
    local frame = CreateFrame("Frame", nil, content)
    frame:SetSize(width, FIELD_LABEL_HEIGHT + FIELD_HEIGHT)
    local label = UI.Text(frame, T.label, C.muted)
    label:SetPoint("TOPLEFT", 0, -2)
    W.Bind(label, "ABOUT_WEBSITE")

    local box = CreateFrame("EditBox", nil, frame)
    local copy = W.Button(frame, "ABOUT_COPY", function()
        box:SetFocus()
        box:HighlightText()
    end, "primary")
    copy:SetPoint("BOTTOMRIGHT")

    local function ShowCopyHint(armed)
        copy.text:SetText(armed and L.ABOUT_COPY_HINT or L.ABOUT_COPY)
        copy:Fit()
    end

    box:SetPoint("BOTTOMLEFT")
    box:SetPoint("RIGHT", copy, "LEFT", -2, 0)
    box:SetHeight(FIELD_HEIGHT)
    box:SetAutoFocus(false)
    box:SetTextInsets(FIELD_INSET, FIELD_INSET, 0, 0)
    box:SetFontObject(UI.Font(T.body))
    box:SetTextColor(unpack(C.text))
    UI.Fill(box, C.control)
    box:SetText(WEBSITE)
    box:SetCursorPosition(0)
    box:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
        ShowCopyHint(true)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        self:SetCursorPosition(0)
        ShowCopyHint(false)
    end)
    box:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        self:SetText(WEBSITE)
        self:HighlightText()
    end)
    box:SetScript("OnEnterPressed", box.ClearFocus)
    box:SetScript("OnEscapePressed", box.ClearFocus)
    return frame
end

local function BuildCommand(content, width, command, descKey)
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(width, COMMAND_ROW_HEIGHT)
    local name = UI.BoldText(row, T.body, C.text)
    name:SetPoint("LEFT")
    name:SetText(command)
    local desc = UI.Text(row, T.body, C.muted)
    desc:SetPoint("LEFT", COMMAND_COLUMN, 0)
    desc:SetPoint("RIGHT")
    desc:SetJustifyH("LEFT")
    W.Bind(desc, descKey)
    return row
end

function About.Build(page, width)
    local content, stack = page.content, page.stack
    stack:Add(W.Heading(content, width, "ABOUT_AUTHOR"))
    stack:Add(BuildAuthor(content, width), 4)
    stack:Add(BuildWebsite(content, width), 12)

    stack:Add(W.Heading(content, width, "ABOUT_COMMAND"), SECTION_GAP)
    for _, entry in ipairs(COMMANDS) do
        stack:Add(BuildCommand(content, width, entry[1], entry[2]))
    end

    stack:Add(W.Paragraph(content, width, "ABOUT_FONT_CREDIT"), 16)
end
