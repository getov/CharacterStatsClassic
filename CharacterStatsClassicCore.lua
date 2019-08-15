-- Access the namespace
local _, core = ...;

local characterStatsClassicEventFrame = CreateFrame("Frame");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
characterStatsClassicEventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED");
characterStatsClassicEventFrame:RegisterEvent("UNIT_MODEL_CHANGED");
characterStatsClassicEventFrame:RegisterEvent("UNIT_LEVEL");
characterStatsClassicEventFrame:RegisterEvent("UNIT_STATS");
characterStatsClassicEventFrame:RegisterEvent("UNIT_RANGEDDAMAGE");
characterStatsClassicEventFrame:RegisterEvent("UNIT_ATTACK_POWER");
characterStatsClassicEventFrame:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
characterStatsClassicEventFrame:RegisterEvent("UNIT_ATTACK");
characterStatsClassicEventFrame:RegisterEvent("UNIT_SPELL_HASTE");
characterStatsClassicEventFrame:RegisterEvent("UNIT_RESISTANCES");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_GUILD_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("SKILL_LINES_CHANGED");
characterStatsClassicEventFrame:RegisterEvent("COMBAT_RATING_UPDATE");
--characterStatsClassicEventFrame:RegisterEvent("MASTERY_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("SPEED_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("LIFESTEAL_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("AVOIDANCE_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("KNOWN_TITLES_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("UNIT_NAME_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("BAG_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
characterStatsClassicEventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
characterStatsClassicEventFrame:RegisterUnitEvent("UNIT_DAMAGE", "player");
characterStatsClassicEventFrame:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player");
characterStatsClassicEventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "player");
characterStatsClassicEventFrame:RegisterUnitEvent("UNIT_AURA", "player");
characterStatsClassicEventFrame:RegisterEvent("SPELL_POWER_CHANGED");
characterStatsClassicEventFrame:RegisterEvent("CHARACTER_ITEM_FIXUP_NOTIFICATION");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");

characterStatsClassicEventFrame:SetScript("OnEvent",
    function(self, event, ...)
        --print(event);
        core.UIConfig:UpdateStats();
    end)