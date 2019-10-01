--[[
    Util functions that wrap my interface and the Blizzard's WoW Classic lua API code for ease of use
]]

local function DebugBreakPrint()
    print("ERROR");
end

-- GENERAL UTIL FUNCTIONS --
local function CSC_GetAppropriateDamage(unit, category)
	if category == PLAYERSTAT_MELEE_COMBAT then
		return UnitDamage(unit);
	elseif category == PLAYERSTAT_RANGED_COMBAT then
		local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
		return minDamage, maxDamage, nil, nil, bonusPos, bonusNeg, percent;
	end
end

local function CSC_GetAppropriateAttackSpeed(unit, category)
	if category == PLAYERSTAT_MELEE_COMBAT then
		return UnitAttackSpeed(unit);
	elseif category == PLAYERSTAT_RANGED_COMBAT then
		local attackSpeed = select(1, UnitRangedDamage(unit))
		return attackSpeed, 0;
	end
end

local function CSC_GetAppropriateAttackRaiting(unit, category)
	local attackBase = 0;
	local attackModifier = 0;

	if category == PLAYERSTAT_MELEE_COMBAT then
		attackBase, attackModifier = UnitAttackBothHands(unit);
	elseif category == PLAYERSTAT_RANGED_COMBAT then
		attackBase, attackModifier = UnitRangedAttack(unit)
	end

	local attackWithModifier = attackBase + attackModifier;
	return attackWithModifier;
end

local function CSC_PaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue)
	if ( isPercentage ) then
		statFrame.Value:SetText(format("%.1F%%", numericValue));
	else
		statFrame.Value:SetText(text);
	end
	statFrame.numericValue = numericValue;

	if ( statFrame.Label ) then
		statFrame.Label:SetText(format(STAT_FORMAT, label));
		statFrame.Label:SetWidth(statFrame:GetWidth() - statFrame.Value:GetWidth() - 20);
		statFrame.Label:SetHeight(statFrame:GetHeight());
		statFrame.Label:SetJustifyH("LEFT");
	end
end

local function CSC_PaperDollFormatStat(name, base, posBuff, negBuff)
	local effective = max(0,base + posBuff + negBuff);
	local text = HIGHLIGHT_FONT_COLOR_CODE..name.." "..effective;
	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
		text = text..FONT_COLOR_CODE_CLOSE;
	else 
		if ( posBuff > 0 or negBuff < 0 ) then
			text = text.." ("..base..FONT_COLOR_CODE_CLOSE;
		end
		if ( posBuff > 0 ) then
			text = text..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
		end
		if ( negBuff < 0 ) then
			text = text..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
		end
		if ( posBuff > 0 or negBuff < 0 ) then
			text = text..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
		end

		-- if there is a negative buff then show the main number in red, even if there are
		-- positive buffs. Otherwise show the number in green
		if ( negBuff < 0 ) then
			effective = RED_FONT_COLOR_CODE..effective..FONT_COLOR_CODE_CLOSE;
		elseif (posBuff > 0) then
			effective = GREEN_FONT_COLOR_CODE..effective..FONT_COLOR_CODE_CLOSE;
		end
	end
    
    return effective, text;
end

-- returns additional crit % stats from Arcane instability and Critical Mass if any
local function CSC_GetMageCritStatsFromTalents()

	local arcaneInstabilityCrit = 0;
	local criticalMassCrit = 0;

	-- Arcane Instability (1, 2, 3)%
	local arcaneInstabilityTable = { 1, 2, 3 };
	local spellRank = select(5, GetTalentInfo(1, 15));
	if (spellRank > 0) and (spellRank <= 3) then
		arcaneInstabilityCrit = arcaneInstabilityTable[spellRank];
	end

	-- Critical Mass (2, 4, 6)%
	local criticalMassTable = { 2, 4, 6 };
	spellRank = select(5, GetTalentInfo(2, 13));
	if (spellRank > 0) and (spellRank <= 3) then
		criticalMassCrit = criticalMassTable[spellRank];
	end

	return arcaneInstabilityCrit, criticalMassCrit;
end

