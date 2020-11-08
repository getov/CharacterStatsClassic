-- Access the namespace
local _, core = ...;

local characterStatsClassicEventFrame = CreateFrame("Frame");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
characterStatsClassicEventFrame:RegisterEvent("UNIT_POWER_UPDATE");
characterStatsClassicEventFrame:RegisterEvent("UNIT_MODEL_CHANGED");
characterStatsClassicEventFrame:RegisterEvent("UNIT_AURA");
characterStatsClassicEventFrame:RegisterEvent("UNIT_LEVEL");
characterStatsClassicEventFrame:RegisterEvent("UNIT_STATS");
characterStatsClassicEventFrame:RegisterEvent("UNIT_DAMAGE");
characterStatsClassicEventFrame:RegisterEvent("UNIT_RANGEDDAMAGE");
characterStatsClassicEventFrame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
characterStatsClassicEventFrame:RegisterEvent("UNIT_ATTACK_SPEED");
characterStatsClassicEventFrame:RegisterEvent("UNIT_ATTACK_POWER");
characterStatsClassicEventFrame:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
characterStatsClassicEventFrame:RegisterEvent("UNIT_ATTACK");
characterStatsClassicEventFrame:RegisterEvent("SKILL_LINES_CHANGED");
characterStatsClassicEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");

characterStatsClassicEventFrame:SetScript("OnEvent",
    function(self, event, ...)
        C_Timer.After(0.5, function ()
            core.UIConfig:UpdateStats();
        end)
    end)