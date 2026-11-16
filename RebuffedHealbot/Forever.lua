local addonName, addon = ...
local S = addon.suite
local eventFrame = CreateFrame("Frame")
local function refresh(button, aura)
    if not UnitExists(button.unit) then return end
    button.nameText:SetText(UnitName(button.unit))
    button.health:SetMinMaxValues(0, UnitHealthMax(button.unit)); button.health:SetValue(UnitHealth(button.unit))
    S.UpdateDisplay(button)
    if aura then S.Auras(button) end
    local inRange, checked = UnitInRange(button.unit)
    if not S.Safe(inRange) or S.Safe(checked) and checked then button:SetAlphaFromBoolean(inRange, 1, .4)
    elseif S.rangeSpell and C_Spell.IsSpellInRange then
        local range = C_Spell.IsSpellInRange(S.rangeSpell, button.unit)
        if S.Safe(range) and range == nil then button:SetAlpha(1) else button:SetAlphaFromBoolean(range, 1, .4) end
    else button:SetAlpha(1) end
end
local function unitButton(unit, condition, kind, owner)
    local b = CreateFrame("Button", addonName .. "_" .. unit, S.root, "SecureActionButtonTemplate,BackdropTemplate")
    b.unit, b.suiteKind, b.suiteOwner = unit, kind, owner
    b:SetSize(128, 52); b:SetAttribute("unit", unit)
    b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    b:SetBackdropColor(.04, .06, .09, 1); b:SetBackdropBorderColor(.2, .3, .4, 1)
    b.health = CreateFrame("StatusBar", nil, b); b.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    b.health:SetPoint("TOPLEFT", 1, -1); b.health:SetPoint("BOTTOMRIGHT", -1, 8)
    b.nameText = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); b.nameText:SetPoint("TOPLEFT", 15, -3); b.nameText:SetWidth(105); b.nameText:SetJustifyH("LEFT")
    S.AttachDisplay(b, b.health)
    RegisterStateDriver(b, "visibility", condition)
    b:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetUnit(self.unit); GameTooltip:Show() end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    for _, event in ipairs({"UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_AURA", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_CONNECTION", "UNIT_NAME_UPDATE", "UNIT_FLAGS", "UNIT_THREAT_SITUATION_UPDATE", "UNIT_IN_RANGE_UPDATE", "INCOMING_RESURRECT_CHANGED", "INCOMING_SUMMON_CHANGED"}) do
        pcall(b.RegisterUnitEvent, b, event, unit)
    end
    b:SetScript("OnEvent", function(self, event) refresh(self, event == "UNIT_AURA"); if event == "UNIT_AURA" and not InCombatLockdown() then S.After(S.UpdateQuickBuff) end end)
    b:SetScript("OnShow", function(self) refresh(self, true) end)
    S.buttons[#S.buttons + 1] = b
    return b
end
local function defaults()
    local range = S.FindSpell({2061, 19750, 8936, 8004, 2050, 635, 5185, 331})
    S.rangeSpell = range and range.id
    local selections = {
        ["1"] = {2061, 19750, 50464, 8936, 8004}, ["2"] = {2060, 2054, 2050, 635, 5185, 331},
        ["3"] = {139, 774, 61295, 20473, 17}, ["shift-1"] = {527, 4987, 2782, 51886},
    }
    for key, ids in pairs(selections) do
        if S.db.bindings[key] == nil then
            local spell = S.FindSpell(ids)
            if spell then S.db.bindings[key] = {kind = "spell", name = spell.name, id = spell.id, rank = "highest"} end
        end
    end
    if not S.db.bindings["1"] then S.db.bindings["1"] = {kind = "target"} end
end
local function initialize()
    if S.root or InCombatLockdown() then return end
    S.Init()
    local root = CreateFrame("Frame", addonName .. "Grid", UIParent, "BackdropTemplate")
    S.root = root; root:SetPoint("TOPLEFT", UIParent, "CENTER", 0, 0); root:SetSize(180, 300)
    root:SetMovable(true); root:EnableMouse(true); root:RegisterForDrag("LeftButton"); root:SetClampedToScreen(true)
    root:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    root:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        S.SavePosition(self)
    end)
    local label = root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); label:SetPoint("TOPLEFT", 8, -5); label:SetText("RebuffedHealbot")
    local settings = CreateFrame("Button", nil, root, "UIPanelButtonTemplate"); settings:SetSize(100, 20); settings:SetPoint("TOPLEFT", 8, -18); settings:SetText(S.Text("Einstellungen", "Settings")); settings:SetScript("OnClick", S.OpenSettings)
    unitButton("player", "[group:raid]hide;show")
    for i = 1, 4 do local unit = "party" .. i; unitButton(unit, "[group:raid]hide;[@" .. unit .. ",exists]show;hide") end
    for i = 1, 40 do local unit = "raid" .. i; unitButton(unit, "[group:raid,@" .. unit .. ",exists]show;hide") end
    unitButton("target", "[@target,help,exists]show;hide", "target")
    S.Start(root, S.buttons); defaults(); S.Apply()
    for _, b in ipairs(S.buttons) do refresh(b, true) end
    if S.ExtrasInit then S.ExtrasInit() end
end
for _, e in ipairs({"PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE", "PLAYER_TARGET_CHANGED", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "UPDATE_MACROS", "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED"}) do eventFrame:RegisterEvent(e) end
eventFrame:SetScript("OnEvent", function(self, event)
    if not S.root then initialize(); return end
    if event == "READY_CHECK" or event == "READY_CHECK_CONFIRM" or event == "READY_CHECK_FINISHED" or event == "PLAYER_TARGET_CHANGED" then
        for _, button in ipairs(S.buttons) do refresh(button, true) end
    elseif InCombatLockdown() then S.pending = true
    else S.Apply(); for _, button in ipairs(S.buttons) do refresh(button, true) end end
end)
SLASH_REBUFFEDHEALBOT1, SLASH_REBUFFEDHEALBOT2 = "/rhb", "/rebuffedhealbot"
SlashCmdList.REBUFFEDHEALBOT = function() S.OpenSettings() end