-- returns the combined crit stats from Holy Specialization and Force of Will
local function CSC_GetPriestCritStatsFromTalents()
	
	local holySpecializationCrit = 0;
	local forceOfWillCrit = 0;

	local critTable = { 1, 2, 3, 4, 5 };
	-- Holy Specialization (1, 2, 3, 4, 5)%
	local spellRank = select(5, GetTalentInfo(2, 3));
	if (spellRank > 0) and (spellRank <= 5) then
		holySpecializationCrit = critTable[spellRank];
	end

	-- Force of Will (1, 2, 3, 4, 5)%
	spellRank = select(5, GetTalentInfo(1, 14));
	if (spellRank > 0) and (spellRank <= 5) then
		forceOfWillCrit = critTable[spellRank];
	end

	local critCombined = holySpecializationCrit + forceOfWillCrit;
	return critCombined;
end

-- returns the crit bonus from Holy Power
local function CSC_GetPaladinCritStatsFromTalents()

	local holyPowerCrit = 0;
	local critTable = { 1, 2, 3, 4, 5 };

	-- Holy Power (1, 2, 3, 4, 5)%
	local spellRank = select(5, GetTalentInfo(1, 13));
	if (spellRank > 0) and (spellRank <= 5) then
		holyPowerCrit = critTable[spellRank];
	end

	return holyPowerCrit;
end
-- GENERAL UTIL FUNCTIONS END --

