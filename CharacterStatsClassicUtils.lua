--[[
    Util functions that wrap my interface and the Blizzard's WoW Classic lua API code for ease of use
]]

--[[
	PaperDollFrame_SetPrimaryStats();
	PaperDollFrame_SetResistances();
	PaperDollFrame_SetArmor();
	PaperDollFrame_SetAttackBothHands();
	- DONE - PaperDollFrame_SetDamage();
	- DONE - PaperDollFrame_SetAttackPower();
	PaperDollFrame_SetRangedAttack();
	PaperDollFrame_SetRangedDamage();
	- DONE - PaperDollFrame_SetRangedAttackPower();
]]

local function DebugBreakPrint()
    print("ERROR");
end

local function CSC_GetAppropriateDamage(unit)
    --[[ TODO: Find a way to check if this is a ranged unit
    if IsRangedWeapon() then
		local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
		return minDamage, maxDamage, nil, nil, 0, 0, percent;
	else
		return UnitDamage(unit);
    end
    ]]
    return UnitDamage(unit);
end

local function CSC_PaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue)
	if ( statFrame.Label ) then
        statFrame.Label:SetText(format(STAT_FORMAT, label));
	end
	if ( isPercentage ) then
		text = format("%d%%", numericValue + 0.5);
	end
	statFrame.Value:SetText(text);
    statFrame.numericValue = numericValue;
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
		end
	end
    
    return effective, text;
end

function CSC_PaperDollFrame_SetDamage(statFrame, unit)

    statFrame:SetScript("OnEnter", CharacterDamageFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)

    local speed, offhandSpeed = UnitAttackSpeed(unit);
    local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = CSC_GetAppropriateDamage(unit);
    
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
    statFrame.unit = unit; -- not in classic

    -- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed ) then
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
    
	-- If no ranged attack then set to n/a
    if ( PaperDollFrame.noRanged ) then
        -- TODO: we need to set the label too
        statFrame.Value:SetText(NOT_APPLICABLE);
		statFrame.tooltip = nil;
		return;
	end
    if ( HasWandEquipped() ) then
        -- TODO: we need to set the label too
        statFrame.Value:SetText("--");
		statFrame.tooltip = nil;
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

function CSC_PaperDollFrame_SetCritChance(statFrame, unit, category)
    -- TODO: Maybe implement it differently (have to test when the game launches)
    -- Warning: For some reason these return the same value on retail.... will have to check on Classic
    local critChance;

    if category == "Melee" then
        critChance = GetCritChance();
    elseif category == "Ranged" then
        critChance = GetRangedCritChance();
    elseif category == "Spell" then
        critChance = GetSpellCritChance();
    end

    CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_CRITICAL_STRIKE, critChance, true, critChance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE).." "..format("%.2F%%", critChance)..FONT_COLOR_CODE_CLOSE;
    statFrame:Show();
end
