local addonName, addon = ...

addon.dispellers = {}
addon.dispels = {}
local instanceIdToDispel = {}

function addon:InitDispellers()
    addon.dispellers = {}
    addon.dispels = {}

    for i = 1, GetNumGroupMembers() do
        local unit = (IsInRaid() and "raid"..i) or "party"..i

        if UnitExists(unit) then
            local role = UnitGroupRolesAssigned(unit)
            local class = select(2, UnitClass(unit))

            if role == "HEALER" then
                table.insert(addon.dispellers, unit)
            end

            if class == "WARLOCK" then
                local spec = GetInspectSpecialization(unit)
                if spec then
                    local _, specName = GetSpecializationInfoByID(spec)
                    if specName == "Affliction" or specName == "Destruction" then
                        table.insert(addon.dispellers, unit)
                    end
                end
            end
        end
    end
end


function addon:HandleAuraUpdate(unitToken, updateInfo)
    local raidIndex = UnitInRaid(unitToken)
    if not raidIndex then return end
    local unit = "raid" .. raidIndex
    local changed = false

    -- full resync (rare but important)
    if updateInfo.isFullUpdate then
        local instanceId = addon:HasDispellableAura(unit)
        if instanceId and not instanceIdToDispel[instanceId] then
            table.insert(addon.dispels, {
                unit = unit,
                auraInstanceID = instanceId,
                dispelled = false
            })
            instanceIdToDispel[instanceId] = #addon.dispels
            changed = true
        end
    end

    -- 1. added auras (already have full data)
    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if addon:IsDispellableAura(aura, unit) then
                if not instanceIdToDispel[aura.auraInstanceID] then
                    table.insert(addon.dispels, {
                        unit = unit,
                        auraInstanceID = aura.auraInstanceID,
                        dispelled = false
                    })
                    instanceIdToDispel[aura.auraInstanceID] = #addon.dispels
                end
                changed = true
            end
        end
    end

    -- 3. removals → re-check this unit only
    if updateInfo.removedAuraInstanceIDs then
        for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
            if auraInstanceId ~= nil then
                local dispelIndex = instanceIdToDispel[auraInstanceID]
                if dispelIndex and addon.dispels[dispelIndex] then
                    addon.dispels[dispelIndex][dispelled] = true
                    instanceIdToDispel[auraInstanceID] = nil
                    changed = true
                end
            end
        end
    end
    return changed
end