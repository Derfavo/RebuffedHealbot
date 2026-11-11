local addonName, addon = ...
local S = addon.suite
local definitions = {
    PRIEST = {{ids = {1243}, group = {21562}}, {ids = {14752}, group = {27681}}, {ids = {976}, group = {27683}}, {ids = {588}, self = true}},
    DRUID = {{ids = {1126}, group = {21849}}, {ids = {467}, thorns = true}},
    SHAMAN = {{ids = {52127}, self = true}, {ids = {8232, 8024, 51730, 8033}, weapon = 16}},
    MAGE = {{ids = {1459}, group = {23028}}, {ids = {30482, 6117, 168}, self = true}},
    WARLOCK = {{ids = {28176, 706, 687}, self = true}}, WARRIOR = {{ids = {469, 6673}, self = true}},
    HUNTER = {{ids = {34074, 13165}, self = true}}, DEATHKNIGHT = {{ids = {57330}, self = true}},
}
local blessings = {
    might = {ids = {19740}, group = {25782}}, wisdom = {ids = {19742}, group = {25894}},
    kings = {ids = {20217}, group = {25898}}, sanctuary = {ids = {20911}, group = {25899}},
}
S.blessingNames = {"kings", "might", "wisdom", "sanctuary"}
local function chargedShield(spell)
    return spell.name == S.SpellName(52127) or spell.name == S.SpellName(324)
end
local weaponSpells = {windfury = 8232, flametongue = 8024, earthliving = 51730, frostbrand = 8033, rockbiter = 8017}
local function hasWeapon(slot)
    local link = GetInventoryItemLink("player", slot)
    if not link then return false end
    local getter = S.modern and C_Item.GetItemInfo or GetItemInfo
    local equip = select(9, getter(link))
    return equip == "INVTYPE_WEAPON" or equip == "INVTYPE_WEAPONMAINHAND" or equip == "INVTYPE_WEAPONOFFHAND" or equip == "INVTYPE_2HWEAPON"
end
function S.WeaponEnchant(slot)
    if S.modern then
        local bank = slot == 16 and Enum.WeaponSlot.MainHand or Enum.WeaponSlot.OffHand
        for _, enchant in pairs(C_Item.GetWeaponEnchantInfo(bank)) do
            if enchant.hasEnchant and enchant.enchantType == Enum.ItemEnchantType.Imbue then return true, enchant.charges end
        end
        return false
    end
    local main, _, mainCharges, fourth, fifth, sixth, seventh = GetWeaponEnchantInfo()
    if slot == 16 then return main, mainCharges end
    if S.modern then return fifth, seventh end
    return fourth, sixth
