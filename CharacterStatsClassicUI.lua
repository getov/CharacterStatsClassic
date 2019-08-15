-- Namespaces
-- core - table (namespace) shared between every lua file
local addonName, core = ...;
core.UIConfig = {};

-- Defaults
local UISettingsGlobal = {
}

local UISettingsCharacter = {
    selectedLeftStatsCategory = 1;
    selectedRightStatsCategory = 2;
}

-- for easier referencing the core config
local UIConfig = core.UIConfig;
local CSC_UIFrame = core.UIConfig;

local statsDropdownList = {
    "Base Stats",
    "Melee",
    "Ranged",
    "Spell",
    "Defenses"
}

local NUM_STATS_TO_SHOW = 6;
local LeftStatsTable = { }
local RightStatsTable = { }

--[[
print("Crit chance: " .. GetCritChance());
print("Spell Crit chance: " .. GetSpellCritChance(2));
print("Dodge Chance: " .. GetDodgeChance());
print("Parry Chance: " .. GetParryChance());
print("Shield Block: " .. GetShieldBlock());
print("Damage: " .. UnitDamage("player"));
print("DPS: " .. UnitDamage("player") / UnitAttackSpeed("player"));
print("Attack speed: " .. UnitAttackSpeed("player"));
print("Attack power: " .. UnitAttackPower("player"));
print("Defense: " .. UnitDefense("player"));
print("Spell Haste: " .. UnitSpellHaste("player"));
print("Hit: " .. GetHitModifier());
print("Spell Hit: " .. GetSpellHitModifier());
--]]

function UIConfig:InitializeStatsFrames(leftParentFrame, rightParentFrame)
    local offsetStepY = 15;
    local accumulatedOffsetY = 0;
    
    for i = 1, NUM_STATS_TO_SHOW do
        accumulatedOffsetY = accumulatedOffsetY + offsetStepY;
        local actualOffset = accumulatedOffsetY;
        
        if i == 1 then 
            actualOffset = 35;
            accumulatedOffsetY = 35;
        end

        LeftStatsTable[i] = CreateFrame("Frame", nil, leftParentFrame, "CharacterStatFrameTemplate");
        LeftStatsTable[i]:SetPoint("LEFT", leftParentFrame, "TOPLEFT", 10, -actualOffset);
        LeftStatsTable[i]:SetWidth(130);

        RightStatsTable[i] = CreateFrame("Frame", nil, rightParentFrame, "CharacterStatFrameTemplate");
        RightStatsTable[i]:SetPoint("LEFT", rightParentFrame, "TOPLEFT", 10, -actualOffset);
        RightStatsTable[i]:SetWidth(130);
    end
end

function UIConfig:SetCharacterStats(statsTable, category)
    if category == "Base Stats" then
        -- str, agility, stamina, intelect, spirit, armor
        PaperDollFrame_SetStat(statsTable[1], "player", LE_UNIT_STAT_STRENGTH);
        PaperDollFrame_SetStat(statsTable[2], "player", LE_UNIT_STAT_AGILITY);
        PaperDollFrame_SetStat(statsTable[3], "player", LE_UNIT_STAT_INTELLECT);
        PaperDollFrame_SetStat(statsTable[4], "player", LE_UNIT_STAT_STAMINA);
        --PaperDollFrame_SetStat(statsTable[5], "player", LE_UNIT_STAT_STRENGTH);
        --PaperDollFrame_SetStat(statsTable[6], "player", LE_UNIT_STAT_STRENGTH);
        statsTable[5]:Hide();
        statsTable[6]:Hide();
    elseif category == "Defenses" then
        -- armor, defense, dodge, parry, block
        PaperDollFrame_SetArmor(statsTable[1], "player");
        PaperDollFrame_SetDodge(statsTable[2], "player");
        PaperDollFrame_SetParry(statsTable[3], "player");
        PaperDollFrame_SetBlock(statsTable[4], "player");
        PaperDollFrame_SetStagger(statsTable[5], "player");
        --PaperDollFrame_SetArmor(statsTable[6], "player");
        statsTable[6]:Hide();
    elseif category == "Melee" then
        -- damage, Att Power, speed, hit raiting, crit chance
        PaperDollFrame_SetDamage(statsTable[1], "player");
        PaperDollFrame_SetAttackPower(statsTable[2], "player");
        PaperDollFrame_SetAttackSpeed(statsTable[3], "player");
        PaperDollFrame_SetCritChance(statsTable[4], "player");
        --PaperDollFrame_SetCritChance(statsTable[5], "player");
        --PaperDollFrame_SetCritChance(statsTable[6], "player");
        statsTable[5]:Hide();
        statsTable[6]:Hide();
    elseif category == "Ranged" then
        -- 
        PaperDollFrame_SetDamage(statsTable[1], "player");
        PaperDollFrame_SetAttackPower(statsTable[2], "player");
        PaperDollFrame_SetAttackSpeed(statsTable[3], "player");
        PaperDollFrame_SetCritChance(statsTable[4], "player");
        statsTable[5]:Hide();
        statsTable[6]:Hide();
    elseif category == "Spell" then
        -- bonus dmg, bonus healing, hit raiting, crit chance, haste raiting, mana regen
        PaperDollFrame_SetSpellPower(statsTable[1], "player");
        PaperDollFrame_SetManaRegen(statsTable[2], "player");
        --PaperDollFrame_SetAttackSpeed(statsTable[3], "player");
        --PaperDollFrame_SetCritChance(statsTable[4], "player");
        statsTable[3]:Hide();
        statsTable[4]:Hide();
        statsTable[5]:Hide();
        statsTable[6]:Hide();
    end
    --print(category)
