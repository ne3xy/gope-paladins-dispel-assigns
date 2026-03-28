local addonName, addon = ...

function addon:IsPlusHasDispellableAura(aura, unit)
    if aura and aura.dispelName then
        return addon:HasDispellableAura(unit)
    end
    return nil
end

function addon:HasDispellableAura(unit) 
    local auras = C_UnitAuras.GetUnitAuras(unit, "HARMFUL")
    if not auras then return nil end

    for _, aura in ipairs(auras) do
        if aura.dispelName then
            print("Found " .. unit .. " IID: " .. aura.auraInstanceID .. " - " .. (aura.name or "unknown"))
            return addon:InstanceIdForUnit(unit, aura.auraInstanceID)
        end
    end

    return nil
end

function addon:InstanceIdForUnit(unit, instanceId)
    return unit .. "-" .. instanceId
end