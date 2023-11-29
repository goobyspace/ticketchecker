local _, core = ...;

local function setMinimap(setting, value)
    if value then
        core.MinimapIcon:Show("TicketChecker")
    else
        core.MinimapIcon:Hide("TicketChecker")
    end
end

function core:InitializeSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory("Ticket Checker")

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("General"));

    do
        local name = "Show Minimap Icon"
        local variable = "ticketminimap"
        local variableKey = "show"
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, TicketCheckerVariableArray
            .minimap,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(setMinimap)

        Settings.CreateCheckbox(category, setting, nil)
    end

    Settings.RegisterAddOnCategory(category)

    function core:OpenSettings()
        Settings.OpenToCategory(category.ID)
    end
end
