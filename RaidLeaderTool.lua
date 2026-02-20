local AceGUI			= LibStub("AceGUI-3.0")
local AceConfig			= LibStub("AceConfig-3.0")
local AceConfigDialog	= LibStub("AceConfigDialog-3.0")
local AceDB				= LibStub("AceDB-3.0")
local AceDBOptions		= LibStub("AceDBOptions-3.0")
local LibDualSpec		= LibStub("LibDualSpec-1.0")
local L					= LibStub("AceLocale-3.0"):GetLocale("RaidLeaderToolLocale")
local CallbackHandler	= LibStub("CallbackHandler-1.0")
local LSM				= LibStub("LibSharedMedia-3.0")
local LDB				= LibStub("LibDataBroker-1.1")
local LDBIcon			= LibStub("LibDBIcon-1.0")

local ADDON_NAME = "RaidLeaderTool"
local ADDON_DB_NAME = "RaidLeaderToolDB"
local CURRENT_VERSION		= "1.0.8"

local Default_PROFILE = {
    global = {
        optGlobalEnable = true,
        optGlobalBackgroundEnable = true,

        optLfgAlert = true,
        optLfgAlertSound = "CUSTOM_PHONE",

        optRecruitmentMemo = true,
        optRecruitmentMemoText = "",

        optGroupSynergy = true,
        optGroupSynergyOverlay = true,

        optGroupExpireAlert = true,
        optGroupExpireAlertSound = "CUSTOM_PHONE",

        optGroupList = true,

        groupSynergyPos = {
            point = "CENTER",
            x = 0,
            y = 0,
        },
    },
}

local SOUND_LIST = {
    ["CUSTOM_PHONE"] = [[Interface\AddOns\RaidLeaderTool\Assets\Sounds\phone.ogg]],
    ["READY_CHECK"] = 8960, -- 시스템 전투 준비 소리
    ["RAID_WARNING"] = 8959, -- 시스템 공대 경보
}

local rlt = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

local configOptions = {
    name = L["optName"],
    type = "group",
    args = {
        globalEnable = {
            type = "toggle",
            name = L["optGlobalEnable"],
            desc = L["optGlobalEnableTooltipDescription"],
            get = function() return rlt.db.global.optGlobalEnable end,
            set = function(_, val) 
                rlt.db.global.optGlobalEnable = val 
                if not val then
                    if rlt.SynergyFrame then rlt.SynergyFrame:Hide() end
                    -- 필요하다면 다른 UI 요소들도 여기서 Hide() 처리
                else
                    if IsInGroup() then rlt:GROUP_JOINED() end
                end
            end,
            order = 0,
            width = "normal",
        },
        globalSoundBackgroundEnable = {
            type = "toggle",
            name = L["optGlobalSoundBackgroundEnable"],
            desc = L["optGlobalSoundBackgroundEnableTooltipDiscription"],
            get = function() 
                return rlt.db.global.optGlobalBackgroundEnable
            end,
            set = function(_, val) 
                rlt.db.global.optGlobalBackgroundEnable = val
            end,
            order = 1,
            width = "normal",
        },
        header = {
            type = "header",
            name = "Options",
            order = 2,
        },
        description = {
            type = "description",
            name = " ",
            order = 3,
        },
        lfgAlertSection = {
            type = "group",
            name = L["optLfgAlertName"],
            inline = true,
            disabled = function() return not rlt.db.global.optGlobalEnable end,
            order = 4,
            args = {
                description = {
                    type = "description",
                    name = L["optLfgAlertDiscription"],
                    order = 0,
                },
                spacer = {
                    type = "description",
                    name = "",
                    order = 1,
                },
                lfgAlert = {
                    type = "toggle",
                    name = L["optEnableToggleName"],
                    get = function() return rlt.db.global.optLfgAlert end,
                    set = function(_, val) rlt.db.global.optLfgAlert = val end,
                    order = 2,
                },
                lfgAlertSound = {
                    type = "select",
                    name = L["optSelectSoundName"],
                    values = {
                        ["CUSTOM_PHONE"] = L["assetPhoneSound"],
                        ["READY_CHECK"] = L["assetReadyCheckSound"],
                        ["RAID_WARNING"] = L["assetRaidWarningSound"],
                    },
                    get = function() return rlt.db.global.optLfgAlertSound end,
                    set = function(_, val) 
                        rlt.db.global.optLfgAlertSound = val 
                        rlt:PlayAlert(rlt.db.global.optLfgAlertSound)
                    end,
                    order = 3,
                },
            },
        },
        recruitmentMemoSection = {
            type = "group",
            name = L["optRecruitmentMemoName"],
            inline = true,
            disabled = function() return not rlt.db.global.optGlobalEnable end,
            order = 6,
            args = {
                description = {
                    type = "description",
                    name = L["optRecruitmentMemoDescription"],
                    order = 0,
                },
                spacer = {
                    type = "description",
                    name = "",
                    order = 1,
                },
                recruitmentMemoToogle = {
                    type = "toggle",
                    name = L["optEnableToggleName"],
                    get = function() return rlt.db.global.optRecruitmentMemo end,
                    set = function(_, val) rlt.db.global.optRecruitmentMemo = val end,
                    order = 2,
                },
                recruitmentMemo = {
                    type = "input",
                    name = L["optRecruitmentMemoEditBoxName"],
                    multiline = 10,
                    width = "full",
                    order = 10,
                    get = function(info)
                        local btn = _G["MultiLineEditBox1Button"]
                        if btn then 
                            btn:SetWidth(100)
                            btn:SetText(L["optRecruitmentMemoSave"])
                        end
                        return rlt.db.global.optRecruitmentMemoText
                    end,
                    set = function(_, val) 
                        rlt.db.global.optRecruitmentMemoText = val
                    end,
                },
            },
        },
        groupSynergySection = {
            type = "group",
            name = L["optGroupSynergyName"],
            inline = true,
            disabled = function() return not rlt.db.global.optGlobalEnable end,
            order = 6,
            args = {
                description = {
                    type = "description",
                    name = L["optGroupSynergyDiscription"],
                    order = 0,
                },
                spacer = {
                    type = "description",
                    name = "",
                    order = 1,
                },
                groupSynergy = {
                    type = "toggle",
                    name = L["optEnableToggleName"],
                    get = function() return rlt.db.global.optGroupSynergy end,
                    set = function(_, val) 
                        rlt.db.global.optGroupSynergy = val 
                        if val and IsInGroup() then
                            if not rlt.SynergyFrame then 
                                rlt:CreateSynergyUI() 
                            end
                        end
                        rlt:UpdateSynergyVisibility()
                    end,
                    order = 2,
                },
            },
        },
        groupExpireAlertSection = {
            type = "group",
            name = L["optGroupExpireAlertName"],
            inline = true,
            disabled = function() return not rlt.db.global.optGlobalEnable end,
            order = 7,
            args = {
                description = {
                    type = "description",
                    name = L["optGroupExpireAlertDiscription"],
                    order = 0,
                },
                spacer = {
                    type = "description",
                    name = "",
                    order = 1,
                },
                groupExpireAlert = {
                    type = "toggle",
                    name = L["optEnableToggleName"],
                    get = function() return rlt.db.global.optGroupExpireAlert end,
                    set = function(_, val) rlt.db.global.optGroupExpireAlert = val end,
                    order = 2,
                },
                groupExpireAlertSound = {
                    type = "select",
                    name = L["optSelectSoundName"],
                    values = {
                        ["CUSTOM_PHONE"] = L["assetPhoneSound"],
                        ["READY_CHECK"] = L["assetReadyCheckSound"],
                        ["RAID_WARNING"] = L["assetRaidWarningSound"],
                    },
                    get = function() return rlt.db.global.optGroupExpireAlertSound end,
                    set = function(_, val) 
                        rlt.db.global.optGroupExpireAlertSound = val 
                        rlt:PlayAlert(rlt.db.global.optGroupExpireAlertSound)
                    end,
                    order = 3,
                },
            },
        },
        groupListSection = {
            type = "group",
            name = L["optGroupListName"],
            inline = true,
            disabled = function() return not rlt.db.global.optGlobalEnable end,
            order = 8,
            args = {
                description = {
                    type = "description",
                    name = L["optGroupListDiscription"],
                    order = 0,
                },
                spacer = {
                    type = "description",
                    name = "",
                    order = 1,
                },
                groupList = {
                    type = "toggle",
                    name = L["optEnableToggleName"],
                    get = function() return rlt.db.global.optGroupList end,
                    set = function(_, val) 
                        rlt.db.global.optGroupList = val 
                        rlt:UpdateLFGButtons()
                    end,
                    order = 2,
                },
            },
        },
    },
}

