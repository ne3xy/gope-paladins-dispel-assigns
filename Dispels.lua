local addonName, addon = ...

addon.dispellers = {}
addon.dispels = {}
addon.myIndex = nil
addon.dispelStatus = {}
local pendingDispels = {}

local function scheduleTimer()
    C_Timer.After(0.01, function()
            addon:processPending()
        end)
end

function addon:processPending()
    local sorted = {}
    for id, info in pairs(pendingDispels) do
        table.insert(sorted, info)
    end
    table.sort(sorted, function(a,b) return a.unit < b.unit end)
    for _, info in ipairs(sorted) do
        table.insert(addon.dispels, info)
    end
    pendingDispels = {}
end

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
        if instanceId and addon.dispelStatus[instanceId] == nil then
            -- print("Adding dispel by full update for unit " .. unit .. " with instance ID " .. instanceId)
            pendingDispels[instanceId] = {
                unit = unit,
                auraInstanceID = instanceId
            }
            addon.dispelStatus[instanceId] = false
            scheduleTimer()
            changed = true
        end
    end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            local instanceId = addon:IsPlusHasDispellableAura(aura, unit)
            if instanceId then
                if addon.dispelStatus[instanceId] == nil then
                    -- print("Adding dispel by added aura for unit " .. unit .. " with instance ID " .. instanceId)
                    pendingDispels[instanceId] = {
                        unit = unit,
                        auraInstanceID = instanceId
                    }
                    addon.dispelStatus[instanceId] = false
                    scheduleTimer()
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
                if addon.dispelStatus[instanceId] == false then
                    -- print("Marking dispel as dispelled for unit " .. unit .. " with instance ID " .. instanceId)
                    addon.dispelStatus[instanceId] = true
                    changed = true
                end
            end
        end
    end
    return changed
end