-- PRIMARY STATS --
function CSC_PaperDollFrame_SetPrimaryStats(statFrames, unit)
	
	local statIndexTable = {
		"STRENGTH",
		"AGILITY",
		"STAMINA",
		"INTELLECT",
		"SPIRIT",
	}

	-- Fix for classic (NUM_STATS instead of NUM_STATS-1)
	for i=1, NUM_STATS, 1 do
		local frameText;

		local stat;
		local effectiveStat;
		local posBuff;
		local negBuff;
		stat, effectiveStat, posBuff, negBuff = UnitStat(unit, i);
		
		-- Set the tooltip text
		local tooltipText = HIGHLIGHT_FONT_COLOR_CODE.._G["SPELL_STAT"..i.."_NAME"].." ";

		-- Get class specific tooltip for that stat
		local temp, classFileName = UnitClass(unit);
		local classStatText = _G[strupper(classFileName).."_"..statIndexTable[i].."_".."TOOLTIP"];
		-- If can't find one use the default
		if ( not classStatText ) then
			classStatText = _G["DEFAULT".."_"..statIndexTable[i].."_".."TOOLTIP"];
		end

		if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
			--text:SetText(effectiveStat);
			frameText = effectiveStat;
			statFrames[i].tooltip = tooltipText..effectiveStat..FONT_COLOR_CODE_CLOSE;
			statFrames[i].tooltip2 = classStatText;
		else 
			tooltipText = tooltipText..effectiveStat;
			if ( posBuff > 0 or negBuff < 0 ) then
				tooltipText = tooltipText.." ("..(stat - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE;
			end
			if ( posBuff > 0 ) then
				tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
			end
			if ( negBuff < 0 ) then
				tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
			end
			if ( posBuff > 0 or negBuff < 0 ) then
				tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
			end
			statFrames[i].tooltip = tooltipText;
			statFrames[i].tooltip2= classStatText;

			-- If there are any negative buffs then show the main number in red even if there are
			-- positive buffs. Otherwise show in green.
			if ( negBuff < 0 ) then
				frameText = RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE;
			else
				frameText = GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE;
			end
		end
		CSC_PaperDollFrame_SetLabelAndText(statFrames[i], _G["SPELL_STAT"..i.."_NAME"], frameText, false, effectiveStat);
		statFrames[i]:Show();
	end
end

-- DAMAGE --
function CSC_PaperDollFrame_SetDamage(statFrame, unit, category)

	if (category == PLAYERSTAT_RANGED_COMBAT) and not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, DAMAGE, NOT_APPLICABLE, false, 0);
		statFrame:Show();
		return;
	end

    statFrame:SetScript("OnEnter", CSC_CharacterDamageFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)

    local speed, offhandSpeed = CSC_GetAppropriateAttackSpeed(unit, category);
    local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = CSC_GetAppropriateDamage(unit, category);
    
    local displayMin = max(floor(minDamage),1);
    local displayMax = max(ceil(maxDamage),1);
    
    minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
    maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;
    
    local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
	local damagePerSecond = (max(fullDamage,1) / speed);
    local damageTooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);
    
    local colorPos = "|cff20ff20";
    local colorNeg = "|cffff2020";
	
    -- epsilon check
	if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
		totalBonus = 0.0;
    end
    
    local damageText;

    if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText = displayMin.." - "..displayMax;
		else
			damageText = displayMin.."-"..displayMax;
		end
	else
		-- set bonus color and display
		local color;
		if ( totalBonus > 0 ) then
			color = colorPos;
		else
			color = colorNeg;
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText = color..displayMin.." - "..displayMax.."|r";
		else
			damageText = color..displayMin.."-"..displayMax.."|r";
		end
		if ( physicalBonusPos > 0 ) then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end
    end
    
    CSC_PaperDollFrame_SetLabelAndText(statFrame, DAMAGE, damageText, false, displayMax);

    statFrame.damage = damageTooltip;
	statFrame.attackSpeed = speed;
    statFrame.dps = damagePerSecond;
	statFrame.attackRating = CSC_GetAppropriateAttackRaiting(unit, category);
	statFrame.TooltipMainTxt = INVTYPE_WEAPONMAINHAND;

	if (category == PLAYERSTAT_RANGED_COMBAT) and IsRangedWeapon() then
		statFrame.TooltipMainTxt = INVTYPE_RANGED;
	end

    -- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed and category == PLAYERSTAT_MELEE_COMBAT) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
		local offhandDamagePerSecond = (max(offhandFullDamage,1) / offhandSpeed);
		local offhandDamageTooltip = max(floor(minOffHandDamage),1).." - "..max(ceil(maxOffHandDamage),1);
		if ( physicalBonusPos > 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end
		statFrame.offhandDamage = offhandDamageTooltip;
		statFrame.offhandAttackSpeed = offhandSpeed;
		statFrame.offhandDps = offhandDamagePerSecond;
	else
		statFrame.offhandAttackSpeed = nil;
    end

	statFrame:Show();
end

-- Note: while this function was historically named "BothHands",
-- it looks like it only ever displayed attack rating for the main hand.
function CSC_PaperDollFrame_SetAttackBothHands(statFrame, unit)

	local mainHandAttackBase, mainHandAttackMod = UnitAttackBothHands(unit);
	local attackWithModifier = mainHandAttackBase + mainHandAttackMod;
	local attackText;

	if( mainHandAttackMod == 0 ) then
		attackText = mainHandAttackBase;
	else
		local color = RED_FONT_COLOR_CODE;
		if( mainHandAttackMod > 0 ) then
			color = GREEN_FONT_COLOR_CODE;
		end
		attackText = color..attackWithModifier..FONT_COLOR_CODE_CLOSE;
	end

	CSC_PaperDollFrame_SetLabelAndText(statFrame, DAMAGE, attackText, false, attackWithModifier);

	statFrame.tooltip = ATTACK_TOOLTIP;
	statFrame.tooltip2 = ATTACK_TOOLTIP_SUBTEXT;
	statFrame:Show();
end

function CSC_PaperDollFrame_SetMeleeAttackPower(statFrame, unit)
    
	local base, posBuff, negBuff = UnitAttackPower(unit);
    
    local valueText, tooltipText = CSC_PaperDollFormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff);
    local valueNum = max(0, base + posBuff + negBuff);
    CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ATTACK_POWER, valueText, false, valueNum);
    statFrame.tooltip = tooltipText;
    statFrame.tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetRangedAttackPower(statFrame, unit)
	
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ATTACK_POWER, NOT_APPLICABLE, false, 0);
		statFrame:Show();
		return;
	end

	if ( HasWandEquipped() ) then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ATTACK_POWER, NOT_APPLICABLE, false, 0);
		statFrame.tooltip = nil;
		statFrame:Show();
		return;
	end

	local base, posBuff, negBuff = UnitRangedAttackPower(unit);
    local valueText, tooltipText = CSC_PaperDollFormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff);
    local valueNum = max(0, base + posBuff + negBuff);
    CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ATTACK_POWER, valueText, false, valueNum);
	statFrame.tooltip = tooltipText;
    statFrame.tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, base/ATTACK_POWER_MAGIC_NUMBER);
    statFrame:Show();