end

function UIConfig:CreateMenu()
    CSC_UIFrame.CharacterStatsPanel = CreateFrame("Frame", nil, PaperDollFrame); --CharacterFrameInsetRight
	CSC_UIFrame.CharacterStatsPanel:SetPoint("LEFT", CharacterFrameInset, "BOTTOMLEFT", 32, 0);
	CSC_UIFrame.CharacterStatsPanel:SetHeight(320);
    CSC_UIFrame.CharacterStatsPanel:SetWidth(200);

    UIConfig:SetupDropdown();

    UIConfig:InitializeStatsFrames(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown);
    UIConfig:SetCharacterStats(LeftStatsTable, statsDropdownList[UISettingsCharacter.selectedLeftStatsCategory]);
    UIConfig:SetCharacterStats(RightStatsTable, statsDropdownList[UISettingsCharacter.selectedRightStatsCategory]);
end

function UIConfig:UpdateStats()
    --for i = 1, NUM_STATS_TO_SHOW do
        --if getn(LeftStatsTable) > 0 then
        
       -- end
        --if getn(RightStatsTable) > 0 then
        
        --end
    --end
    UIConfig:SetCharacterStats(LeftStatsTable, statsDropdownList[UISettingsCharacter.selectedLeftStatsCategory]);
    UIConfig:SetCharacterStats(RightStatsTable, statsDropdownList[UISettingsCharacter.selectedRightStatsCategory]);
end

local function OnClickLeftStatsDropdown(self)
    UISettingsCharacter.selectedLeftStatsCategory = self:GetID();
    UIDropDownMenu_SetSelectedID(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, UISettingsCharacter.selectedLeftStatsCategory);
    UIConfig:SetCharacterStats(LeftStatsTable, statsDropdownList[UISettingsCharacter.selectedLeftStatsCategory]);
end

local function OnClickRightStatsDropdown(self)
    UISettingsCharacter.selectedRightStatsCategory = self:GetID();
    UIDropDownMenu_SetSelectedID(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, UISettingsCharacter.selectedRightStatsCategory);
    UIConfig:SetCharacterStats(RightStatsTable, statsDropdownList[UISettingsCharacter.selectedRightStatsCategory]);
end

function UIConfig:InitializeLeftStatsDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo();
    for k,v in pairs(statsDropdownList) do
        info.text = v;
        info.func = OnClickLeftStatsDropdown;
        info.checked = false;
        UIDropDownMenu_AddButton(info, level);
     end
end

function UIConfig:InitializeRightStatsDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo();
    for k,v in pairs(statsDropdownList) do
        info.text = v;
        info.func = OnClickRightStatsDropdown;
        info.checked = false;
        UIDropDownMenu_AddButton(info, level);
     end
end

function UIConfig:SetupDropdown()

    CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown = CreateFrame("Frame", nil, CSC_UIFrame.CharacterStatsPanel, "UIDropDownMenuTemplate");
    CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown:SetPoint("TOPLEFT", CSC_UIFrame.CharacterStatsPanel, "TOPLEFT", 0, 0);

    CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown = CreateFrame("Frame", nil, CSC_UIFrame.CharacterStatsPanel, "UIDropDownMenuTemplate");
    CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown:SetPoint("TOPLEFT", CSC_UIFrame.CharacterStatsPanel, "TOPLEFT", 115, 0);

    UIDropDownMenu_Initialize(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, UIConfig.InitializeLeftStatsDropdown);
    UIDropDownMenu_SetSelectedID(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, UISettingsCharacter.selectedLeftStatsCategory);
    UIDropDownMenu_SetWidth(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, 99);
    UIDropDownMenu_JustifyText(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, "LEFT");

    UIDropDownMenu_Initialize(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, UIConfig.InitializeRightStatsDropdown);
    UIDropDownMenu_SetSelectedID(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, UISettingsCharacter.selectedRightStatsCategory);
    UIDropDownMenu_SetWidth(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, 99);
    UIDropDownMenu_JustifyText(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, "LEFT");
end

-- Serializing the DB
local dbLoader = CreateFrame("Frame");
dbLoader:RegisterEvent("ADDON_LOADED");
dbLoader:RegisterEvent("PLAYER_LOGOUT");

-- ADDON_LOADED is called after the code of the addon is being executed
-- Therefore I have to call any setup-functions dependent on the DB after the event (UIConfig:SetupDropdown())
function dbLoader:OnEvent(event, arg1)
    if (event == "ADDON_LOADED" and arg1 == "CharacterStatsClassic") then
        -- Global DB
        if (CharacterStatsClassicDB == nil) then
            CharacterStatsClassicDB = UISettingsGlobal;
        else
            UISettingsGlobal = CharacterStatsClassicDB;
        end
        
        -- Character DB
        if (CharacterStatsClassicCharacterDB == nil) then
            CharacterStatsClassicCharacterDB = UISettingsCharacter;
        else
            UISettingsCharacter = CharacterStatsClassicCharacterDB;
        end

        UIConfig:CreateMenu();
    elseif (event == "PLAYER_LOGOUT") then
        CharacterStatsClassicDB = UISettingsGlobal;
        CharacterStatsClassicCharacterDB = UISettingsCharacter;
    end
end

dbLoader:SetScript("OnEvent", dbLoader.OnEvent);