function rlt:OnInitialize()
    self.db = AceDB:New(ADDON_DB_NAME,Default_PROFILE)

    AceConfig:RegisterOptionsTable(ADDON_NAME, configOptions)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(ADDON_NAME, ADDON_NAME)

    self:RegisterChatCommand("rlt", "SlashCommandExecute")
    self:RegisterChatCommand("공장툴", "SlashCommandExecute")
end

function rlt:SlashCommandExecute()
    if AceConfigDialog.OpenFrames[ADDON_NAME] then AceConfigDialog:Close(ADDON_NAME) else AceConfigDialog:Open(ADDON_NAME) end
end

local function OnPostClick()
    print("|cff00ff00[rlt]|r 파티 만들기 버튼 클릭됨 -> 보임")
end

function rlt:OnEnable()
    self:Print(ADDON_NAME.."("..CURRENT_VERSION..")- /rlt or /공장툴 ")

    self:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
    self:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("GROUP_JOINED")
    self:RegisterEvent("GROUP_LEFT")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() self:UpdateSynergyVisibility() end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() self:UpdateSynergyVisibility() end)
    self:RegisterEvent("LFG_LIST_ENTRY_EXPIRED_TIMEOUT")

    if IsInGroup() then self:GROUP_JOINED() end

    LFGListFrame.CategorySelection.StartGroupButton:HookScript("OnClick", function(self)
	    --print("(CategorySelection)파티 만들기 버튼 누름")

        if rlt.db.global.optGlobalEnable and rlt.db.global.optRecruitmentMemo then
            local memo = rlt:GetOrCreateMemoFrame()
            memo:Show()
            memo.EditBox:SetCursorPosition(0)
        end
    end)

    LFGListFrame.EntryCreation.ListGroupButton:HookScript("OnClick", function(self)
	    --print("(EntryCreation)파티 등록 버튼 누름")
        if LFGRecruitmentMemoFrame then LFGRecruitmentMemoFrame:Hide() end
    end)

    LFGListFrame.EntryCreation.CancelButton:HookScript("OnClick", function(self)
	    --print("(EntryCreation)뒤로가기 버튼 누름")
        if LFGRecruitmentMemoFrame then LFGRecruitmentMemoFrame:Hide() end
    end)

    LFGListFrame.EntryCreation:HookScript("OnShow", function(self)
        if rlt.db.global.optGlobalEnable and rlt.db.global.optRecruitmentMemo then
            local memo = rlt:GetOrCreateMemoFrame()
            memo:Show()
            memo.EditBox:SetCursorPosition(0)
        else
            if LFGRecruitmentMemoFrame then LFGRecruitmentMemoFrame:Hide() end
        end
    end)

    PVEFrame:HookScript("OnHide", function(self)
        --print("PVEFrame이 닫혔습니다.")
        if LFGRecruitmentMemoFrame then LFGRecruitmentMemoFrame:Hide() end
    end)

