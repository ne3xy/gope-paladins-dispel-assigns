local addonName, addon = ...
local LGF = LibStub("LibGetFrame-1.0")
local LCG = LibStub("LibCustomGlow-1.0")

-- addon.ui = CreateFrame("Frame", "GopePaladinDispelDebugFrame", UIParent, "BackdropTemplate")
-- addon.ui:SetSize(300, 400)
-- addon.ui:SetPoint("CENTER")
-- addon.ui:SetMovable(true)
-- addon.ui:EnableMouse(true)
-- addon.ui:RegisterForDrag("LeftButton")
-- addon.ui:SetScript("OnDragStart", addon.ui.StartMoving)
-- addon.ui:SetScript("OnDragStop", addon.ui.StopMovingOrSizing)

-- addon.ui:SetBackdrop({
--     bgFile = "Interface/Tooltips/UI-Tooltip-Background",
--     edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
--     tile = true, tileSize = 16, edgeSize = 12,
--     insets = { left = 4, right = 4, top = 4, bottom = 4 }
-- })
-- addon.ui:SetBackdropColor(0, 0, 0, 0.8)
-- addon.ui:Hide()

-- addon.ui.rows = {}

function addon:RenderUI()
    -- local frame = addon.ui

    -- -- clear old rows
    -- for _, row in ipairs(frame.rows) do
    --     row:Hide()
    -- end

    -- frame.rows = {}

    -- local yOffset = -10
    -- local index = 1

    -- for dispellerIndex, dispellerUnit in pairs(addon.dispellers or {}) do
    --     local dispellerName = UnitName(dispellerUnit)

    --     -- create row frame
    --     local row = CreateFrame("Frame", nil, frame)
    --     row:SetSize(280, 20)
    --     row:SetPoint("TOPLEFT", 10, yOffset)

    --     local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     text:SetPoint("LEFT")

    --     -- find assignment(s)
    --     local assignedTargets = {}

    --     for dispelIndex, dispelInfo in pairs(addon.dispels or {}) do
    --         local assignedDispellerIndex = ((dispelIndex - 1) % #addon.dispellers) + 1
    --         local assignedDispeller = addon.dispellers[assignedDispellerIndex]

    --         if assignedDispeller == dispellerUnit then
    --             local dispel = addon.dispels[dispelIndex]
    --             table.insert(assignedTargets, dispel.auraInstanceID .. (addon.dispelStatus[dispel.auraInstanceID] and " (dispelled)" or "()"))
    --         end
    --     end

    --     local assignmentText = #assignedTargets > 0 and table.concat(assignedTargets, ", ") or "—"

    --     text:SetText(dispellerName .. ": " .. assignmentText)

    --     table.insert(frame.rows, row)

    --     yOffset = yOffset - 22
    --     index = index + 1
    -- end
    -- frame:Show()
end

function addon:HideUI()
    -- addon.ui:Hide()
end

local glowedFrames = {}
function addon:UpdateGlows()
    if (addon.myIndex == nil) then return end
    local numDispellers = #addon.dispellers or 1
    local found = false
    local n = addon.myIndex
    while (n <= #addon.dispels and not found) do
        local dispelInfo = addon.dispels[n]
        if dispelInfo then
            local frame = LGF.GetUnitFrame(dispelInfo.unit)
            if not frame then print("Frame not found for unit: " .. dispelInfo.unit); return end
            if addon.dispelStatus[dispelInfo.auraInstanceID] == false then
                glowedFrames[frame] = true
                LCG.ButtonGlow_Start(frame)
                found = true
                break
            else            
                LCG.ButtonGlow_Stop(frame)
                glowedFrames[frame] = nil
            end
        end
        n = n + numDispellers
    end
end

function addon:StopAllGlows()
    for frame, _ in pairs(glowedFrames) do
        LCG.ButtonGlow_Stop(frame)
    end
    glowedFrames = {}
end