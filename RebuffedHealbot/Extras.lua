local addonName, addon = ...
local S = addon.suite
local previews, previewCount, previewRoot = {}, 0, nil
local function preview()
    if previewCount == 0 or not previewRoot then return end
    local p = S.db.profiles[S.editProfile or S.GroupType()]
    local columns = math.ceil(previewCount / 5)
    local widthCount, heightCount = columns, 5
    if p.vertical then widthCount, heightCount = heightCount, widthCount end
    previewRoot:SetSize(widthCount * (p.width + 4) + 16, heightCount * (p.height + 3) + 46)
    previewRoot:SetScale(math.min(p.scale, (UIParent:GetWidth() - 50) / previewRoot:GetWidth()))
    previewRoot.label:SetText("PREVIEW - " .. previewCount)
    for i = 1, 40 do
        local b = previews[i]
        if not b then
            b = CreateFrame("Frame", nil, previewRoot, S.modern and "BackdropTemplate" or nil)
            b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
            b:SetBackdropBorderColor(.2, .3, .4, 1)
            b.health = CreateFrame("StatusBar", nil, b); b.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8"); b.health:SetAllPoints(); b.health:SetMinMaxValues(0, 100)
            b.text = b.health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); b.text:SetPoint("TOPLEFT", 4, -4)
            previews[i] = b
        end
        b:SetSize(p.width, p.height); b:ClearAllPoints()
        local column, row = math.floor((i - 1) / 5), (i - 1) % 5
        if p.vertical then column, row = row, column end
        local xSign = p.grow:find("RIGHT", 1, true) and -1 or 1
        local ySign = p.grow:find("BOTTOM", 1, true) and 1 or -1
        b:SetPoint(p.grow, previewRoot, p.grow, xSign * (8 + column * (p.width + 4)), ySign * ((ySign == 1 and 8 or 40) + row * (p.height + 3)))
        b.health:SetValue(25 + i * 17 % 75)
        local colors = {{.2, .8, .35}, {.4, .6, 1}, {1, .7, .2}, {.9, .35, .4}}
        b.health:SetStatusBarColor(unpack(colors[i % 4 + 1])); b.text:SetText("Preview " .. i .. "  " .. (25 + i * 17 % 75) .. "%")
        if i <= previewCount then b:Show() else b:Hide() end
    end
    previewRoot:Show()