end

---
--- 이벤트 핸들러
---

rlt.lastLfgAlertTime = 0
rlt.lastApplicantCount = 0

function rlt:LFG_LIST_APPLICANT_UPDATED()

    -- 1. 기본 권한 및 옵션 체크
    if not self.db.global.optGlobalEnable or not self.db.global.optLfgAlert then 
        return 
    end

    -- 모집 중이 아니면 숫자를 0으로 고정하고 종료
    if not C_LFGList.HasActiveEntryInfo() then
        self.lastApplicantCount = 0
        return 
    end
    
    local isLeader = UnitIsGroupLeader("player")
    local isAssistant = UnitIsGroupAssistant("player")
    if not (isLeader or isAssistant) then 
        return 
    end

    -- 2. 현재 모든 신청자 ID 리스트 가져오기
    local applicants = C_LFGList.GetApplicants()
    local activeCount = 0
    local currentTime = GetTime()

    -- 3. [핵심] 잔상을 제거하고 실제 '대기 중'인 인원만 카운트
    for _, applicantID in ipairs(applicants) do
        local info = C_LFGList.GetApplicantInfo(applicantID)
        -- 상태가 "applied"인 경우(실제 대기 중)만 유효 숫자로 인정
        -- 취소(cancelled)나 거절된 잔상은 카운트에서 제외됨
        if info and (info.pendingApplicationStatus == "applied" or info.isNew) then
            activeCount = activeCount + 1
        end
    end

    -- 4. 실제 유효 신청자가 이전보다 늘어났을 때만 알림 실행
    if activeCount > (self.lastApplicantCount or 0) then
        
        -- 3초 쿨타임 체크 (연속 알람 방지)
        if (currentTime - (self.lastLfgAlertTime or 0)) < 3 then
            self.lastApplicantCount = activeCount -- 숫자 동기화는 수행
            return 
        end

        self.lastLfgAlertTime = currentTime

        -- [알림 액션]
        self:ShowText(L["newLfgAlertText"], 5)
        self:PlayAlert(self.db.global.optLfgAlertSound)

        -- 파티 찾기 창이 닫혀있다면 자동으로 열기
        if not GroupFinderFrame:IsVisible() then 
            PVEFrame_ShowFrame("GroupFinderFrame")
            -- '내 파티 등록' 탭(보통 3번 버튼) 클릭
            if GroupFinderFrameGroupButton3 then 
                GroupFinderFrameGroupButton3:Click() 
            end
        end

        -- 작업표시줄 아이콘 깜빡임
        FlashClientIcon()
    end

    -- 5. 현재 실제 유효 인원수로 상태 동기화 (거절/취소 발생 시에도 정확한 숫자로 업데이트)
    self.lastApplicantCount = activeCount
end

function rlt:LFG_LIST_ACTIVE_ENTRY_UPDATE()
    -- 모집글이 사라졌다면 다음을 위해 카운트 초기화
    if not C_LFGList.HasActiveEntryInfo() then
        self.lastApplicantCount = 0
    end
end

rlt.SynergyMain = nil
rlt.SynergyFrame = nil
rlt.SynergyFrameText = nil

function rlt:GROUP_JOINED()
    if not self.db.global.optGlobalEnable then return end
    if not self.db.global.optGroupSynergy then return end

    if not self.SynergyFrame then 
        self:CreateSynergyUI() 
    end

    self:UpdateLFGButtons()

    self:UpdateSynergyVisibility()
end

function rlt:GROUP_LEFT()
    if self.SynergyFrame then self.SynergyFrame:Hide() end
end

function rlt:GROUP_ROSTER_UPDATE()
    if IsInGroup() and self.SynergyFrame and self.SynergyFrame:IsShown() then
        self:UpdateSynergyDisplay()
    end
end

function rlt:LFG_LIST_ENTRY_EXPIRED_TIMEOUT()

    if not self.db.global.optGlobalEnable then 
        return 
    end

    self:ShowText(L["newLfgExpiredTimeoutText"], 5)

    if self.db.global.optGroupExpireAlert then
        self:PlayAlert(self.db.global.optGroupExpireAlertSound)
    end

    PVEFrame_ShowFrame("GroupFinderFrame")
    LFGListFrame.CategorySelection.StartGroupButton:Click()

    FlashClientIcon()
end

---
--- 파티 시너지
---

-- 1. 데이터 계산 로직 (기본 로직 유지)
function rlt:GetSynergyData()
    local data = {
        total = 0,
        classCount = {},
        roleCount = {TANK = 0, HEALER = 0, DAMAGER = 0, NONE = 0},
        tierCount = {DREADFUL = 0, MYSTIC = 0, VENERATED = 0, ZENITH = 0},
        classicTierCount = {CONQUEROR = 0, PROTECTOR = 0, VANQUISHER = 0, DEATH = 0}
    }
    local classes = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER"}
    for _, c in ipairs(classes) do data.classCount[c] = 0 end

    local numGroup = GetNumGroupMembers()
    local isRaid = IsInRaid()
    local prefix = isRaid and "raid" or "party"
    local maxIdx = isRaid and numGroup or (numGroup > 0 and numGroup or 0)

    for i = 1, maxIdx do
        local unit = prefix..i
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            if class then
                data.total = data.total + 1
                data.classCount[class] = (data.classCount[class] or 0) + 1
                local role = UnitGroupRolesAssigned(unit)
                data.roleCount[role] = (data.roleCount[role] or 0) + 1
            end
        end
    end

    if not isRaid or numGroup == 0 then
        local _, class = UnitClass("player")
        if data.classCount[class] == 0 then
            data.total = data.total + 1
            data.classCount[class] = 1
            data.roleCount[UnitGroupRolesAssigned("player")] = (data.roleCount[UnitGroupRolesAssigned("player")] or 0) + 1
        end
    end

    local tierGroups = {
        DREADFUL = {"PRIEST", "MAGE", "WARLOCK"}, MYSTIC = {"ROGUE", "MONK", "DRUID", "DEMONHUNTER"}, 
        VENERATED = {"HUNTER", "SHAMAN", "EVOKER"}, ZENITH = {"WARRIOR", "PALADIN", "DEATHKNIGHT"}
    }
    local classicTierGroups = {
        CONQUEROR = {"PALADIN", "PRIEST", "SHAMAN"}, PROTECTOR = {"WARRIOR", "ROGUE", "MONK", "EVOKER"}, 
        VANQUISHER = {"HUNTER", "MAGE", "DRUID"}, DEATH = {"DEATHKNIGHT", "WARLOCK", "DEMONHUNTER"}
    }

    for group, list in pairs(tierGroups) do
        for _, c in ipairs(list) do data.tierCount[group] = data.tierCount[group] + (data.classCount[c] or 0) end
    end
    for group, list in pairs(classicTierGroups) do
        for _, c in ipairs(list) do data.classicTierCount[group] = data.classicTierCount[group] + (data.classCount[c] or 0) end
    end
    return data
