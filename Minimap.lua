local _, core = ...

local mousedOver = false;
core.Minimap = {};

local function setGameTooltipText()
    local color = TicketCheckerVariableArray["enabled"] and "|cff40c040" or "|c3fff2114";
    local status = TicketCheckerVariableArray["enabled"] and "Enabled.|r" or "Disabled.|r";
    local text = "|cffffd100Ticket Checker!|r\nStatus: " ..
        color ..
        status ..
        "\n\n|cff2c71f2Left-Click|r to toggle auto accept status.\n|cff2c71f2Right-Click|r to open settings."
    GameTooltip:SetText(text, 1, 1, 1)
end

local TicketCheckerLDB = LibStub("LibDataBroker-1.1"):NewDataObject("TicketChecker", {
    type = "data source",
    text = "Ticket Checker",
    icon = "Interface\\ICONS\\INV_Misc_Ticket_Tarot_Madness",
    OnClick = function(_, e)
        if (e == "RightButton") then
            core:OpenSettings()
        else
            TicketCheckerVariableArray["enabled"] = not TicketCheckerVariableArray["enabled"];
            if mousedOver then setGameTooltipText() end
        end
    end,
    OnEnter = function()
        mousedOver = true;
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        setGameTooltipText();
        GameTooltip:Show();
    end,
    OnLeave = function()
        mousedOver = false;
        GameTooltip:Hide();
    end
})

function core:InitializeMinimap()
    core.MinimapIcon = LibStub("LibDBIcon-1.0")
    core.MinimapIcon:Register("TicketChecker", TicketCheckerLDB, TicketCheckerVariableArray.minimap)

    if not TicketCheckerVariableArray.minimap.show then
        core.MinimapIcon:Hide("TicketChecker")
    else
        core.MinimapIcon:Show("TicketChecker")
    end
end