end

-- SECONDARY STATS --
function CSC_PaperDollFrame_SetCritChance(statFrame, unit, category)
    local critChance;

    if category == PLAYERSTAT_MELEE_COMBAT then
        critChance = GetCritChance();
	elseif category == PLAYERSTAT_RANGED_COMBAT then
		if not IsRangedWeapon() then
			CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_CRITICAL_STRIKE, NOT_APPLICABLE, false, 0);
			statFrame:Show();
			return;
		end
        critChance = GetRangedCritChance();
    end

    CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_CRITICAL_STRIKE, critChance, true, critChance);
	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE).." "..format("%.2F%%", critChance);
    statFrame:Show();
end

function CSC_PaperDollFrame_SetSpellCritChance(statFrame, unit)

	statFrame:SetScript("OnEnter", CSC_CharacterSpellCritFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)
	
	local MAX_SPELL_SCHOOLS = 7;
	local holySchool = 2;

	-- Start at 2 to skip physical damage
	local maxSpellCrit = GetSpellCritChance(holySchool);
	for i=holySchool, MAX_SPELL_SCHOOLS do
		local bonusCrit = GetSpellCritChance(i);
		maxSpellCrit = max(maxSpellCrit, bonusCrit);
	end

	statFrame.holyCrit = GetSpellCritChance(2);
	statFrame.fireCrit = GetSpellCritChance(3);
	statFrame.natureCrit = GetSpellCritChance(4);
	statFrame.frostCrit = GetSpellCritChance(5);
	statFrame.shadowCrit = GetSpellCritChance(6);
	statFrame.arcaneCrit = GetSpellCritChance(7);

	local unitClassLoc = select(2, UnitClass(unit));
	if (unitClassLoc == "MAGE") then
		local arcaneInstabilityCrit, criticalMassCrit = CSC_GetMageCritStatsFromTalents();
		if (arcaneInstabilityCrit > 0) then
			-- increases the crit of all spell schools
			statFrame.holyCrit = statFrame.holyCrit + arcaneInstabilityCrit;
			statFrame.fireCrit = statFrame.fireCrit + arcaneInstabilityCrit;
			statFrame.natureCrit = statFrame.natureCrit + arcaneInstabilityCrit;
			statFrame.frostCrit = statFrame.frostCrit + arcaneInstabilityCrit;
			statFrame.shadowCrit = statFrame.shadowCrit + arcaneInstabilityCrit;
			statFrame.arcaneCrit = statFrame.arcaneCrit + arcaneInstabilityCrit;
			-- set the new maximum
			maxSpellCrit = maxSpellCrit + arcaneInstabilityCrit;
		end
		if (criticalMassCrit > 0) then
			statFrame.fireCrit = statFrame.fireCrit + criticalMassCrit;
			-- set the new maximum
			maxSpellCrit = max(maxSpellCrit, statFrame.fireCrit);
		end
	elseif (unitClassLoc == "PRIEST") then
		local priestHolyCrit = CSC_GetPriestCritStatsFromTalents();
		if (priestHolyCrit > 0) then
			statFrame.holyCrit = statFrame.holyCrit + priestHolyCrit;
			-- set the new maximum
			maxSpellCrit = max(maxSpellCrit, statFrame.holyCrit);
		end
	elseif (unitClassLoc == "PALADIN") then
		local paladinHolyCrit = CSC_GetPaladinCritStatsFromTalents();
		if (paladinHolyCrit > 0) then
			statFrame.holyCrit = statFrame.holyCrit + paladinHolyCrit;
			-- set the new maximum
			maxSpellCrit = max(maxSpellCrit, statFrame.holyCrit);
		end
	end

	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_CRITICAL_STRIKE, maxSpellCrit, true, maxSpellCrit);

    statFrame:Show();
