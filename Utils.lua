local addonName, addon = ...

function addon:IsDispellableAura(aura, unit)
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
            return aura.auraInstanceID
        end
    end

    return nil
end