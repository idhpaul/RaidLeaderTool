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
local CURRENT_VERSION		= "1.0.7"

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
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("GROUP_JOINED")
    self:RegisterEvent("GROUP_LEFT")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateSynergyVisibility")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateSynergyVisibility")
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

function rlt:LFG_LIST_APPLICANT_UPDATED()

    local isLeader = UnitIsGroupLeader("player")
    local isAssistant = UnitIsGroupAssistant("player")
    local currentTime = GetTime()

    if not self.db.global.optGlobalEnable then 
        return 
    end
    
    if not (isLeader or isAssistant) then 
        return 
    end

    if self.db.global.optLfgAlert then

        if (currentTime - self.lastLfgAlertTime) < 3 then
            return 
        end
        self.lastLfgAlertTime = currentTime

        self:ShowText(L["newLfgAlertText"], 5)

        self:PlayAlert(self.db.global.optLfgAlertSound)

        if not GroupFinderFrame:IsVisible() then PVEFrame_ShowFrame("GroupFinderFrame")
            GroupFinderFrameGroupButton3:Click()
        end

        FlashClientIcon()
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
        self.SynergyFrameText:SetText(self:GetSynergyText())
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

function rlt:GetSynergyText()
    local numGroup = GetNumGroupMembers()
    local isRaid = IsInRaid()
    local prefix = isRaid and "raid" or "party"
    
    local classes = {"WARRIOR", "PALADIN", "HUNTER", 
                        "ROGUE", "PRIEST", "DEATHKNIGHT", 
                        "SHAMAN", "MAGE", "WARLOCK", 
                        "MONK", "DRUID", "DEMONHUNTER", "EVOKER"}
    local localized = {WARRIOR=L["warrior"], PALADIN=L["paladin"], HUNTER=L["hunter"], 
                        ROGUE=L["rogue"], PRIEST=L["priest"], DEATHKNIGHT=L["deathknight"], 
                        SHAMAN=L["shaman"], MAGE=L["mage"], WARLOCK=L["warlock"], 
                        MONK=L["monk"], DRUID=L["druid"], DEMONHUNTER=L["demonhunter"], EVOKER=L["evoker"]}
    
    local classCount = {}
    for _, c in ipairs(classes) do classCount[c] = 0 end
    local roleCount = {TANK = 0, HEALER = 0, DAMAGER = 0, NONE = 0}
    local tierCount = {DREADFUL = 0, MYSTIC = 0, VENERATED = 0, ZENITH = 0}
    local tierGroups = {DREADFUL = {"PRIEST", "MAGE", "WARLOCK"}, 
                        MYSTIC = {"ROGUE", "MONK", "DRUID", "DEMONHUNTER"}, 
                        VENERATED = {"HUNTER", "SHAMAN", "EVOKER"}, 
                        ZENITH = {"WARRIOR", "PALADIN", "DEATHKNIGHT"}}

    local classictierCount = {CONQUEROR = 0, PROTECTOR = 0, VANQUISHER = 0, DEATH = 0}
    local classictierGroups = {CONQUEROR = {"PALADIN", "PRIEST", "SHAMAN"}, 
                                PROTECTOR = {"WARRIOR", "ROGUE", "MONK", "EVOKER"}, 
                                VANQUISHER = {"HUNTER", "MAGE", "DRUID"}, 
                                DEATH = {"DEATHKNIGHT", "WARLOCK", "DEMONHUNTER"}}

    local total = 0
    local maxIdx = isRaid and numGroup or (numGroup > 0 and numGroup or 0)
    
    for i = 1, maxIdx do
        local unit = prefix..i
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            if class then
                total = total + 1
                classCount[class] = classCount[class] + 1
                local role = UnitGroupRolesAssigned(unit)
                roleCount[role] = (roleCount[role] or 0) + 1
            end
        end
    end

    if not isRaid or numGroup == 0 then
        local _, class = UnitClass("player")
        if not isRaid and classCount[class] == 0 then
            total = total + 1
            classCount[class] = 1
            roleCount[UnitGroupRolesAssigned("player")] = (roleCount[UnitGroupRolesAssigned("player")] or 0) + 1
        end
    end

    for group, list in pairs(tierGroups) do
        for _, c in ipairs(list) do tierCount[group] = tierCount[group] + (classCount[c] or 0) end
    end

    for group, list in pairs(classictierGroups) do
        for _, c in ipairs(list) do classictierCount[group] = classictierCount[group] + (classCount[c] or 0) end
    end

    local header = string.format(L["synergyTotalSummaryFormat"], total, roleCount.TANK, roleCount.HEALER, roleCount.DAMAGER)
    local tierStr = string.format(L["synergyTotalTierFormat"], tierCount.DREADFUL, tierCount.MYSTIC, tierCount.VENERATED, tierCount.ZENITH)
    local classictierStr = string.format(L["synergyTotalClassicTierFormat"], classictierCount.CONQUEROR, classictierCount.PROTECTOR, classictierCount.VANQUISHER, classictierCount.DEATH)
    local classStr = "\n"
    for i, class in ipairs(classes) do
        local color = RAID_CLASS_COLORS[class].colorStr
        local mark = (classCount[class] > 0) and "|cff00ff00O|r" or "|cffff0000X|r"
        local cnt = (classCount[class] >= 1) and "("..classCount[class]..")" or ""
        classStr = classStr .. string.format("|c%s%s|r : %s%s\n", color, localized[class], mark, cnt)
    end
    return "\n\n" ..header .. tierStr ..classictierStr .. "\n" .. classStr