end

function CSC_PaperDollFrame_SetHitChance(statFrame, unit)
	local hitChance = GetHitModifier();
	
	if not hitChance then
		hitChance = 0;
	end

	local hitChanceText = hitChance;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, hitChanceText, true, hitChance);
	statFrame.tooltip = STAT_HIT_CHANCE.." "..hitChanceText;
	statFrame.tooltip2 = format(CR_HIT_MELEE_TOOLTIP, UnitLevel(unit), hitChance);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetRangedHitChance(statFrame, unit)
	
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, NOT_APPLICABLE, false, 0);
		statFrame:Show();
		return;
	end
	
	local hitChance = GetHitModifier();
	
	if not hitChance then
		hitChance = 0;
	end

	local hitChanceText = hitChance;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, hitChanceText, true, hitChance);
	statFrame.tooltip = STAT_HIT_CHANCE.." "..hitChanceText;
	statFrame.tooltip2 = format(CR_HIT_RANGED_TOOLTIP, UnitLevel(unit), hitChance);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetSpellHitChance(statFrame, unit)
	local hitChance = GetSpellHitModifier();
	
	if not hitChance then
		hitChance = 0;
	end

	local hitChanceText = hitChance;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, hitChanceText, true, hitChance);
	statFrame.tooltip = STAT_HIT_CHANCE.." "..hitChanceText;
	statFrame.tooltip2 = format(CR_HIT_SPELL_TOOLTIP, UnitLevel(unit), hitChance);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetAttackSpeed(statFrame, unit)
	local speed, offhandSpeed = UnitAttackSpeed(unit);
	local speedLabel = WEAPON_SPEED;

	local displaySpeed = format("%.2F", speed);
	if ( offhandSpeed ) then
		offhandSpeed = format("%.2F", offhandSpeed);
	end
	if ( offhandSpeed ) then
		displaySpeed =  displaySpeed.." / ".. offhandSpeed;
	else
		displaySpeed =  displaySpeed;
	end
	CSC_PaperDollFrame_SetLabelAndText(statFrame, speedLabel, displaySpeed, false, speed);
	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED).." "..displaySpeed;
	statFrame:Show();
end

function CSC_PaperDollFrame_SetRangedAttackSpeed(statFrame, unit)
	
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, NOT_APPLICABLE, false, 0);
		statFrame:Show();
		return;
	end

	local attackSpeed, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
	local displaySpeed = format("%.2F", attackSpeed);

	CSC_PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, displaySpeed, false, attackSpeed);
	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED).." "..displaySpeed;
	statFrame:Show();
end

-- DEFENSES --
function CSC_PaperDollFrame_SetArmor(statFrame, unit)

	local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor(unit);
	--negBuff = 0; -- Remove for Classic

	if (unit ~= "player") then
		--[[ In 1.12.0, UnitArmor didn't report positive / negative buffs for units that weren't the active player.
			 This hack replicates that behavior for the UI. ]]
		base = effectiveArmor;
		armor = effectiveArmor;
		posBuff = 0;
		negBuff = 0;
	end

	local playerLevel = UnitLevel(unit);
	local armorReduction = effectiveArmor/((85 * playerLevel) + 400);
	armorReduction = 100 * (armorReduction/(armorReduction + 1));

	local valueText, tooltipText = CSC_PaperDollFormatStat(ARMOR, base, posBuff, negBuff);
	local valueNum = max(0, base + posBuff + negBuff);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ARMOR, valueText, false, valueNum);
	statFrame.tooltip = tooltipText;
    statFrame.tooltip2 = format(ARMOR_TOOLTIP, playerLevel, armorReduction);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetDefense(statFrame, unit)

	local numSkills = GetNumSkillLines();
	local skillIndex = 0;
	local x = 0;
	for i = 1, numSkills do
		local skillName = select(1, GetSkillLineInfo(i));

		if (skillName == DEFENSE) then
			if (x == 0) then
				x = 1;
			else
				skillIndex = i;
				break;
			end
		end
	end

	local skillRank, skillModifier;
	if (skillIndex > 0) then
		skillRank = select(4, GetSkillLineInfo(skillIndex));
		skillModifier = select(6, GetSkillLineInfo(skillIndex));
	else
		-- Use this as a backup, just in case something goes wrong
		skillRank, skillModifier = UnitDefense(unit); --Not working properly
	end

	local posBuff = 0;
	local negBuff = 0;
	if ( skillModifier > 0 ) then
		posBuff = skillModifier;
	elseif ( skillModifier < 0 ) then
		negBuff = skillModifier;
	end
	local valueText, tooltipText = CSC_PaperDollFormatStat(DEFENSE_COLON, skillRank, posBuff, negBuff);
	local valueNum = max(0, skillRank + posBuff + negBuff);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, DEFENSE, valueText, false, valueNum);
	statFrame.tooltip = tooltipText;
	tooltipText = format(DEFAULT_STATDEFENSE_TOOLTIP, valueNum, 0, valueNum*0.04, valueNum*0.04);
	tooltipText = tooltipText:gsub('.-\n', '', 1);
	tooltipText = tooltipText:gsub('%b()', '');
	statFrame.tooltip2 = tooltipText;
	statFrame:Show();