end
function S.Preview()
    if not previewRoot then
        previewRoot = CreateFrame("Frame", addonName .. "SuitePreview", UIParent)
        previewRoot:SetPoint("CENTER"); previewRoot:SetFrameStrata("DIALOG"); previewRoot:SetClampedToScreen(true)
        previewRoot:SetMovable(true); previewRoot:EnableMouse(true); previewRoot:RegisterForDrag("LeftButton")
        previewRoot:SetScript("OnDragStart", previewRoot.StartMoving); previewRoot:SetScript("OnDragStop", previewRoot.StopMovingOrSizing)
        previewRoot.label = previewRoot:CreateFontString(nil, "OVERLAY", "GameFontNormal"); previewRoot.label:SetPoint("TOPLEFT", 8, -8)
        local close = CreateFrame("Button", nil, previewRoot, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT"); close:SetScript("OnClick", function() previewCount = 0; previewRoot:Hide() end)
    end
    previewCount = previewCount == 0 and 5 or previewCount == 5 and 10 or previewCount == 10 and 20 or previewCount == 20 and 40 or 5
    preview()
end
local nativeFrames = {}
local function nativeVisibility()
    if InCombatLockdown() then return end
    for _, name in ipairs({"PartyFrame", "CompactPartyFrame", "CompactRaidFrameContainer", "PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4"}) do
        local frame = _G[name]
        if frame then
            if S.db.hideBlizzard and S.root:IsShown() then
                if nativeFrames[frame] == nil then nativeFrames[frame] = frame:IsShown() end
                RegisterStateDriver(frame, "visibility", "hide")
            elseif nativeFrames[frame] ~= nil then
                UnregisterStateDriver(frame, "visibility")
                if nativeFrames[frame] then frame:Show() else frame:Hide() end
                nativeFrames[frame] = nil
            end
        end
    end
end
local function welcome()
    if S.db.welcomed then return end
    local w = CreateFrame("Frame", addonName .. "Welcome", UIParent, S.modern and "BackdropTemplate" or nil)
    w:SetSize(390, 145); w:SetPoint("TOP", 0, -100); w:SetFrameStrata("DIALOG")
    w:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16})
    local text = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 16, -16); text:SetPoint("TOPRIGHT", -16, -16)
    text:SetText(S.Text("RebuffedHealbot\nKlicke einen Spieler zum Heilen.\n/rhb \195\182ffnet Klicks, Tasten, Buffs und Layouts.\nDein eigener Frame ist mit einem Pfeil markiert.", "RebuffedHealbot\nClick a player to heal.\n/rhb opens clicks, keys, buffs and layouts.\nAn arrow marks your own frame."))
    local arrow
    for _, button in ipairs(S.buttons) do
        if UnitExists(button.unit) and UnitIsUnit(button.unit, "player") then
            arrow = button:CreateTexture(nil, "OVERLAY"); arrow:SetTexture("Interface\\TUTORIALFRAME\\UI-TutorialFrame-CalloutArrow-Up")
            arrow:SetSize(24, 32); arrow:SetPoint("TOP", button, "BOTTOM", 0, -3); break
        end
    end
    local close = CreateFrame("Button", nil, w, "UIPanelButtonTemplate"); close:SetSize(120, 22); close:SetPoint("BOTTOM", 0, 12); close:SetText(S.Text("Verstanden", "Got it"))
    close:SetScript("OnClick", function() S.db.welcomed = true; w:Hide(); if arrow then arrow:Hide() end end)
end
local function manaCost(spell)
    if not S.Safe(spell) or not spell then return end
    if S.modern then
        local costs = C_Spell.GetSpellPowerCost(spell)
        for _, cost in ipairs(costs or {}) do if S.Safe(cost.type) and cost.type == 0 and S.Safe(cost.cost) then return cost.cost end end
    else local _, _, _, cost, _, power = GetSpellInfo(spell); if power == 0 then return cost end end
end
local function costOverlay(button)
    if button.costOverlay then return end
    local overlay = CreateFrame("StatusBar", nil, button.power)
    overlay:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8"); overlay:SetStatusBarColor(.7, .8, 1, .7)
    if overlay.SetReverseFill then overlay:SetReverseFill(true) end
    overlay:SetPoint("RIGHT", button.power:GetStatusBarTexture(), "RIGHT", 0, 0); overlay:SetSize(button:GetWidth() - 2, 6); overlay:Hide()
    if button.power.SetClipsChildren then button.power:SetClipsChildren(true) end
    button.costOverlay = overlay
    button.fiveSecond = button:CreateTexture(nil, "OVERLAY"); button.fiveSecond:SetTexture("Interface\\Buttons\\WHITE8X8"); button.fiveSecond:SetVertexColor(.3, .6, 1, 1)
    button.fiveSecond:SetHeight(2); button.fiveSecond:SetPoint("BOTTOMLEFT"); button.fiveSecond:SetPoint("BOTTOMRIGHT"); button.fiveSecond:Hide()
