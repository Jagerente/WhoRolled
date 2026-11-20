local _, ns = ...

local ACTIONS = {
    [""] = function() ns.HistoryWindow.Toggle() end,
    window = function() ns.RecentWindow.Toggle() end,
    options = function() ns.Options.Toggle() end,
    config = function() ns.Options.Toggle() end,
    test = function() ns.TestMode.Toggle() end,
}

SLASH_WHOROLLED1 = "/wroll"
SLASH_WHOROLLED2 = "/whorolled"
SlashCmdList.WHOROLLED = function(input)
    local command = strtrim(input or ""):lower()
    local action = ACTIONS[command] or ACTIONS[""]
    action()
end

function WhoRolled_OnAddonCompartmentClick()
    ns.HistoryWindow.Toggle()
end