end

function CSC_PaperDollFrame_SetDodge(statFrame, unit)
	local chance = GetDodgeChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_DODGE, chance, true, chance);
	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE).." "..string.format("%.2F", chance).."%";
	--statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));
	statFrame:Show();
end

function CSC_PaperDollFrame_SetParry(statFrame, unit)
	local chance = GetParryChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_PARRY, chance, true, chance);
	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE).." "..string.format("%.2F", chance).."%";
	--statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));
	statFrame:Show();
end

local function CSC_PaperDollFrame_GetArmorReduction(armor, attackerLevel)
	return C_PaperDollInfo.GetArmorEffectiveness(armor, attackerLevel) * 100;
end

local function CSC_PaperDollFrame_GetArmorReductionAgainstTarget(armor)
	local armorEffectiveness = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(armor);
	if ( armorEffectiveness ) then
		return armorEffectiveness * 100;
	end
end

function CSC_PaperDollFrame_SetBlock(statFrame, unit)
	local chance = GetBlockChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_BLOCK, chance, true, chance);
	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE).." "..string.format("%.2F", chance).."%";
	
	--[[
	local shieldBlockArmor = GetShieldBlock();
	local blockArmorReduction = CSC_PaperDollFrame_GetArmorReduction(shieldBlockArmor, UnitEffectiveLevel(unit));
	local blockArmorReductionAgainstTarget = CSC_PaperDollFrame_GetArmorReductionAgainstTarget(shieldBlockArmor);

	statFrame.tooltip2 = CR_BLOCK_TOOLTIP:format(blockArmorReduction);
	if (blockArmorReductionAgainstTarget) then
		--statFrame.tooltip3 = format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget);
	else
		statFrame.tooltip3 = nil;
	end
	--]]

	statFrame:Show();
end

function CSC_PaperDollFrame_SetStagger(statFrame, unit)
	local stagger, staggerAgainstTarget = C_PaperDollInfo.GetStaggerPercentage(unit);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_STAGGER, stagger, true, stagger);

	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAGGER).." "..string.format("%.2F%%",stagger);
	statFrame.tooltip2 = format(STAT_STAGGER_TOOLTIP, stagger);
	if (staggerAgainstTarget) then
		statFrame.tooltip3 = format(STAT_STAGGER_TARGET_TOOLTIP, staggerAgainstTarget);
	else
		statFrame.tooltip3 = nil;
	end

	statFrame:Show();
end

