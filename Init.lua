local _, core = ...

core.commands = {
    ["vars"] = function()
        print(DevTools_Dump(TicketCheckerVariableArray));
    end,
    ["toggle"] = function()
        TicketCheckerVariableArray["enabled"] = not TicketCheckerVariableArray["enabled"];
        print("Ticket Checker", TicketCheckerVariableArray["enabled"] and "enabled" or "disabled");
    end
}
local function slashCommandHandler(str)
    if (#str == 0) then
        core.commands.toggle()
    end
    -- turn arguments after / command into table and then check if they match a function and what the other arguments are, if they dont match a function do the default
    local args = {};
    for _, arg in ipairs({ string.split(' ', str) }) do
        if (#arg > 0) then
            table.insert(args, arg);
        end
    end

    local path = core.commands; -- required for updating found table.

    for id, arg in ipairs(args) do
        if (#arg > 0) then -- if string length is greater than 0.
            arg = arg:lower();
            if (path[arg]) then
                if (type(path[arg]) == "function") then
                    -- all remaining args passed to our function!
                    path[arg](select(id + 1, unpack(args)));
                    return;
                elseif (type(path[arg]) == "table") then
                    path = path[arg]; -- another sub-table found!
                end
            else
                -- does not exist!
                core.commands.toggle();
                return;
            end
        end
    end
end

local function varChecker()
    if TicketCheckerVariableArray == nil then
        TicketCheckerVariableArray = {
            enabled = true,
            convert = true,
            keywords = {
                "invite"
            }
        };
    end
end

local function debugMode(enabled)
    if enabled == true then
        SLASH_RELOADUI1 = "/rl"
        SlashCmdList.RELOADUI = ReloadUI

        for i = 1, NUM_CHAT_WINDOWS do
            _G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
        end
    end
end

function core:InitEventHandler(_, name)
    if name ~= "TicketChecker" then return end
    varChecker()

    SLASH_TicketShort1 = "/TC"
    SlashCmdList.TicketShort = slashCommandHandler
    SLASH_TickerChecker1 = "/TicketChecker"
    SlashCmdList.TicketChecker = slashCommandHandler

    core:InitializeSettings();
    core:InitializeMinimap();
    core:InitializeEvents();
    debugMode(true);
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", core.InitEventHandler)