end

function rlt:CreateSynergyUI()
    if self.SynergyFrame then return end

    -- [부모 프레임]
    local display = CreateFrame("Frame", "RLT_SynergyFrame", UIParent, "BackdropTemplate")
    local pos = self.db.global.groupSynergyPos
    display:SetSize(250, 100) 
    display:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    display:SetMovable(true)
    display:SetClampedToScreen(true)
    display:SetBackdrop({ 
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } 
    })
    display:SetBackdropColor(0, 0, 0, 0.9)
    display:SetBackdropBorderColor(1, 1, 1, self.db.global.synergyBgAlpha or 0.9)
    display:EnableMouse(true)
    display:RegisterForDrag("LeftButton")
    display:SetScript("OnDragStart", function(s) s:StartMoving() end)
    display:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        local point, _, _, x, y = s:GetPoint()
        self.db.global.groupSynergyPos = { point = point, x = x, y = y }
    end)
    self.SynergyFrame = display

    local contentWidth = display:GetWidth() - 20

    -- [1. TitlebarContainer] (높이 고정: 30)
    local TitlebarContainer = CreateFrame("Frame", nil, display, "BackdropTemplate")
    TitlebarContainer:SetSize(contentWidth, 30)
    TitlebarContainer:SetPoint("TOPLEFT", display, "TOPLEFT", 3, -3)
    TitlebarContainer:SetPoint("TOPRIGHT", display, "TOPRIGHT", -3, -3)

    -- 타이틀바 전용 배경 (본체보다 약간 밝게 하여 구분감 생성)
    TitlebarContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    TitlebarContainer:SetBackdropColor(0.15, 0.15, 0.15, 0.9) -- 본체보다 진한 회색
    TitlebarContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
    self.Titlebar = TitlebarContainer

    -- [1. 알파 슬라이더: MinimalSliderTemplate + 하단 레이블]
    local alphaSlider = CreateFrame("Slider", "RLT_SynergyAlphaSlider", TitlebarContainer, "MinimalSliderTemplate")
    alphaSlider:SetPoint("LEFT", TitlebarContainer, "LEFT", 10, 4) -- 레이블 공간을 위해 약간 위로
    alphaSlider:SetSize(80, 18)
    alphaSlider:SetMinMaxValues(0, 1.0)
    alphaSlider:SetValueStep(0.05)
    alphaSlider:SetObeyStepOnDrag(true)
    alphaSlider:SetValue(self.db.global.synergyBgAlpha or 0.9)

    -- 슬라이더 바로 밑에 "Alpha" 텍스트 배치
    local alphaLabel = alphaSlider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    alphaLabel:SetFont([[Fonts\2002.TTF]], 9, "OUTLINE")
    alphaLabel:SetPoint("TOP", alphaSlider, "BOTTOM", 0, 2)
    alphaLabel:SetText("Alpha")

    alphaSlider:SetScript("OnValueChanged", function(s, value)
        self.db.global.synergyBgAlpha = value
        display:SetBackdropColor(0, 0, 0, value)
        display:SetBackdropBorderColor(1, 1, 1, value)
    end)

    -- [2. 오버레이 핀 버튼: 자물쇠 아이콘 형태]
    local pinBtn = CreateFrame("Button", nil, TitlebarContainer)
    pinBtn:SetSize(45,45) 
    pinBtn:SetPoint("RIGHT", TitlebarContainer, "RIGHT", 5, 0)

    local pinTex = pinBtn:CreateTexture(nil, "ARTWORK")
    pinTex:SetAllPoints()
    pinBtn.tex = pinTex

    -- 상태 업데이트 함수 
    local function UpdatePinIcon()
        local isPinned = self.db.global.optGroupSynergyOverlay
        if isPinned then
            -- 빨강 핀
            pinTex:SetTexture([[Interface\AddOns\RaidLeaderTool\Assets\Icons\pinRed]]) 
            pinBtn.tex:SetVertexColor(1, 1, 1, 1) -- 원본 색상 유지
        else
            -- 회색 핀
            pinTex:SetTexture([[Interface\AddOns\RaidLeaderTool\Assets\Icons\pinGray]])
            pinBtn.tex:SetVertexColor(1, 1, 1, 0.8) -- 해제 시 약간의 투명도를 주면 더 자연스러움
        end
    end
    UpdatePinIcon()

    -- 툴팁 설정 (마우스 올렸을 때 설명 출력)
    pinBtn:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        local status = self.db.global.optGroupSynergyOverlay and L["synergyOverlayTooltipTitleEnable"] or L["synergyOverlayTooltipTitleDisable"]
        GameTooltip:SetText(L["synergyOverlayTooltipTitle"] .. " " .. status)
        GameTooltip:AddLine(L["synergyOverlayTooltipTitleDiscription"], 1, 1, 1)
        GameTooltip:Show()
    end)
    pinBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- 하이라이트 효과 (마우스 올리면 밝아짐)
    pinBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    pinBtn:SetScript("OnClick", function()
        self.db.global.optGroupSynergyOverlay = not self.db.global.optGroupSynergyOverlay
        UpdatePinIcon()
        self:UpdateSynergyVisibility()
        
        -- 클릭 시 툴팁 즉시 갱신
        if GameTooltip:IsOwned(pinBtn) then
            pinBtn:GetScript("OnEnter")(pinBtn)
        end
    end)

    -- [2. HeaderContainer] (텍스트 양에 따라 가변 높이)
    local HeaderContainer = CreateFrame("Frame", nil, display)
    HeaderContainer:SetWidth(contentWidth)
    HeaderContainer:SetPoint("TOP", TitlebarContainer, "BOTTOM", 0, -10)
    self.HeaderCont = HeaderContainer

    local headerText = HeaderContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetFont([[Fonts\2002.TTF]], 16, "THICKOUTLINE")
    headerText:SetPoint("TOPLEFT", HeaderContainer, "TOPLEFT", 5, 0) 
    headerText:SetWidth(contentWidth) -- 줄바꿈을 위해 너비 고정
    headerText:SetJustifyH("LEFT")
    headerText:SetWordWrap(true)
    self.SynergyHeader = headerText

    -- [3. ModeButtonContainer] (높이 고정: 25)
    local ModeButtonContainer = CreateFrame("Frame", nil, display)
    ModeButtonContainer:SetSize(contentWidth, 30)
    ModeButtonContainer:SetPoint("TOP", HeaderContainer, "BOTTOM", 0, -15) -- 헤더 아래로 앵커
    self.ModeBtnCont = ModeButtonContainer

    -- [공통 버튼 생성 함수]
    local function CreateCustomButton(parent, width, height)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(width, height)
        
        -- 배경 (반투명 검정)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        -- 테두리 (회색)
        btn.border = btn:CreateLine()
        btn.border:SetColorTexture(0.5, 0.5, 0.5, 1)
        
        -- 텍스트 설정
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetFont([[Fonts\2002.TTF]], 12, "OUTLINE")
        
        -- 호버 효과 (마우스 올렸을 때 색 변화)
        btn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.4, 0.4, 0.4, 0.9)
            -- 툴팁 추가 (선택 사항)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["Click to toggle status"]) 
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
            GameTooltip:Hide()
        end)
        
        return btn
    end

    -- [3. ModeButtonContainer]
    local ModeButtonContainer = CreateFrame("Frame", nil, display)
    ModeButtonContainer:SetSize(contentWidth, 25)
    ModeButtonContainer:SetPoint("TOP", HeaderContainer, "BOTTOM", 0, -15)
    self.ModeBtnCont = ModeButtonContainer

    -- 1. 보기 모드 전환 버튼
    local viewBtn = CreateCustomButton(ModeButtonContainer, 100, 20)
    viewBtn:SetPoint("RIGHT", ModeButtonContainer, "RIGHT", -5, 0)

    -- 2. 축약 모드 설정 버튼
    local shortBtn = CreateCustomButton(ModeButtonContainer, 65, 20)
    shortBtn:SetPoint("RIGHT", viewBtn, "LEFT", -8, 0)

    local function UpdateBtnText()
        -- 보기 모드
        local viewLabel = self.db.global.useIconView and "Icon View" or "Text View"
        viewBtn.text:SetText("|cff00ff00" .. viewLabel .. "|r")
        
        -- 축약 모드 (텍스트 뷰일 때만 보임)
        if self.db.global.useIconView then
            shortBtn:Hide()
        else
            shortBtn:Show()
            local shortLabel = self.db.global.useShortText and "Full" or "Short"
            shortBtn.text:SetText("|cffffff00" .. shortLabel .. "|r")
        end
    end
    UpdateBtnText()

    viewBtn:SetScript("OnClick", function()
        PlaySound(856) -- [WoW UI Sounds](https://warcraft.wiki.gg)
        self.db.global.useIconView = not self.db.global.useIconView
        UpdateBtnText()
        self:UpdateSynergyDisplay()
    end)

    shortBtn:SetScript("OnClick", function()
        PlaySound(856)
        self.db.global.useShortText = not self.db.global.useShortText
        UpdateBtnText()
        self:UpdateSynergyDisplay()
    end)

    -- [4. DataContainer] (모드에 따라 가변 높이)
    local DataContainer = CreateFrame("Frame", nil, display)
    DataContainer:SetWidth(contentWidth)
    DataContainer:SetPoint("TOP", ModeButtonContainer, "BOTTOM", 0, -10)
    self.DataCont = DataContainer

    -- 텍스트 뷰
    local classText = DataContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classText:SetFont([[Fonts\2002.TTF]], 18, "THICKOUTLINE")
    classText:SetSpacing(12)
    classText:SetWidth(contentWidth - 10)
    classText:SetPoint("TOPLEFT", DataContainer, "TOPLEFT", 10, 0)
    classText:SetJustifyH("LEFT")
    classText:SetWordWrap(true)
    self.SynergyFrameText = classText

    -- 아이콘 뷰 그룹
    local iconGroup = CreateFrame("Frame", nil, DataContainer)
    iconGroup:SetPoint("TOPLEFT", DataContainer, "TOPLEFT", 15, 0)
    iconGroup:SetSize(220, 280) -- 아이콘 레이아웃에 따른 고정 높이
    self.IconContainer = iconGroup
    self.IconFrames = {}

    local classLayout = {
        {id="PRIEST", icon=626004, name=L["priest"]}, {id="MAGE", icon=626001, name=L["mage"]}, {id="WARLOCK", icon=626007, name=L["warlock"]}, {id=nil},
        {id="HUNTER", icon=626000, name=L["hunter"]}, {id="SHAMAN", icon=626006, name=L["shaman"]}, {id="EVOKER", icon=4574311, name=L["evoker"]}, {id=nil},
        {id="ROGUE", icon=626005, name=L["rogue"]}, {id="DRUID", icon=625999, name=L["druid"]}, {id="MONK", icon=626002, name=L["monk"]}, {id="DEMONHUNTER", icon=1260827, name=L["demonhunter"]},
        {id="WARRIOR", icon=626008, name=L["warrior"]}, {id="PALADIN", icon=626003, name=L["paladin"]}, {id="DEATHKNIGHT", icon=135771, name=L["deathknight"]}
    }

    for i, data in ipairs(classLayout) do
        if data.id then
            local f = CreateFrame("Frame", nil, iconGroup)
            f:SetSize(38, 38)
            local col, row = (i-1) % 4, math.floor((i-1) / 4)
            f:SetPoint("TOPLEFT", col * 55, -row * 70)
            f.tex = f:CreateTexture(nil, "ARTWORK")
            f.tex:SetAllPoints(); f.tex:SetTexture(data.icon)
            f.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            f.name:SetFont([[Fonts\2002.TTF]], 10, "THICKOUTLINE")
            f.name:SetPoint("TOP", f, "BOTTOM", 0, 2)
            f.name:SetText(data.name)
            f.count = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            f.count:SetFont([[Fonts\2002.TTF]], 16, "THICKOUTLINE")
            f.count:SetPoint("TOP", f.name, "BOTTOM", 0, 2)
            self.IconFrames[data.id] = f
        end
    end

    if not self.pveHooked then
        hooksecurefunc("PVEFrame_ShowFrame", function() self:UpdateSynergyVisibility() end)
        if PVEFrame then PVEFrame:HookScript("OnHide", function() self:UpdateSynergyVisibility() end) end
        self.pveHooked = true
    end
    self:UpdateSynergyVisibility()
end

-- [높이 계산 함수 추가]
function rlt:UpdateSynergyFrameSize()
    if not self.SynergyFrame then return end

    -- 1. 헤더 높이: 텍스트 실제 높이에 맞춤
    local headerH = self.SynergyHeader:GetStringHeight()
    self.HeaderCont:SetHeight(headerH + 2)

    -- 2. 데이터 컨테이너 높이: 모드에 따라 결정
    local dataH = 0
    if self.db.global.useIconView then
        dataH = 280 -- 아이콘 레이아웃 높이
    else
        dataH = self.SynergyFrameText:GetStringHeight() + 10
    end
    self.DataCont:SetHeight(dataH)

    -- 3. 부모 프레임 전체 높이 재계산 (모든 컨테이너 + 마진)
    local totalHeight = 10 + -- 상단 마진
                        self.Titlebar:GetHeight() + 10 + 
                        self.HeaderCont:GetHeight() + 15 + 
                        self.ModeBtnCont:GetHeight() + 10 + 
                        self.DataCont:GetHeight() + 20 -- 하단 마진
    
    self.SynergyFrame:SetHeight(totalHeight)
end

function rlt:UpdateSynergyDisplay()
    local data = self:GetSynergyData()
    
    -- [1. 상단 요약 정보]
    local header = string.format("\n"..L["synergyTotalSummaryFormat"], data.total, data.roleCount.TANK, data.roleCount.HEALER, data.roleCount.DAMAGER)
    local t1 = string.format(L["synergyTotalTierFormat"], data.tierCount.DREADFUL, data.tierCount.MYSTIC, data.tierCount.VENERATED, data.tierCount.ZENITH)
    local t2 = string.format(L["synergyTotalClassicTierFormat"], data.classicTierCount.CONQUEROR, data.classicTierCount.PROTECTOR, data.classicTierCount.VANQUISHER, data.classicTierCount.DEATH)
    
    self.SynergyHeader:SetText("|cffffffff" .. header .. "|r\n" .. t1 .. "\n" .. t2)

    -- [2. 하단 상세 정보 (아이콘 vs 텍스트)]
    if self.db.global.useIconView then
        -- 아이콘 뷰 모드
        self.SynergyFrameText:Hide()
        self.IconContainer:Show()
        for id, f in pairs(self.IconFrames) do
            local count = data.classCount[id] or 0
            f.count:SetText("x"..count)
            
            -- 아이콘 하단 이름 업데이트 (축약 여부 반영)
            local nameKey = self.db.global.useShortText and (id:lower() .. "_short") or id:lower()
            f.name:SetText(L[nameKey] or L[id:lower()])

            if count > 0 then 
                f.tex:SetDesaturated(false)
                f.count:SetTextColor(0, 1, 0)
            else 
                f.tex:SetDesaturated(true) 
                f.count:SetTextColor(0.5, 0.5, 0.5) 
            end
        end
    else
        -- 텍스트 뷰 모드
        self.IconContainer:Hide()
        self.SynergyFrameText:Show()
        
        local classStr = ""
        local classes = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER"}
        
        for i, class in ipairs(classes) do
            local color = RAID_CLASS_COLORS[class].colorStr
            local hasClass = (data.classCount[class] or 0) > 0
            local mark = hasClass and "|cff00ff00O|r" or "|cffff0000X|r"
            local cnt = hasClass and "("..data.classCount[class]..")" or ""
            
            if self.db.global.useShortText then
                local shortName = L[class:lower() .. "_short"] or L[class:lower()]
                -- 축약
                classStr = classStr .. string.format("|c%s%s|r : %s %s\n", color, shortName, mark, cnt)
            else
                -- 일반
                classStr = classStr .. string.format("|c%s%s|r : %s %s\n", color, L[class:lower()], mark, cnt)
            end
        end
        
        self.SynergyFrameText:SetText(classStr)
    end
    
    -- 텍스트 렌더링 후 프레임 높이 계산을 위한 지연 실행
    -- [C_Timer.After](https://warcraft.wiki.gg) 사용
    C_Timer.After(0.05, function() 
        if self.UpdateSynergyFrameSize then
            self:UpdateSynergyFrameSize() 
        end
    end)
end

function rlt:UpdateSynergyVisibility()
    -- 설정에서 비활성화했거나 프레임이 없으면 중단
    if not self.db.global.optGlobalEnable or not self.db.global.optGroupSynergy then
        if self.SynergyFrame then self.SynergyFrame:Hide() end
        return
    end

    local inGroup = IsInGroup()
    local inCombat = UnitAffectingCombat("player")
    local isOverlay = self.db.global.optGroupSynergyOverlay
    local isPveOpen = (PVEFrame and PVEFrame:IsShown())

    -- 파티 중이 아니거나 전투 중이면 숨김 (전투 중 팝업 방지)
    if not inGroup or inCombat then
        if self.SynergyFrame then self.SynergyFrame:Hide() end
        return
    end

    -- 오버레이 모드이거나 던전찾기(PVE) 창이 열려있을 때만 표시
    if isOverlay or isPveOpen then
        if not self.SynergyFrame then self:CreateSynergyUI() end -- 프레임 없으면 생성
        self.SynergyFrame:Show()
        self:UpdateSynergyDisplay()
    else
        if self.SynergyFrame then self.SynergyFrame:Hide() end
    end
end

---
--- 파티 모집글
---
rlt.LFGRecruitmentMemoFrame = nil -- 프레임 객체 저장 변수

-- 메모장 프레임을 생성하거나 가져오는 함수
function rlt:GetOrCreateMemoFrame()
    if LFGRecruitmentMemoFrame then return LFGRecruitmentMemoFrame end

    -- 1. 메인 외곽 프레임
    LFGRecruitmentMemoFrame = CreateFrame("Frame", "RLT_LFGRecruitmentMemoFrame", LFGListFrame.EntryCreation, "BackdropTemplate")
    LFGRecruitmentMemoFrame:SetSize(PVEFrame:GetWidth(), 250)
    LFGRecruitmentMemoFrame:SetPoint("TOPLEFT", PVEFrame, "BOTTOMLEFT", 0, -30)
    LFGRecruitmentMemoFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    LFGRecruitmentMemoFrame:SetBackdropColor(0, 0, 0, 0.9)

    -- 2. 타이틀 & 저장 버튼 (기존과 동일)
    local title = LFGRecruitmentMemoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 15, -15)
    title:SetText(L["recruitmentMemoTitle"])

    local btnContainer = CreateFrame("Frame", nil, LFGRecruitmentMemoFrame, "BackdropTemplate")
    btnContainer:SetSize(60, 26)
    btnContainer:SetPoint("TOPRIGHT", LFGRecruitmentMemoFrame, "TOPRIGHT", -10, -8)
    btnContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    btnContainer:SetBackdropColor(0.2, 0.2, 0.2, 0.8) -- 버튼 영역만 약간 더 밝게
    btnContainer:SetBackdropBorderColor(1, 0.82, 0, 1) -- 황금색 테두리로 강조

    local saveBtn = CreateFrame("Button", nil, btnContainer)
    saveBtn:SetAllPoints()
    saveBtn:SetNormalFontObject("GameFontNormalSmall")
    saveBtn:SetText(L["recruitmentMemoSave"])
    saveBtn:SetScript("OnClick", function()
        if rlt.db and rlt.db.global then
            rlt.db.global.optRecruitmentMemoText = LFGRecruitmentMemoFrame.EditBox:GetText()
            UIErrorsFrame:AddMessage(L["recruitmentMemoSaveMessage"], 0, 1, 0)
        end
        LFGRecruitmentMemoFrame.EditBox:ClearFocus()
    end)

    -- 3. ★ 에디트박스 테두리 프레임 (추가) ★
    local ebBorder = CreateFrame("Frame", nil, LFGRecruitmentMemoFrame, "BackdropTemplate")
    ebBorder:SetPoint("TOPLEFT", 10, -40)
    ebBorder:SetPoint("BOTTOMRIGHT", -10, 10)
    ebBorder:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    ebBorder:SetBackdropColor(0.1, 0.1, 0.1, 0.8) -- 입력창 배경을 약간 더 밝게
    ebBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) -- 회색 테두리

    -- 4. 스크롤 프레임 (ebBorder 안으로 배치)
    local scrollFrame = CreateFrame("ScrollFrame", "RLT_RecruitmentMemoScrollFrame", ebBorder, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 8)

    -- 5. 에디트박스
    local eb = CreateFrame("EditBox", nil, scrollFrame)
    eb:SetMultiLine(true)
    eb:SetMaxLetters(2000)
    eb:SetFontObject(ChatFontNormal)
    eb:SetWidth(scrollFrame:GetWidth()) 
    eb:SetAutoFocus(false)
    
    scrollFrame:SetScrollChild(eb)

    -- 렌더링 강제 갱신 로직 (텍스트 안보임 현상 방지)
    eb:SetScript("OnTextChanged", function(self)
        ScrollingEdit_OnTextChanged(self, self:GetParent())
    end)
    eb:SetScript("OnCursorChanged", function(self, x, y, w, h)
        ScrollingEdit_OnCursorChanged(self, x, y, w, h)
    end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- 초기 텍스트 설정 및 커서 정렬
    local savedText = (rlt.db and rlt.db.global and rlt.db.global.optRecruitmentMemoText) or ""
    eb:SetText(savedText)
    eb:SetCursorPosition(0) 

    LFGRecruitmentMemoFrame.EditBox = eb
    
    return LFGRecruitmentMemoFrame
end

---
--- 파티 탐색하기 버튼
---
rlt.lfgButtons = {}

function rlt:CreateLFGButtons()
    local f = _G.LFGListFrame
    if not f or self.lfgButtons.initialized then return end

    -- 공통 버튼 생성 함수 (중복 제거)
    local function CreateLFGButton(text, onClick)
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(144, 22)
        btn:SetText(text)
        btn:SetPoint("TOP", f, "BOTTOM", -100, 26)
        btn:SetScript("OnClick", onClick)
        btn:Hide()
        return btn
    end

    -- 탐색 버튼
    self.lfgButtons.Browse = CreateLFGButton(L["lfgBrowseParty"], function()
        local AV = f.ApplicationViewer
        if AV and AV.BrowseGroupsButton:IsEnabled() then AV.BrowseGroupsButton:Click() end
    end)

    -- 복귀 버튼
    self.lfgButtons.Return = CreateLFGButton(L["lfgBackGroup"], function()
        if not C_LFGList.GetActiveEntryInfo() then return end
        LFGListFrame_SetActivePanel(f, f.ApplicationViewer)
    end)
    
    -- 레이어 보정 (복귀 버튼)
    if f.SearchPanel and f.SearchPanel.BackButton then
        self.lfgButtons.Return:SetFrameLevel(f.SearchPanel.BackButton:GetFrameLevel() + 2)
    end

    -- UI 상태 변화 감지 후킹
    f.ApplicationViewer:HookScript("OnShow", function() self:UpdateLFGButtons() end)
    f.SearchPanel:HookScript("OnShow", function() self:UpdateLFGButtons() end)
    f:HookScript("OnHide", function() self.lfgButtons.Browse:Hide() self.lfgButtons.Return:Hide() end)

    self.lfgButtons.initialized = true
end

function rlt:UpdateLFGButtons()
    if not self.db.global.optGlobalEnable or not self.db.global.optGroupList then
        if self.lfgButtons.Browse then self.lfgButtons.Browse:Hide() end
        if self.lfgButtons.Return then self.lfgButtons.Return:Hide() end
        return
    end

    if not self.lfgButtons.initialized then self:CreateLFGButtons() end

    local inGroup = IsInGroup()
    -- 1. 그룹이 아니거나 '전투 중'이면 무조건 숨김
    if not inGroup then
        self.SynergyFrame:Hide()
        return
    end

    local f = _G.LFGListFrame
    local isActive = C_LFGList.GetActiveEntryInfo() ~= nil
    local isLeader = UnitIsGroupLeader("player")

    local showBrowse = isActive and not isLeader and f.ApplicationViewer:IsShown()
    local showReturn = isActive and f.SearchPanel:IsShown()

    self.lfgButtons.Browse:SetShown(showBrowse)
    self.lfgButtons.Return:SetShown(showReturn)
end

---
--- Public Function
---
function rlt:PlayAlert(soundkey)
    local soundKey = soundkey
    local soundData = SOUND_LIST[soundKey]
    local systemBackgroundSoundEnable = C_CVar.GetCVarBool("Sound_EnableSoundWhenGameIsInBG")

    if not rlt.db.global.optGlobalBackgroundEnable then
        return
    end

    if not systemBackgroundSoundEnable then
        C_CVar.SetCVar("Sound_EnableSoundWhenGameIsInBG","1");

        C_Timer.After(2, function(soundData)

            if type(soundData) == "string" then
                PlaySoundFile(soundData, "Master")
            elseif type(soundData) == "number" then
                PlaySound(soundData, "Master")
            end
            
            C_CVar.SetCVar("Sound_EnableSoundWhenGameIsInBG","0");
        end)
    else
        if type(soundData) == "string" then
            PlaySoundFile(soundData, "Master")
        elseif type(soundData) == "number" then
            PlaySound(soundData, "Master")
        end
    end
end

local textFrame = CreateFrame("Frame", nil, UIParent)
textFrame:SetSize(600, 100)
textFrame:SetPoint("CENTER", 0, 150)
textFrame:Hide()

local fontString = textFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
fontString:SetPoint("CENTER")
fontString:SetFont(fontString:GetFont() or [[Fonts\2002.TTF]], 64, "OUTLINE")

local hideTimer

function rlt:ShowText(text, duration)
    if not text then return end
    local displayTime = duration or 3
    
    if hideTimer then
        hideTimer:Cancel()
    end
    
    fontString:SetText(text)
    textFrame:Show()
    
    hideTimer = C_Timer.After(displayTime, function()
        textFrame:Hide()
    end)
end

---
--- [디버깅] 테스트 버튼
---
function rlt:CreateTestButton()
    local btn = CreateFrame("Button", "RLT_TestButton", UIParent, "UIPanelButtonTemplate")
    btn:SetSize(120, 30)
    btn:SetText("합류 이벤트 테스트")
    btn:SetPoint("CENTER")
    
    -- 마우스 드래그 설정
    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)
    btn:SetScript("OnDragStart", btn.StartMoving)
    btn:SetScript("OnDragStop", btn.StopMovingOrSizing)
    
    -- 클릭 시 이벤트 함수 호출
    btn:SetScript("OnClick", function()
        self:Print("테스트 버튼 클릭 - 이벤트를 시뮬레이션합니다.")
        self:GROUP_ROSTER_UPDATE()
    end)

    -- 처음엔 숨겨두고 싶다면 여기에 btn:Hide() 추가
    self.testButton = btn
end
