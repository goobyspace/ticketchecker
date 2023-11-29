local _, core = ...;

local function findKeyword(message)
    local filterText = string.lower(message);
    for _, keyword in ipairs(TicketCheckerVariableArray.keywords) do
        local foundKeyword = string.find(filterText, string.lower(keyword));
        if foundKeyword ~= nil then return true end
    end
    return false;
end

local function handleEvents(_, event, ...)
    if not TicketCheckerVariableArray["enabled"] or not C_PartyInfo.CanInvite() then return end

    if event == "CHAT_MSG_BN_WHISPER" then
        local msg, _, _, _, _, _, _, _, _, _, _, _, id = ...;
        if hasanysecretvalues(msg, id) then return end;
        local foundKeyword = findKeyword(msg);
        if foundKeyword then
            -- technically if theyre online on multiple battle net accounts we should do a check but like idk how to choose which one to pick so just do the first
            local friendAccount = C_BattleNet.GetAccountInfoByID(id);
            if not friendAccount then return end;
            local gameAccount = friendAccount.gameAccountInfo;
            if not gameAccount or not gameAccount.characterName then return end;
            local name = gameAccount.characterName .. "-" .. gameAccount.realmName;
            C_PartyInfo.InviteUnit(name);
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local msg, playerName = ...;
        if hasanysecretvalues(msg, playerName) then return end;
        local foundKeyword = findKeyword(msg);
        if foundKeyword then
            C_PartyInfo.InviteUnit(playerName);
        end
    elseif event == "GROUP_INVITE_CONFIRMATION" then
        local guid = GetNextPendingInviteConfirmation();
        if hasanysecretvalues(guid) then return end;
        RespondToInviteConfirmation(guid, true);
        StaticPopup_Hide("GROUP_INVITE_CONFIRMATION");
    end
end

function core:InitializeEvents()
    local events = CreateFrame("Frame", "TicketChecker");
    events:RegisterEvent("CHAT_MSG_BN_WHISPER");
    events:RegisterEvent("CHAT_MSG_WHISPER");
    events:RegisterEvent("GROUP_INVITE_CONFIRMATION");
    events:SetScript("OnEvent", handleEvents);
end
