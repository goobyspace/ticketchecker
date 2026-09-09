local _, core = ...;

local KEYWORD_ROW_HEIGHT = 24;
local ROW_SPACING = 8;

local function refreshMinimap()
    if TicketCheckerVariableArray.minimap.show then
        core.MinimapIcon:Show("TicketChecker")
    else
        core.MinimapIcon:Hide("TicketChecker")
    end
end

local function createCheckbox(parent, labelText, tooltip, getValue, setValue)
    local row = CreateFrame("Button", nil, parent);
    row:SetHeight(26);
    row:SetPoint("RIGHT", parent, "RIGHT", -32, 0);

    local highlight = row:CreateTexture(nil, "BACKGROUND");
    highlight:SetAllPoints(row);
    highlight:SetColorTexture(1, 1, 1, 0.2);
    highlight:Hide();

    -- visual only; the row itself owns the click/hover handling so the whole row is clickable
    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate");
    checkbox:SetSize(26, 26);
    checkbox:SetPoint("LEFT", row, "LEFT", 0, 0);
    checkbox:EnableMouse(false);
    checkbox:SetChecked(getValue());

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0);
    label:SetJustifyH("LEFT");
    label:SetText(labelText);

    row:SetScript("OnEnter", function(self)
        highlight:Show();
        if tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText(tooltip, nil, nil, nil, nil, true);
            GameTooltip:Show();
        end
    end);
    row:SetScript("OnLeave", function()
        highlight:Hide();
        GameTooltip:Hide();
    end);

    row:SetScript("OnClick", function()
        local newValue = not getValue();
        setValue(newValue);
        checkbox:SetChecked(newValue);
        PlaySound(newValue and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    end);

    return row;
end

local function refreshKeywordList()
    local frame = core.KeywordsFrame;
    if not frame then return end

    frame.rowPool:ReleaseAll();

    local keywords = TicketCheckerVariableArray.keywords;
    for index, keyword in ipairs(keywords) do
        local row = frame.rowPool:Acquire();
        row:SetParent(frame.ScrollChild);
        row:SetPoint("TOPLEFT", frame.ScrollChild, "TOPLEFT", 0, -(index - 1) * KEYWORD_ROW_HEIGHT);
        row:SetPoint("RIGHT", frame.ScrollChild, "RIGHT", 0, 0);
        row.Label:SetText(keyword);
        row.RemoveButton:SetScript("OnClick", function()
            table.remove(TicketCheckerVariableArray.keywords, index);
            refreshKeywordList();
        end);
        row:Show();
    end

    frame.ScrollChild:SetHeight(math.max(#keywords * KEYWORD_ROW_HEIGHT, 1));
end

local function addKeyword(text)
    text = text and text:match("^%s*(.-)%s*$") or "";
    if text == "" then return end

    for _, keyword in ipairs(TicketCheckerVariableArray.keywords) do
        if keyword:lower() == text:lower() then return end
    end

    table.insert(TicketCheckerVariableArray.keywords, text);
    refreshKeywordList();
end

local function initKeywordRow(row)
    row:SetHeight(KEYWORD_ROW_HEIGHT);
    row:EnableMouse(true);

    row.Highlight = row:CreateTexture(nil, "BACKGROUND");
    row.Highlight:SetAllPoints(row);
    row.Highlight:SetColorTexture(1, 1, 1, 0.2);
    row.Highlight:Hide();

    row:SetScript("OnEnter", function(self)
        self.Highlight:Show();
    end);
    row:SetScript("OnLeave", function(self)
        self.Highlight:Hide();
    end);

    row.RemoveButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate");
    row.RemoveButton:SetSize(70, 20);
    row.RemoveButton:SetPoint("RIGHT", row, "RIGHT", 0, 0);
    row.RemoveButton:SetText("Remove");
    -- moving onto a child frame swaps which frame is "topmost", firing the row's OnLeave, so mirror the highlight here too
    row.RemoveButton:HookScript("OnEnter", function()
        row.Highlight:Show();
    end);
    row.RemoveButton:HookScript("OnLeave", function()
        row.Highlight:Hide();
    end);

    row.Label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    row.Label:SetPoint("LEFT", row, "LEFT", 4, 0);
    row.Label:SetPoint("RIGHT", row.RemoveButton, "LEFT", -8, 0);
    row.Label:SetJustifyH("LEFT");
end

function core:InitializeSettings()
    local panel = CreateFrame("Frame", "TicketCheckerSettingsPanel", UIParent);

    local generalHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    generalHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16);
    generalHeader:SetText("General");

    local minimapCheckbox = createCheckbox(panel, "Show Minimap Icon", nil,
        function() return TicketCheckerVariableArray.minimap.show end,
        function(value)
            TicketCheckerVariableArray.minimap.show = value;
            refreshMinimap();
        end);
    minimapCheckbox:SetPoint("TOPLEFT", generalHeader, "BOTTOMLEFT", 0, -12);

    local friendsOnlyCheckbox = createCheckbox(panel, "Friend/Guild invites only",
        "When enabled, only whispers from Battle.net friends, in-game friends, or guild members will be invited.",
        function() return TicketCheckerVariableArray.friendsOnly end,
        function(value) TicketCheckerVariableArray.friendsOnly = value end);
    friendsOnlyCheckbox:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -ROW_SPACING);

    local autoAcceptCheckbox = createCheckbox(panel, "Auto Accept Requests To Join",
        "Automatically accept 'Request to Join'/'Suggest Invite' confirmations.",
        function() return TicketCheckerVariableArray.autoAcceptRequests end,
        function(value) TicketCheckerVariableArray.autoAcceptRequests = value end);
    autoAcceptCheckbox:SetPoint("TOPLEFT", friendsOnlyCheckbox, "BOTTOMLEFT", 0, -ROW_SPACING);

    local keywordsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    keywordsHeader:SetPoint("TOPLEFT", autoAcceptCheckbox, "BOTTOMLEFT", 0, -20);
    keywordsHeader:SetText("Keywords");

    local exactMatchCheckbox = createCheckbox(panel, "Require Exact Keyword Match",
        "When enabled, a whisper must contain only the keyword and no other text",
        function() return TicketCheckerVariableArray.exactMatch end,
        function(value) TicketCheckerVariableArray.exactMatch = value end);
    exactMatchCheckbox:SetPoint("TOPLEFT", keywordsHeader, "BOTTOMLEFT", 0, -12);

    local editBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate");
    editBox:SetSize(180, 20);
    editBox:SetPoint("TOPLEFT", exactMatchCheckbox, "BOTTOMLEFT", 6, -20);
    editBox:SetAutoFocus(false);

    local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
    addButton:SetSize(70, 22);
    addButton:SetPoint("LEFT", editBox, "RIGHT", 8, 0);
    addButton:SetText("Add");
    addButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText("Keywords are always case-insensitive", nil, nil, nil, nil, true);
        GameTooltip:Show();
    end);
    addButton:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);

    local function onAdd()
        addKeyword(editBox:GetText());
        editBox:SetText("");
        editBox:SetFocus();
    end
    addButton:SetScript("OnClick", onAdd);
    editBox:SetScript("OnEnterPressed", onAdd);

    local keywordsFrame = CreateFrame("Frame", nil, panel);
    keywordsFrame:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", -6, -12);
    keywordsFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 16);

    keywordsFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, keywordsFrame, "UIPanelScrollFrameTemplate");
    keywordsFrame.ScrollFrame:SetAllPoints(keywordsFrame);

    keywordsFrame.ScrollChild = CreateFrame("Frame", nil, keywordsFrame.ScrollFrame);
    keywordsFrame.ScrollChild:SetSize(1, 1);
    keywordsFrame.ScrollFrame:SetScrollChild(keywordsFrame.ScrollChild);

    -- ScrollChild needs a real width or rows anchored to its edges collapse to zero size
    keywordsFrame.ScrollFrame:SetScript("OnSizeChanged", function(_, width)
        keywordsFrame.ScrollChild:SetWidth(width);
    end);

    keywordsFrame.rowPool = CreateFramePool("Frame", keywordsFrame.ScrollChild, nil, nil, false, initKeywordRow);

    core.KeywordsFrame = keywordsFrame;
    refreshKeywordList();

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Ticket Checker");
    Settings.RegisterAddOnCategory(category);

    -- panel isn't sized/anchored into the settings canvas until shown, so rebuild the list then too
    panel.OnRefresh = refreshKeywordList;

    function core:OpenSettings()
        Settings.OpenToCategory(category:GetID());
    end
end