end
function S.BuffDefinitions()
    local _, class = UnitClass("player")
    local defs = definitions[class] or {}
    if class == "SHAMAN" then
        local main = weaponSpells[S.db.mainhandEnchant]
        local off = weaponSpells[S.db.offhandEnchant]
        defs = {{ids = {S.db.shield == "lightning" and 324 or 52127}, self = true}}
        if S.db.mainhandEnchant ~= "off" and hasWeapon(16) then
            defs[#defs + 1] = {ids = main and {main} or {51730, 8232, 8024, 8033, 8017}, weapon = 16}
        end
        if S.db.offhandEnchant and S.db.offhandEnchant ~= "off" and hasWeapon(17) then
            defs[#defs + 1] = {ids = off and {off} or {8232, 8024, 8033, 8017}, weapon = 17}
        end
    elseif class == "PALADIN" then defs = {{blessing = true}} end
    return defs
end
function S.Members()
    local members = {"player"}
    if S.GroupType() == "raid" then
        local count = S.modern and GetNumGroupMembers() or GetNumRaidMembers()
        for i = 1, count do local unit = "raid" .. i; if not UnitIsUnit(unit, "player") then members[#members + 1] = unit end end
    else for i = 1, 4 do if UnitExists("party" .. i) then members[#members + 1] = "party" .. i end end end
    if S.db.targetBuffs and UnitExists("target") and UnitIsFriend("player", "target") then
        local found
        for _, unit in ipairs(members) do if UnitIsUnit(unit, "target") then found = true end end
        if not found then members[#members + 1] = "target" end
    end
    return members
end
function S.HasBuff(unit, spell, group)
    if S.modern then
        local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spell.id)
        if not aura and group then aura = C_UnitAuras.GetUnitAuraBySpellID(unit, group.id) end
        if not S.Safe(aura) then return true end
        if not aura then return false end
        if chargedShield(spell) and S.Safe(aura.applications) and aura.applications <= 1 then return false end
        if not S.Safe(aura.expirationTime) then return true end
        return aura.expirationTime == 0 or aura.expirationTime - GetTime() > S.db.buffRefresh
    end
    local cached = S.buffCache and S.buffCache[unit]
    if not cached then
        cached = {}
        for i = 1, 40 do
            local name, _, _, count, _, _, expiration = UnitBuff(unit, i)
            if not name then break end
            cached[name] = {count = count, expiration = expiration}
        end
        if S.buffCache then S.buffCache[unit] = cached end
    end
    for name, aura in pairs(cached) do
        local count, expiration = aura.count, aura.expiration
        if name == spell.name or group and name == group.name then
            local charged = chargedShield(spell)
            return (not expiration or expiration == 0 or expiration - GetTime() > S.db.buffRefresh)
                and (not charged or count and count > 1)
        end
    end
    return false
end
function S.TrackedBuffs()
    local result, seen = {}, {}
    local _, class = UnitClass("player")
    local defs = class == "PALADIN" and {blessings.kings, blessings.might, blessings.wisdom, blessings.sanctuary} or S.BuffDefinitions()
    for _, def in ipairs(defs) do
        local spell = S.FindSpell(def.ids)
        if spell and not seen[spell.name] then result[#result + 1] = spell; seen[spell.name] = true end
    end
    return result
end
function S.Role(unit)
    if GetPartyAssignment and GetPartyAssignment("MAINTANK", unit) then return "TANK" end
    if ChronixHealDB.tankGuid and S.Safe(UnitGUID(unit)) and UnitGUID(unit) == ChronixHealDB.tankGuid then return "TANK" end
    if UnitGroupRolesAssigned then
        local tank, healer = UnitGroupRolesAssigned(unit)
        if type(tank) == "string" then return tank end
        if tank == true or tank == 1 then return "TANK" end
        if healer == true or healer == 1 then return "HEALER" end
    end
    return "DAMAGER"
end
local function wantedBlessing(unit)
    local _, class = UnitClass(unit)
    local role = S.Role(unit)
    local configured = S.db.blessings[role] or S.db.blessings[class] or "kings"
    local definition = blessings[configured]
    if S.FindSpell(definition.ids) then return definition end
    return S.FindSpell(blessings.might.ids) and blessings.might or blessings.wisdom
end
function S.BuffPlan()
    S.buffCache = {}
    local _, class = UnitClass("player")
    local defs = S.BuffDefinitions()
    local plan, members = {}, S.Members()
    for _, definition in ipairs(defs) do
        for _, unit in ipairs(members) do
            local def = definition.blessing and wantedBlessing(unit) or definition
            if class == "SHAMAN" and definition.self and S.db.shield == "lightning" then def = {ids = {324}, self = true} end
            local spell, group = S.FindSpell(def.ids), def.group and S.FindSpell(def.group)
            local applies = not def.self or unit == "player"
            if def.thorns and S.db.thorns ~= "all" then applies = unit == "player" or S.db.thorns == "tanks" and S.Role(unit) == "TANK" end
            local reachable = not UnitIsVisible or UnitIsVisible(unit)
            if spell and unit ~= "player" then
                local range
                if S.modern and C_Spell.IsSpellInRange then range = C_Spell.IsSpellInRange(spell.id, unit)
                elseif not S.modern and IsSpellInRange then range = IsSpellInRange(spell.name, unit) end
                if S.Safe(range) and (range == false or range == 0) then reachable = false end
            end
            if spell and reachable and not (S.db.disabledBuffs and S.db.disabledBuffs[spell.name]) and applies and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
                local missing
                if def.weapon then
                    if unit == "player" then
                        local active, charges = S.WeaponEnchant(def.weapon)
                        missing = not active or charges == 1
                    end
                else missing = not S.HasBuff(unit, spell, group) end
                if missing then plan[#plan + 1] = {unit = unit, spell = spell, group = group, definition = def, blessing = definition.blessing} end
            end
        end
    end
    S.buffCache = nil
    return plan
end
local function bucket(entry)
    if entry.blessing then local _, class = UnitClass(entry.unit); return class end
    local raidIndex = tonumber(entry.unit:match("^raid(%d+)$"))
    if not raidIndex and S.GroupType() == "raid" then
        local count = S.modern and GetNumGroupMembers() or GetNumRaidMembers()
        for index = 1, count do if UnitIsUnit(entry.unit, "raid" .. index) then raidIndex = index; break end end
    end
    return raidIndex and select(3, GetRaidRosterInfo(raidIndex)) or 1
end
function S.UpdateQuickBuff()
    if not S.quick or not S.db then return end
    if InCombatLockdown() then S.pendingBuff = true; return end
    if S.UpdateOwnBuffs then S.UpdateOwnBuffs() end
    local plan = S.BuffPlan()
    S.buffPlan = plan
    local nextBuff = plan[1]
    if nextBuff then
        local spell = nextBuff.spell
        if nextBuff.group then
            local count = 0
            for _, entry in ipairs(plan) do
                if entry.spell.name == spell.name and bucket(entry) == bucket(nextBuff) then count = count + 1 end
            end
            if count >= S.db.groupBuffThreshold then spell = nextBuff.group end
        end
        local cast = "/cast [nocombat,@" .. nextBuff.unit .. ",help,nodead] " .. spell.name
        if nextBuff.definition.weapon then cast = "/cast [nocombat] " .. spell.name .. "\n/use [nocombat] " .. nextBuff.definition.weapon end
        S.quick:SetAttribute("type1", "macro"); S.quick:SetAttribute("macrotext1", cast)
        S.quick.icon:SetTexture(spell.texture)
        S.quick.label:SetText((UnitName(nextBuff.unit) or nextBuff.unit) .. "  " .. #plan)
        S.quick.tip = spell.name
    else
        S.quick:SetAttribute("type1", "none"); S.quick:SetAttribute("macrotext1", nil)
        S.quick.icon:SetTexture("Interface\\Icons\\Spell_Holy_BlessingOfStrength")
        S.quick.label:SetText(S.Text("Buffs vollst\195\164ndig", "Buffs complete")); S.quick.tip = nil
    end
    ClearOverrideBindings(S.quick)
    if S.db.quickKey ~= "" then SetOverrideBindingClick(S.quick, true, S.db.quickKey, S.quick:GetName(), "LeftButton") end
    for _, button in ipairs(S.buttons) do
            local missing
            if S.db.showBuffMarks then
                for _, entry in ipairs(plan) do if UnitExists(button.unit) and UnitIsUnit(button.unit, entry.unit) then missing = true; break end end
            end
            if button.buffMark then if missing then button.buffMark:Show() else button.buffMark:Hide() end end
    end
end
function S.BuffsInit()
    local quick = CreateFrame("Button", addonName .. "QuickBuff", UIParent, "SecureActionButtonTemplate")
    S.quick = quick
    quick:SetSize(32, 32); quick:SetPoint("TOPLEFT", S.root, "BOTTOMLEFT", 0, -70)
    quick:RegisterForClicks(S.modern and "AnyDown" or "AnyUp", "AnyUp")
    quick.icon = quick:CreateTexture(nil, "ARTWORK"); quick.icon:SetAllPoints()
    quick.label = quick:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); quick.label:SetPoint("LEFT", quick, "RIGHT", 5, 0)
    quick:SetMovable(true); quick:EnableMouse(true); quick:RegisterForDrag("RightButton")
    quick:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    quick:SetScript("OnDragStop", function(self) if not InCombatLockdown() then self:StopMovingOrSizing() end end)
    S.RememberIcon(quick, "quick")
    quick:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Quick Buff")
        GameTooltip:AddLine(self.tip or S.Text("Gruppe gebufft", "Group buffed"), 1, 1, 1)
        GameTooltip:AddLine(S.Text("Pro Klick ein Buff, au\195\159erhalb des Kampfes.", "One buff per click, out of combat."), .7, .7, .7); GameTooltip:Show()
    end)
    quick:SetScript("OnLeave", function() GameTooltip:Hide() end)
    quick:SetScript("PostClick", function() if not InCombatLockdown() then S.After(S.UpdateQuickBuff) end end)
    for _, button in ipairs(S.buttons) do
        button.buffMark = (button.suiteOverlay or button):CreateTexture(nil, "OVERLAY"); button.buffMark:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        button.buffMark:SetSize(8, 8); button.buffMark:SetPoint("BOTTOMRIGHT", -2, 2); button.buffMark:Hide()
    end
    if S.modern then
        S.ownBuffButtons = {}
        local chargeAlpha = C_CurveUtil.CreateCurve(); chargeAlpha:AddPoint(0, 1); chargeAlpha:AddPoint(1, 1); chargeAlpha:AddPoint(2, 0)
        local chargeColor = C_CurveUtil.CreateColorCurve(); chargeColor:AddPoint(0, CreateColor(1, .1, .1)); chargeColor:AddPoint(1, CreateColor(1, .1, .1)); chargeColor:AddPoint(2, CreateColor(.2, .3, .4))
        S.RefreshOwnBuffVisuals = function()
            for _, b in ipairs(S.ownBuffButtons) do
                if b.entry and b:IsShown() then
                    local def, spell = b.entry.definition, b.entry.spell
                    local alpha, r, g, blue = 0, .2, .3, .4
                    if not UnitIsDeadOrGhost("player") then
                        local missing
                        if def.weapon then local active, charges = S.WeaponEnchant(def.weapon); missing = not active or charges == 1
                        else
                            local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "player", spell.id)
                            local readable = ok and S.Safe(aura)
                            missing = readable and not aura
                            if readable and aura and chargedShield(spell) then
                                alpha = chargeAlpha:Evaluate(aura.applications)
                                local color = chargeColor:Evaluate(aura.applications); r, g, blue = color:GetRGB()
                            elseif readable and aura and not InCombatLockdown() then missing = not S.HasBuff("player", spell) end
                        end
                        if missing then alpha, r, g, blue = 1, 1, .1, .1 end
                    end
                    b.alert:SetAlpha(alpha); b:SetBackdropBorderColor(r, g, blue, 1)
                end
            end
        end
        S.UpdateOwnBuffs = function()
            if InCombatLockdown() then return end
            local _, class = UnitClass("player")
            local defs = S.BuffDefinitions()
            if class == "PALADIN" then defs = {wantedBlessing("player")} end
            for i = 1, math.max(#defs, #S.ownBuffButtons) do
                local def = defs[i]
                local spell = def and S.FindSpell(def.ids)
                local b = S.ownBuffButtons[i]
                if spell and not (S.db.disabledBuffs and S.db.disabledBuffs[spell.name]) then
                    if not b then
                        b = CreateFrame("Button", addonName .. "OwnBuff" .. i, UIParent, "SecureActionButtonTemplate,BackdropTemplate")
                        b:SetSize(30, 30); b:SetPoint("LEFT", quick, "RIGHT", 150 + (i - 1) * 34, 0)
                        b:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2})
                        b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetPoint("TOPLEFT", 2, -2); b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
                        b.alert = CreateFrame("Frame", nil, b); b.alert:SetAllPoints()
                        b.glow = b.alert:CreateTexture(nil, "OVERLAY"); b.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border"); b.glow:SetBlendMode("ADD"); b.glow:SetSize(46, 46); b.glow:SetPoint("CENTER")
                        b.pulse = b.glow:CreateAnimationGroup(); b.pulse:SetLooping("BOUNCE")
                        local alpha = b.pulse:CreateAnimation("Alpha"); alpha:SetFromAlpha(.3); alpha:SetToAlpha(1); alpha:SetDuration(.6)
                        b:RegisterForClicks("AnyDown", "AnyUp")
                        b:SetMovable(true); b:EnableMouse(true); b:RegisterForDrag("RightButton")
                        b:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
                        b:SetScript("OnDragStop", function(self) if not InCombatLockdown() then self:StopMovingOrSizing() end end)
                        S.RememberIcon(b, "own" .. i)
                        S.ownBuffButtons[i] = b
                    end
                    b.icon:SetTexture(spell.texture); b:SetAttribute("type1", "spell"); b:SetAttribute("spell1", spell.id); b:SetAttribute("unit", "player")
                    b.entry = {definition = def, spell = spell}
                    if def.weapon then
                        b:SetAttribute("type1", "macro"); b:SetAttribute("macrotext1", "/cast " .. spell.name .. "\n/use " .. def.weapon)
                    else b:SetAttribute("macrotext1", nil) end
                    b.pulse:Play()
                    b:Show()
                elseif b then b:Hide() end
            end
            S.RefreshOwnBuffVisuals()
        end
    end
end
