local _, core = ...;

local function findKeyword(message)
    local filterText = string.lower(message);
    local exactMatch = TicketCheckerVariableArray["exactMatch"];
    for _, keyword in ipairs(TicketCheckerVariableArray.keywords) do
        local lowerKeyword = string.lower(keyword);
        if exactMatch then
            for word in filterText:gmatch("%a+") do
                if word == lowerKeyword then return true end
            end
        else
            -- plain-text search avoids treating keyword as a Lua pattern
            if string.find(filterText, lowerKeyword, 1, true) ~= nil then return true end
        end
    end
    return false;
end

local function isBattleNetFriendByName(playerName)
    if not playerName or not (C_BattleNet and C_BattleNet.GetNumFriends) then return false end

    local normalizedName = string.lower(playerName)
    local numFriends = C_BattleNet.GetNumFriends();
    for i = 1, numFriends do
        local friendInfo = C_BattleNet.GetFriendAccountInfo(i);
        if friendInfo then
            local gameAccount = friendInfo.gameAccountInfo;
            if gameAccount then
                local friendName = string.lower(gameAccount.characterName or "")
                local friendRealm = string.lower(gameAccount.realmName or "")
                if normalizedName == friendName then return true end
                if normalizedName == (friendName .. "-" .. friendRealm) then return true end
            end
        end
    end
    return false;
end

local function isAllowedSender(guid, playerName)
    if not TicketCheckerVariableArray["friendsOnly"] then return true end
    if guid and (C_FriendList.IsFriend(guid) or IsGuildMember(guid)) then return true end
    if playerName and isBattleNetFriendByName(playerName) then return true end
    return false;
end

local function handleEvents(_, event, ...)
    if not TicketCheckerVariableArray["enabled"] or not C_PartyInfo.CanInvite() then return end

    if event == "CHAT_MSG_BN_WHISPER" then
        local msg, _, _, _, _, _, _, _, _, _, _, _, id = ...;
        if hasanysecretvalues(msg, id) then return end;
        local foundKeyword = findKeyword(msg);
        if foundKeyword then
            -- BNet whispers only come from Battle.net friends, so friendsOnly is already satisfied
            local friendAccount = C_BattleNet.GetAccountInfoByID(id);
            if not friendAccount then return end;
            local gameAccount = friendAccount.gameAccountInfo;
            if not gameAccount or not gameAccount.characterName then return end;
            local name = gameAccount.characterName .. "-" .. gameAccount.realmName;
            C_PartyInfo.InviteUnit(name);
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local msg, playerName, _, _, _, _, _, _, _, _, _, guid = ...;
        if hasanysecretvalues(msg, playerName) then return end;
        if not isAllowedSender(guid, playerName) then return end;
        local foundKeyword = findKeyword(msg);
        if foundKeyword then
            C_PartyInfo.InviteUnit(playerName);
        end
    elseif event == "GROUP_INVITE_CONFIRMATION" then
        if not TicketCheckerVariableArray["autoAcceptRequests"] then return end;
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