end

function rlt:GetSynergyIcon()
    local classData = {
        {id="PRIEST", name="사제", icon=626004}, {id="MAGE", name="마법사", icon=626001}, {id="WARLOCK", name="흑마법사", icon=626007}, {id=nil},
        {id="HUNTER", name="사냥꾼", icon=626000}, {id="SHAMAN", name="주술사", icon=626006}, {id="EVOKER", name="기원사", icon=4574311}, {id=nil},
        {id="ROGUE", name="도적", icon=626005}, {id="DRUID", name="드루이드", icon=625999}, {id="MONK", name="수도사", icon=626002}, {id="DEMONHUNTER", name="악마사냥꾼", icon=1260827},
        {id="WARRIOR", name="전사", icon=626008}, {id="PALADIN", name="성기사", icon=626003}, {id="DEATHKNIGHT", name="죽음의 기사", icon=135771}, {id=nil}
    }

    local iconSize = 40
    local spacingX = 16  -- 아이콘 사이 가로 간격을 4px로 극축소
    local rowHeight = 70 -- 아이콘+텍스트 포함 한 행의 높이를 54px로 압축

    local mainFrame = CreateFrame("Frame", "ClassMonitorMainFrame", UIParent)
    mainFrame:SetSize((iconSize + spacingX) * 4, rowHeight * 4)
    mainFrame:SetPoint("CENTER")

    for i, data in ipairs(classData) do
        if data.id then
            local f = CreateFrame("Frame", nil, mainFrame)
            f:SetSize(iconSize, iconSize)
            
            local col = (i-1) % 4
            local row = math.floor((i-1) / 4)
            f:SetPoint("TOPLEFT", col * (iconSize + spacingX), -row * rowHeight)

            -- 1. 아이콘 (정사각형)
            f.tex = f:CreateTexture(nil, "ARTWORK")
            f.tex:SetAllPoints()
            f.tex:SetTexture(data.icon)
            f.tex:SetDesaturated(true)

            -- 2. 클래스 명칭 ([사제]) - 아이콘 하단에 바짝 붙임
            f.nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            f.nameText:SetFont(f.nameText:GetFont(), 12, "OUTLINE") 
            f.nameText:SetPoint("TOP", f, "BOTTOM", 0, 8) 
            f.nameText:SetText("[" .. data.name .. "]")
            f.nameText:SetTextColor(0.7, 0.7, 0.7)

            -- 3. 인원수 (x0) - 명칭 바로 아래 밀착
            f.countText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            f.countText:SetFont(f.countText:GetFont(), 15, "THICKOUTLINE")
            f.countText:SetPoint("TOP", f.nameText, "BOTTOM", 0, -3) 
            f.countText:SetText("x0")
        end
    end
end

function rlt:UpdateSynergyFrameSize()
    if not self.SynergyFrameText or not self.SynergyFrame then return end
    
    -- 텍스트의 실제 너비와 높이 계산
    local textWidth = self.SynergyFrameText:GetStringWidth()
    local textHeight = self.SynergyFrameText:GetStringHeight()

    -- 1. 폭(Width) 설정 (양옆 여백 20px 추가)
    local targetWidth = textWidth + 20
    
    -- (옵션) 너무 좁거나 넓어지지 않게 제한 설정
    if targetWidth < 100 then targetWidth = 100 end -- 최소폭
    if targetWidth > 400 then targetWidth = 400 end -- 최대폭

    self.SynergyFrame:SetWidth(targetWidth)

    -- 2. 높이(Height) 설정 (상하 여백 35px 추가)
    self.SynergyFrame:SetHeight(textHeight + 35)
end

