--[[
    Util functions specific for Classes
]]

-- returns additional crit % stats from Arcane instability and Critical Mass if any
function CSC_GetMageCritStatsFromTalents()

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
function CSC_GetPriestCritStatsFromTalents()
	
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
function CSC_GetPaladinCritStatsFromTalents()

	local holyPowerCrit = 0;
	local critTable = { 1, 2, 3, 4, 5 };

	-- Holy Power (1, 2, 3, 4, 5)%
	local spellRank = select(5, GetTalentInfo(1, 13));
	if (spellRank > 0) and (spellRank <= 5) then
		holyPowerCrit = critTable[spellRank];
    end

	return holyPowerCrit;
end

-- returns the defense bonus from the Anticipation Prot talent
local function CSC_GetPaladinDefenseFromTalents()

    local defense = 0;
    local defenseTable = { 2, 4, 6, 8, 10 };

    -- Anticipation (2, 4, 6, 8, 10)%
    local spellRank = select(5, GetTalentInfo(2, 9));
    if (spellRank > 0) and (spellRank <=5) then
        defense = defenseTable[spellRank];
    end

    return defense;
end

-- returns the defense bonus from the Anticipation Prot talent
local function CSC_GetWarriorDefenseFromTalents()
    
    local defense = 0;
    local defenseTable = { 2, 4, 6, 8, 10 };

    -- Anticipation (2, 4, 6, 8, 10)%
    local spellRank = select(5, GetTalentInfo(3, 2));
    if (spellRank > 0) and (spellRank <=5) then
		defense = defenseTable[spellRank];
	end

    return defense;
end

function CSC_GetDefenseFromTalents(unit)
    
    local defense = 0;
    local unitClassLoc = select(2, UnitClass(unit));

    if (unitClassLoc == "PALADIN") then
        defense = CSC_GetPaladinDefenseFromTalents();
    elseif (unitClassLoc == "WARRIOR") then
        defense = CSC_GetWarriorDefenseFromTalents();
    end

    return defense;
end

-- returns the shapeshift form index for druids
function CSC_GetShapeshiftForm()
	local shapeIndex = 0;

	for possibleForm=1, GetNumShapeshiftForms() do
		if select(2, GetShapeshiftFormInfo(possibleForm)) then
			shapeIndex = possibleForm;
		end
	end

	return shapeIndex;
end

function CSC_GetMP5ModifierFromTalents(unit)
    local unitClassId = select(3, UnitClass(unit));
	local spellRank = 0;

	if unitClassId == 5 then -- Priest
		-- Meditation
        spellRank = select(5, GetTalentInfo(1, 8));
	elseif unitClassId == 8 then -- Mage
		-- Arcane Meditation
        spellRank = select(5, GetTalentInfo(1, 12));
	elseif unitClassId == 11 then -- Druid
		-- Reflection
        spellRank = select(5, GetTalentInfo(3, 6));
	end
	
	local modifier = spellRank * 0.05;

    return modifier;
end

function CSC_GetMP5ModifierFromSetBonus(unit)
	local unitClassId = select(3, UnitClass(unit));
	local modifier = 0;
	
	-- not Druid (11) or Priest (5)
	if unitClassId ~= 11 and unitClassId ~= 5 then
		return modifier;
	end
	
	local firstItemslotIndex = 1;
	local lastItemslotIndex = 18;

	local vestmentsOfTranscendenceIDs = { [16925] = 16925, 
										  [16926] = 16926, 
										  [16919] = 16919, 
										  [16921] = 16921, 
										  [16920] = 16920, 
									   	  [16922] = 16922, 
										  [16924] = 16924, 
										  [16923] = 16923
										};

	local stormrageRaimentIDs = { [16897] = 16897, 
								  [16898] = 16898, 
								  [16899] = 16899, 
								  [16900] = 16900, 
								  [16901] = 16901, 
								  [16902] = 16902, 
								  [16903] = 16903, 
								  [16904] = 16904
								};

	local equippedSetItems = 0;
    for itemSlot = firstItemslotIndex, lastItemslotIndex do
        local itemId = GetInventoryItemID(unit, itemslot);
		
		if (itemId) then
			if (itemId == vestmentsOfTranscendenceIDs[itemId] or itemId == stormrageRaimentIDs[itemId]) then
				equippedSetItems = equippedSetItems + 1;
			end
		end
    end

    if equippedSetItems >= 3 then
        modifier = 0.15;
	end

    return modifier;
end
