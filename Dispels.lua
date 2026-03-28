local addonName, addon = ...

addon.dispellers = {}
addon.dispels = {}
addon.myIndex = nil
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
                if UnitIsUnit(unit, "player") then
                    addon.myIndex = #addon.dispellers
                end
            end

            if class == "WARLOCK" then
                local spec = GetInspectSpecialization(unit)
                if spec then
                    local _, specName = GetSpecializationInfoByID(spec)
                    if specName == "Affliction" or specName == "Destruction" then
                        table.insert(addon.dispellers, unit)
                        if UnitIsUnit(unit, "player") then
                            addon.myIndex = #addon.dispellers
                        end
                    end
                end
            end
        end
    end
end


function addon:HandleAuraUpdate(unitToken, updateInfo)
    local raidIndex = UnitInRaid(unitToken)
    if not raidIndex then return end
    -- I suspect this method of getting raidId is causing taint but I'm ignoring it.
    local unit = "raid" .. raidIndex
    local changed = false

    if updateInfo.isFullUpdate then
        local instanceId = addon:HasDispellableAura(unit)
        if instanceId and not instanceIdToDispel[instanceId] then
            print("Adding dispel by full update for unit " .. unit .. " with instance ID " .. instanceId)
            table.insert(addon.dispels, {
                unit = unit,
                auraInstanceID = instanceId,
                dispelled = false
            })
            instanceIdToDispel[instanceId] = #addon.dispels
            changed = true
        end
    end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            local instanceId = addon:IsPlusHasDispellableAura(aura, unit)
            if instanceId then
                if not instanceIdToDispel[instanceId] then
                    print("Adding dispel by added aura for unit " .. unit .. " with instance ID " .. instanceId)
                    table.insert(addon.dispels, {
                        unit = unit,
                        auraInstanceID = instanceId,
                        dispelled = false
                    })
                    instanceIdToDispel[instanceId] = #addon.dispels
                end
                changed = true
            end
        end
    end

    -- not handling updatedAuras

    if updateInfo.removedAuraInstanceIDs then
        for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
            if auraInstanceID ~= nil then
                local instanceId = addon:InstanceIdForUnit(unit, auraInstanceID)
                local dispelIndex = instanceIdToDispel[instanceId]
                if dispelIndex and addon.dispels[dispelIndex] then
                    print("Marking dispel as dispelled for unit " .. unit .. " with instance ID " .. instanceId)
                    addon.dispels[dispelIndex].dispelled = true
                    instanceIdToDispel[instanceId] = nil
                    changed = true
                end
            end
        end
    end
    return changed
end