function rlt:CreateSynergyUI()
    if self.SynergyFrame then return end

    -- 1. 텍스트 프레임 (이제 이 프레임이 메인이자 드래그 핸들)
    local display = CreateFrame("Frame", "RLT_SynergyFrame", UIParent, "BackdropTemplate")
    local pos = self.db.global.groupSynergyPos
    display:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    display:SetWidth(350)
    display:SetMovable(true)
    display:SetClampedToScreen(true)
    display:SetBackdrop({ 
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = true, tileSize = 16, edgeSize = 16, 
        insets = { left = 4, right = 4, top = 4, bottom = 4 } 
    })
    display:SetBackdropColor(0, 0, 0, 0.9)
    display:EnableMouse(true)
    self.SynergyFrame = display

    -- 2. 드래그 로직 (프레임 직접 조작)
    display:RegisterForDrag("LeftButton")
    display:SetScript("OnDragStart", function(self) self:StartMoving() end)
    display:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        rlt.db.global.groupSynergyPos = { point = point, x = x, y = y }
    end)

    -- 3. 오버레이 토글 컨테이너
    local toggleContainer = CreateFrame("Frame", nil, display, "BackdropTemplate")
    toggleContainer:SetSize(130, 30) -- 텍스트와 버튼이 들어갈 크기
    toggleContainer:SetPoint("TOPRIGHT", display, "TOPRIGHT", -8, -8)
    toggleContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- 얇은 테두리
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    toggleContainer:SetBackdropColor(0.2, 0.2, 0.2, 0.8) -- 버튼 영역만 약간 더 밝게
    toggleContainer:SetBackdropBorderColor(1, 0.82, 0, 1) -- 황금색 테두리로 강조

    local toggleBtn = CreateFrame("CheckButton", nil, toggleContainer, "UICheckButtonTemplate")
    toggleBtn:SetSize(22, 22)
    toggleBtn:SetPoint("RIGHT", toggleContainer, "RIGHT", -5, 0)
    toggleBtn.text = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toggleBtn.text:SetPoint("RIGHT", toggleBtn, "LEFT", -2, 0)
    toggleBtn.text:SetText(L["synergyOverlayToggleEnable"]) -- 흰색으로 텍스트 강조
    
    toggleBtn:SetChecked(self.db.global.optGroupSynergyOverlay)

    toggleContainer:SetScript("OnEnter", function()
        GameTooltip:SetOwner(toggleBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["synergyOverlayTooltipTitle"], 1, 1, 1)
        GameTooltip:AddLine(L["synergyOverlayTooltipCheckText"], 1, 0.82, 0, true)
        GameTooltip:AddLine(L["synergyOverlayTooltipUnCheckText"], 1, 0.82, 0, true)
        GameTooltip:AddLine(L["synergyOverlayTooltipUnHideText"], 0.5, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    toggleContainer:SetScript("OnLeave", function() GameTooltip:Hide() end)

    toggleBtn:SetScript("OnClick", function(cb)
        self.db.global.optGroupSynergyOverlay = cb:GetChecked()
        self:UpdateSynergyVisibility()
    end)

    -- 4. 텍스트 객체
    local text = display:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetFont(text:GetFont() or [[Fonts\2002.TTF]], 15, "OUTLINE")
    text:SetPoint("TOPLEFT", 12, -12)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
    self.SynergyFrameText = text

    -- 5. PVEFrame 후킹
    if not self.pveHooked then
        hooksecurefunc("PVEFrame_ShowFrame", function() self:UpdateSynergyVisibility() end)
        if PVEFrame then
            PVEFrame:HookScript("OnHide", function() self:UpdateSynergyVisibility() end)
        end
        self.pveHooked = true
    end

    -- 높이 조절 후킹
    hooksecurefunc(text, "SetText", function() self:UpdateSynergyFrameSize() end)

    -- 초기 상태 적용
    self:UpdateSynergyVisibility()
end

function rlt:UpdateSynergyVisibility()
    if not self.db.global.optGlobalEnable or not self.db.global.optGroupSynergy then
        if self.SynergyFrame then 
            self.SynergyFrame:Hide() 
        end

        return
    end

    if not self.SynergyFrame then 
        return 
    end

    local inGroup = IsInGroup()
    local isOverlay = self.db.global.optGroupSynergyOverlay
    local isPveOpen = PVEFrame and PVEFrame:IsShown()
    local inCombat = UnitAffectingCombat("player") -- [추가] 전투 여부 확인

    -- 1. 그룹이 아니거나 '전투 중'이면 무조건 숨김
    if not inGroup or inCombat then
        self.SynergyFrame:Hide()
        return
    end

    -- 2. 비전투 상태 + 그룹인 경우: 오버레이 ON 또는 파티찾기(H) 창이 열려 있을 때 표시
    if isOverlay or isPveOpen then
        self.SynergyFrame:Show()
        if self.SynergyFrameText then
            self.SynergyFrameText:SetText(self:GetSynergyText())
        end
        rlt.SynergyIconUI()
    else
        self.SynergyFrame:Hide()
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
