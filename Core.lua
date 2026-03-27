-- namespace pattern (prevents global pollution)
local addonName, addon = ...

addon.frame = CreateFrame("Frame")

local TARGET_ENCOUNTER_ID = 3180
local active = false

-- event handler
addon.frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ENCOUNTER_START" then
        local encounterID = ...
        if encounterID == TARGET_ENCOUNTER_ID then
            active = true
            addon:InitDispellers()
            addon:RenderUI()
        end

    elseif event == "ENCOUNTER_END" then
        active = false
        addon:HideUI()
        addon:StopAllGlows()

    elseif event == "UNIT_AURA" and active then
        local changed = addon:HandleAuraUpdate(...)
        if changed then
            addon:RenderUI()
            addon:UpdateGlows()
        end
    end
end)

-- register events
addon.frame:RegisterEvent("ENCOUNTER_START")
addon.frame:RegisterEvent("ENCOUNTER_END")
addon.frame:RegisterEvent("UNIT_AURA")