-- SPELL --
function CSC_PaperDollFrame_SetSpellPower(statFrame, unit)

	statFrame:SetScript("OnEnter", CSC_CharacterSpellDamageFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)

	local MAX_SPELL_SCHOOLS = 7;
	local holySchool = 2;

	-- Start at 2 to skip physical damage
	local maxSpellDmg = GetSpellBonusDamage(holySchool);
	for i=holySchool, MAX_SPELL_SCHOOLS do
		local bonusDamage = GetSpellBonusDamage(i);
		maxSpellDmg = max(maxSpellDmg, bonusDamage);
	end

	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_SPELLPOWER, BreakUpLargeNumbers(maxSpellDmg), false, maxSpellDmg);
	statFrame.holyDmg = GetSpellBonusDamage(2);
	statFrame.fireDmg = GetSpellBonusDamage(3);
	statFrame.natureDmg = GetSpellBonusDamage(4);
	statFrame.frostDmg = GetSpellBonusDamage(5);
	statFrame.shadowDmg = GetSpellBonusDamage(6);
	statFrame.arcaneDmg = GetSpellBonusDamage(7);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetManaRegen(statFrame, unit)

	if ( not UnitHasMana(unit) ) then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, MANA_REGEN, NOT_APPLICABLE, false, 0);
		statFrame.tooltip = nil;
		statFrame:Show();
		return;
	end

	local base, combat = GetManaRegen();
	
	-- All mana regen stats are displayed as mana/5 sec.
	base = floor(base * 5.0);
	combat = floor(combat * 5.0);
	local baseText = BreakUpLargeNumbers(base);
	local combatText = BreakUpLargeNumbers(combat);
	-- Combat mana regen is most important to the player, so we display it as the main value
	CSC_PaperDollFrame_SetLabelAndText(statFrame, MANA_REGEN, combatText, false, combat);
	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MANA_REGEN) .. " " .. combatText;
	-- Base (out of combat) regen is displayed only in the subtext of the tooltip
	statFrame.tooltip2 = format(MANA_REGEN_TOOLTIP, baseText);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetHealing(statFrame, unit)
	local healing = GetSpellBonusHealing();
	local healingText = healing;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_SPELLHEALING, healingText, false, healing);
	statFrame.tooltip = STAT_SPELLHEALING.." "..healing;
	statFrame.tooltip2 = STAT_SPELLHEALING_TOOLTIP;
	statFrame:Show();
end

-- OnEnter Tooltip functions
function CSC_CharacterDamageFrame_OnEnter(self)
	-- Main hand weapon
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(self.TooltipMainTxt, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2F", self.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(DAMAGE_COLON, self.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1F", self.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(ATTACK_TOOLTIP..":", self.attackRating, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	-- Check for offhand weapon
	if ( self.offhandAttackSpeed ) then
		GameTooltip:AddLine(" "); -- Blank line.
		GameTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2F", self.offhandAttackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(DAMAGE_COLON, self.offhandDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1F", self.offhandDps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	GameTooltip:Show();
end

function CSC_CharacterSpellDamageFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(STAT_SPELLPOWER, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(STAT_SPELLPOWER_TOOLTIP);
	GameTooltip:AddLine(" "); -- Blank line.
	GameTooltip:AddDoubleLine(SPELL_SCHOOL1_CAP.." "..DAMAGE..": ", format("%.2F", self.holyDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL2_CAP.." "..DAMAGE..": ", format("%.2F", self.fireDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL4_CAP.." "..DAMAGE..": ", format("%.2F", self.frostDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL6_CAP.." "..DAMAGE..": ", format("%.2F", self.arcaneDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL5_CAP.." "..DAMAGE..": ", format("%.2F", self.shadowDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL3_CAP.." "..DAMAGE..": ", format("%.2F", self.natureDmg), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:Show();
end

function CSC_CharacterSpellCritFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(STAT_CRITICAL_STRIKE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine(" "); -- Blank line.
	GameTooltip:AddDoubleLine(SPELL_SCHOOL1_CAP.." "..CRIT_ABBR..": ", format("%.2F", self.holyCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL2_CAP.." "..CRIT_ABBR..": ", format("%.2F", self.fireCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL4_CAP.." "..CRIT_ABBR..": ", format("%.2F", self.frostCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL6_CAP.." "..CRIT_ABBR..": ", format("%.2F", self.arcaneCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL5_CAP.." "..CRIT_ABBR..": ", format("%.2F", self.shadowCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(SPELL_SCHOOL3_CAP.." "..CRIT_ABBR..": ", format("%.2F", self.natureCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:Show();
end
-- OnEnter Tooltip functions END