end
function S.ExtrasInit()
    for _, button in ipairs(S.buttons) do costOverlay(button) end
    local toggle = CreateFrame("Button", addonName .. "SecureToggle", UIParent, "SecureHandlerClickTemplate")
    toggle:RegisterForClicks("AnyUp"); toggle:SetFrameRef("grid", S.root)
    toggle:SetAttribute("_onclick", [[ local grid = self:GetFrameRef("grid"); if grid:IsShown() then grid:Hide() else grid:Show() end ]])
    S.UpdateToggleKey = function()
        ClearOverrideBindings(toggle)
        if S.db.toggleKey ~= "" then SetOverrideBindingClick(toggle, true, S.db.toggleKey, toggle:GetName(), "LeftButton") end
    end
    S.UpdateToggleKey()
    if S.modern then
        local b = CreateFrame("Button", addonName .. "ForeverMinimap", Minimap)
        b:SetSize(28, 28); b:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
        local t = b:CreateTexture(nil, "ARTWORK"); t:SetTexture("Interface\\Icons\\Spell_Holy_Heal"); t:SetAllPoints()
        b:SetScript("OnClick", S.OpenSettings)
    end
    local function moved(self)
        if InCombatLockdown() then return end
        S.SavePosition(self)
    end
    S.root:HookScript("OnDragStop", moved)
    if EventRegistry then
        EventRegistry:RegisterCallback("EditMode.Enter", function() if not InCombatLockdown() then S.root:EnableMouse(true); S.Print(S.Text("RebuffedHealbot am Kopf verschieben. /rhb f\195\188r die Gr\195\182\195\159e.", "Drag the RebuffedHealbot header. Use /rhb to change size.")) end end, S)
    end
    local events = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "UPDATE_MACROS", "PLAYER_TARGET_CHANGED", "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UNIT_AURA", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED"}) do
        if S.modern and event:find("UNIT_SPELLCAST", 1, true) then events:RegisterUnitEvent(event, "player")
        else events:RegisterEvent(event) end
    end
    events:SetScript("OnEvent", function(self, event, unit, ...)
        if event == "UNIT_AURA" then
            if S.RefreshOwnBuffVisuals then S.RefreshOwnBuffVisuals() end
            if not S.modern then
                for _, b in ipairs(S.buttons) do if UnitExists(b.unit) and UnitIsUnit(b.unit, unit) then S.Auras(b) end end
            end
            if not InCombatLockdown() then S.After(S.UpdateQuickBuff) end
            return
        end
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
            if S.RefreshOwnBuffVisuals then S.RefreshOwnBuffVisuals() end
            if not InCombatLockdown() then S.After(S.UpdateQuickBuff) end
            return
        end
        if event == "PLAYER_REGEN_ENABLED" or event == "SPELLS_CHANGED" or event == "UPDATE_MACROS" then
            if not InCombatLockdown() then S.Apply(); nativeVisibility(); preview() end
        elseif event:find("UNIT_SPELLCAST", 1, true) and (S.modern or unit == "player") then
            local spell
            if S.modern then spell = select(2, ...) else spell = select(1, ...) end
            local cost = manaCost(spell)
            for _, b in ipairs(S.buttons) do
                local same = UnitExists(b.unit) and UnitIsUnit(b.unit, "player")
                if S.modern or same then
                    if S.modern then
                        b.costOverlay:SetAlphaFromBoolean(same, 1, 0)
                        b.fiveSecond:SetAlphaFromBoolean(same, 1, 0)
                    end
                    if event == "UNIT_SPELLCAST_START" and cost and cost > 0 and S.db.showManaCost then
                        if S.modern then b.costOverlay:SetMinMaxValues(0, UnitPowerMax("player", 0)); b.costOverlay:SetValue(cost)
                        else
                            local width = b.power:GetWidth() * math.min(cost, UnitPower("player", 0)) / math.max(1, UnitPowerMax("player", 0))
                            b.costOverlay:SetWidth(width); b.costOverlay:SetMinMaxValues(0, 1); b.costOverlay:SetValue(1)
                        end
                        b.costOverlay:Show()
                    else b.costOverlay:Hide() end
                    if event == "UNIT_SPELLCAST_SUCCEEDED" and cost and cost > 0 and S.db.showFiveSecond then
                        b.fiveSecond:Show()
                        S.Delay("fsr:" .. b.unit, 5, function() b.fiveSecond:Hide() end)
                    end
                end
            end
        else for _, b in ipairs(S.buttons) do if UnitExists(b.unit) then S.UpdateDisplay(b) end end end
    end)
    S.RefreshNativeFrames = nativeVisibility
    S.RefreshPreview = preview
    welcome(); nativeVisibility()
end
