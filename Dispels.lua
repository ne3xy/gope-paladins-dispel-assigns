local addonName, addon = ...

addon.dispellers = {}
addon.dispels = {}
local instanceIdToDispel = {}

function addon:InitDispellers()
    addon.dispellers = {}

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


function addon:HandleAuraUpdate(unit, updateInfo)
    if not UnitInRaid(unit) then return end
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
            if addon:IsDispellableAura(aura) then
                print("Added dispellable aura with instance ID:", aura.auraInstanceID)
                 table.insert(addon.dispels, {
                    unit = unit,
                    auraInstanceID = aura.auraInstanceID,
                    dispelled = false
                })
                instanceIdToDispel[aura.auraInstanceID] = #addon.dispels
                changed = true
            end
        end
    end

    -- 2. updated auras (need lookup) -------should be NOOP
    -- if updateInfo.updatedAuraInstanceIDs then
    --     for _, auraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
    --         local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
    --         if addon:IsDispellableAura(aura) then
    --             addon.dispels[unit] = true
    --             return
    --         end
    --     end
    -- end

    -- 3. removals → re-check this unit only
    if updateInfo.removedAuraInstanceIDs then
        for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
            print("Removed dispellable aura with instance ID:", auraInstanceID)
            local dispelIndex = instanceIdToDispel[auraInstanceID]
            if dispelIndex and addon.dispels[dispelIndex] then
                addon.dispels[dispelIndex][dispelled] = true
                instanceIdToDispel[auraInstanceID] = nil
                changed = true
            end
        end
    end
    return changed
end