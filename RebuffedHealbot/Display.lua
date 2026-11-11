local _, addon = ...
local S = addon.suite
local white = "Interface\\Buttons\\WHITE8X8"
local function shown(region, value) if value then region:Show() else region:Hide() end end
local function bar(parent, color)
    local value = CreateFrame("StatusBar", nil, parent)
    value:SetStatusBarTexture(white); value:SetStatusBarColor(unpack(color))
    value:SetMinMaxValues(0, 1); value:SetValue(0)
    return value
end
function S.AttachDisplay(button, health)
    if button.suiteDisplay then return end
    button.suiteDisplay = true
    button.health = health
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(); overlay:SetFrameLevel(button:GetFrameLevel() + 10)
    button.suiteOverlay = overlay
    if button.nameText then button.nameText:Hide() end
    button.nameText = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.nameText:SetJustifyH("LEFT")
    if button.actionText then
        button.actionText:Hide()
        button.actionText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.actionText:SetPoint("TOPLEFT", 4, -15); button.actionText:SetJustifyH("LEFT")
    end
    for _, name in ipairs({"icon", "tankRoleIcon", "healerRoleIcon"}) do
        if button[name] then
            button[name]:Hide(); button[name] = overlay:CreateTexture(nil, "OVERLAY")
            local icon = button[name]
            if name == "icon" then icon:SetSize(14, 14); icon:SetPoint("TOPRIGHT", -4, -3)
            else icon:SetSize(12, 12); icon:SetPoint("TOPLEFT", name == "tankRoleIcon" and 3 or 16, -2) end
        end
    end
    button.power = bar(button, {.15, .4, .95, 1})
    button.power:SetPoint("BOTTOMLEFT", 1, 1); button.power:SetPoint("BOTTOMRIGHT", -1, 1); button.power:SetHeight(6)
    button.incoming = bar(health, {.2, 1, .4, .7})
    button.hotPrediction = bar(health, {.1, .65, .3, .65})
    button.absorbs = bar(health, {.7, .85, 1, .7})
    for _, segment in ipairs({button.incoming, button.hotPrediction, button.absorbs}) do
        segment:SetPoint("TOPLEFT", health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        segment:SetHeight(20)
    end
    if health.SetClipsChildren then health:SetClipsChildren(true) end
    button.suiteHealthText = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.suiteHealthText:SetPoint("TOPRIGHT", -4, -15)
    button.suiteState = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.suiteState:SetPoint("BOTTOMLEFT", 3, 8)
    button.overheal = overlay:CreateTexture(nil, "OVERLAY")
    button.overheal:SetTexture(white); button.overheal:SetVertexColor(.85, .45, .15, .7)
    button.overheal:SetWidth(4); button.overheal:SetPoint("TOPRIGHT", -1, -1); button.overheal:SetHeight(12)
    button.overAbsorb = overlay:CreateTexture(nil, "OVERLAY"); button.overAbsorb:SetTexture(white); button.overAbsorb:SetVertexColor(.6, .85, 1, .9)
    button.overAbsorb:SetWidth(4); button.overAbsorb:SetPoint("BOTTOMRIGHT", -1, 8); button.overAbsorb:SetHeight(12)
    button.raidMarker = overlay:CreateTexture(nil, "OVERLAY"); button.raidMarker:SetSize(14, 14); button.raidMarker:SetPoint("TOPLEFT", 2, -2)
    button.readyMarker = overlay:CreateTexture(nil, "OVERLAY"); button.readyMarker:SetSize(16, 16); button.readyMarker:SetPoint("CENTER")
    button.targetBorder = overlay:CreateTexture(nil, "OVERLAY"); button.targetBorder:SetTexture(white)
    button.targetBorder:SetVertexColor(1, .85, .2, .85); button.targetBorder:SetHeight(2)
    button.targetBorder:SetPoint("TOPLEFT"); button.targetBorder:SetPoint("TOPRIGHT")
    button.suiteBorders = {}
    for i, point in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local edge = overlay:CreateTexture(nil, "OVERLAY"); edge:SetTexture(white)
        if i < 3 then edge:SetHeight(1); edge:SetPoint(point .. "LEFT"); edge:SetPoint(point .. "RIGHT")
        else edge:SetWidth(1); edge:SetPoint("TOP" .. point); edge:SetPoint("BOTTOM" .. point) end
        button.suiteBorders[i] = edge
    end
    button.suiteAuras = {}
    for i = 1, 9 do
        local icon = CreateFrame("Frame", nil, overlay)
        icon:SetSize(12, 12)
        icon:SetPoint("BOTTOMLEFT", 3 + (i - 1) * 13, 8)
        icon.texture = icon:CreateTexture(nil, "ARTWORK"); icon.texture:SetAllPoints()
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate"); icon.cooldown:SetAllPoints()
        icon.count = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); icon.count:SetPoint("BOTTOMRIGHT")
        icon.timer = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); icon.timer:SetPoint("TOP")
        button.suiteAuras[i] = icon
    end
    if S.modern and CreateUnitHealPredictionCalculator then
        button.calculator = CreateUnitHealPredictionCalculator()
        button.calculator:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
        button.calculator:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MissingHealth)
    end
end
function S.DisplaysSize(button)
    local profile = S.Profile()
    local width = button:GetWidth() - 2
    local height = profile.height - 9
    button.health:ClearAllPoints(); button.health:SetPoint("TOPLEFT", 1, -1); button.health:SetPoint("BOTTOMRIGHT", -1, 8)
    for _, segment in ipairs({button.incoming, button.hotPrediction, button.absorbs}) do segment:SetSize(width, height) end
    if button.nameText then
        button.nameText:ClearAllPoints(); button.nameText:SetPoint("TOPLEFT", button.icon and 29 or 20, -3); button.nameText:SetWidth(math.max(20, width - (button.icon and 48 or 24)))
    end
    if button.actionText then button.actionText:SetWidth(math.max(20, width - 47)) end
    if button.costOverlay then button.costOverlay:SetSize(width, 6) end
    local size = math.max(6, math.min(12, math.floor((width - 6) / 9)))
    for i, icon in ipairs(button.suiteAuras) do icon:SetSize(size, size); icon:ClearAllPoints(); icon:SetPoint("BOTTOMLEFT", 3 + (i - 1) * (size + 1), 8) end
end
function S.Predictions(button)
    local unit, maximum = button.unit, UnitHealthMax(button.unit)
    if S.modern then
        if button.calculator and (S.db.showPrediction or S.db.showAbsorbs) then
            UnitGetDetailedHealPrediction(unit, "player", button.calculator)
            local incoming, _, _, clamped = button.calculator:GetIncomingHeals()
            local absorbs, absorbClamped = button.calculator:GetDamageAbsorbs()
            button.incoming:SetMinMaxValues(0, maximum); button.incoming:SetValue(S.db.showPrediction and incoming or 0); shown(button.incoming, S.db.showPrediction)
            button.absorbs:ClearAllPoints(); button.absorbs:SetPoint("TOPLEFT", button.incoming:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
            shown(button.overheal, S.db.showPrediction); button.overheal:SetAlphaFromBoolean(clamped, 1, 0)
            button.absorbs:SetMinMaxValues(0, maximum); button.absorbs:SetValue(absorbs)
            shown(button.absorbs, S.db.showAbsorbs)
            shown(button.overAbsorb, S.db.showAbsorbs); button.overAbsorb:SetAlphaFromBoolean(absorbClamped, 1, 0)
        else button.incoming:Hide(); button.absorbs:Hide(); button.overheal:Hide(); button.overAbsorb:Hide() end
        button.hotPrediction:Hide()
        return
    end
    local health = UnitHealth(unit)
    local incoming, hot, absorb = 0, 0, 0
    local lib = LibStub and LibStub("LibHealComm-4.0", true)
    local guid = UnitGUID(unit)
    if lib and guid then
        local modifier = lib:GetHealModifier(guid)
        incoming = (lib:GetHealAmount(guid, lib.CASTED_HEALS, GetTime() + 4) or 0) * modifier
        hot = (lib:GetHealAmount(guid, lib.HOT_HEALS, nil, UnitGUID("player")) or 0) * modifier
    elseif UnitGetIncomingHeals then incoming = UnitGetIncomingHeals(unit) or 0 end
    if UnitGetTotalAbsorbs then absorb = UnitGetTotalAbsorbs(unit) or 0
    elseif LibStub and guid then
        local monitor = LibStub("AbsorbsMonitor-1.0", true)
        if monitor then absorb = math.max(0, monitor.Unit_Total(guid) or 0) end
    end
    local width, height = button.health:GetWidth(), button.health:GetHeight()
    local available = math.max(0, maximum - health)
    local function segment(region, amount, start, enabled)
        region:ClearAllPoints()
        region:SetPoint("TOPLEFT", button.health, "TOPLEFT", width * start / math.max(1, maximum), 0)
        region:SetSize(width, height); region:SetMinMaxValues(0, math.max(1, maximum)); region:SetValue(math.max(0, math.min(amount, maximum - start)))
        shown(region, enabled)
    end
    local direct = S.db.showPrediction and math.min(incoming, available) or 0
    local periodic = S.db.showHotPrediction and math.min(hot, math.max(0, available - direct)) or 0
    segment(button.incoming, direct, health, S.db.showPrediction)
    segment(button.hotPrediction, periodic, health + direct, S.db.showHotPrediction)
    segment(button.absorbs, absorb, health + direct + periodic, S.db.showAbsorbs)
    shown(button.overheal, S.db.showPrediction and incoming > available)
    shown(button.overAbsorb, S.db.showAbsorbs and absorb > math.max(0, available - direct - periodic))
end
local dispels = {
    Magic = {527, 4987, 88423, 77130}, Disease = {527, 4987, 1152, 2870, 528},
    Curse = {475, 2782, 51886, 88423}, Poison = {4987, 1152, 2893, 8946, 526, 2782},
}
function S.RefreshDispelCapabilities()
    S.dispelCapabilities = {}
    for kind, ids in pairs(dispels) do S.dispelCapabilities[kind] = S.FindSpell(ids) ~= nil end
end
function S.Auras(button)
    local icons, slot = button.suiteAuras, 1
    if S.modern then
        local seen = {}
        for _, filter in ipairs({"HELPFUL|PLAYER", "HARMFUL|RAID", "HARMFUL"}) do
            local limit = filter == "HELPFUL|PLAYER" and 4 or filter == "HARMFUL|RAID" and 3 or 2
            local auras = C_UnitAuras.GetUnitAuras(button.unit, filter, limit)
            for _, aura in ipairs(auras) do
                local icon = icons[slot]
                if not icon then break end
                local duplicate = S.Safe(aura.auraInstanceID) and seen[aura.auraInstanceID]
                if not duplicate then
                if S.Safe(aura.auraInstanceID) then seen[aura.auraInstanceID] = true end
                icon.texture:SetTexture(aura.icon)
                icon.count:SetFormattedText("%d", aura.applications)
                if S.db.showTimers and S.Safe(aura.auraInstanceID) then
                    local duration = C_UnitAuras.GetAuraDuration(button.unit, aura.auraInstanceID)
                    if duration then icon.cooldown:SetCooldownFromDurationObject(duration); icon.cooldown:Show() else icon.cooldown:Hide() end
                else icon.cooldown:Hide() end
                icon.timer:SetText(""); icon:Show(); slot = slot + 1
                end
            end
        end
    else
        local groups = {own = {}, dispel = {}, other = {}}
        for _, harmful in ipairs({false, true}) do
            for index = 1, 40 do
                local getter = harmful and UnitDebuff or UnitBuff
                local name, _, texture, count, kind, duration, expiration, caster = getter(button.unit, index)
                if not name then break end
                local canDispel = kind and S.dispelCapabilities and S.dispelCapabilities[kind]
                local mode = harmful and (canDispel and "dispel" or "other") or "own"
                local selected = groups[mode]
                local limit = mode == "own" and 4 or mode == "dispel" and 3 or 2
                if (harmful or caster and UnitIsUnit(caster, "player")) and #selected < limit then
                    selected[#selected + 1] = {texture = texture, count = count, duration = duration, expiration = expiration}
                end
            end
        end
        for _, mode in ipairs({"own", "dispel", "other"}) do
            for _, aura in ipairs(groups[mode]) do
                    local icon = icons[slot]
                    if not icon then break end
                    local count, duration, expiration = aura.count, aura.duration, aura.expiration
                    icon.texture:SetTexture(aura.texture); icon.count:SetText(count and count > 1 and count or "")
                    local seconds = expiration and expiration > 0 and math.max(0, math.ceil(expiration - GetTime())) or 0
                    icon.expiration = expiration
                    icon.timer:SetText(S.db.showTimers and seconds > 0 and seconds or "")
                    if S.db.showTimers and duration and duration > 0 and expiration then icon.cooldown:SetCooldown(expiration - duration, duration); icon.cooldown:Show() else icon.cooldown:Hide() end
                    icon:Show(); slot = slot + 1
            end
        end
    end
    for index = slot, #icons do icons[index]:Hide() end
end
function S.UpdateAuraTimers(button)
    if S.modern then return end
    local now = GetTime()
    if button.suiteTimerSecond == math.floor(now) then return end
    button.suiteTimerSecond = math.floor(now)
    for _, icon in ipairs(button.suiteAuras) do
        if icon.expiration and icon.expiration > 0 then
            icon.timer:SetText(S.db.showTimers and math.max(0, math.ceil(icon.expiration - now)) or "")
        end
    end
end
function S.UpdateDisplay(button)
    if not button.suiteDisplay or not UnitExists(button.unit) then return end
    local unit = button.unit
    button.power:SetMinMaxValues(0, UnitPowerMax(unit, 0)); button.power:SetValue(UnitPower(unit, 0))
    local text = button.suiteHealthText
    if S.db.healthText == "none" then text:SetText("")
    elseif S.modern then
        if S.db.healthText == "missing" then text:SetFormattedText("-%.0f", UnitHealthMissing(unit, true))
        elseif S.db.healthText == "absolute" then text:SetFormattedText("%.0f", UnitHealth(unit))
        elseif S.percentCurve then text:SetFormattedText("%.0f%%", UnitHealthPercent(unit, true, S.percentCurve)) end
    else
        local health, maximum = UnitHealth(unit), math.max(1, UnitHealthMax(unit))
        if S.db.healthText == "missing" then text:SetText(tostring(health - maximum))
        elseif S.db.healthText == "absolute" then text:SetText(tostring(health))
        else text:SetText(tostring(math.floor(health / maximum * 100 + .5)) .. "%") end
    end
    local r, g, b = .1, .75, .25
    if S.db.color == "class" then
        local _, class = UnitClass(unit)
        local color = S.Safe(class) and RAID_CLASS_COLORS[class]
        if color then r, g, b = color.r, color.g, color.b end
    elseif S.db.color == "gradient" then
        if S.modern and S.colorCurve then
            local color = UnitHealthPercent(unit, true, S.colorCurve)
            r, g, b = color:GetRGB()
        elseif not S.modern then g = UnitHealth(unit) / math.max(1, UnitHealthMax(unit)); r = 1 - g; b = .1 end
    end
    button.health:SetStatusBarColor(r, g, b, 1)
    local marker = GetRaidTargetIndex(unit)
    if S.Safe(marker) and marker then SetRaidTargetIconTexture(button.raidMarker, marker); button.raidMarker:Show() else button.raidMarker:Hide() end
    if S.Safe(marker) and marker then
        if button.tankRoleIcon then button.tankRoleIcon:Hide() end
        if button.healerRoleIcon then button.healerRoleIcon:Hide() end
    end
    local ready = GetReadyCheckStatus and GetReadyCheckStatus(unit)
    if ready == "ready" then button.readyMarker:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready"); button.readyMarker:Show()
    elseif ready == "notready" then button.readyMarker:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady"); button.readyMarker:Show()
    elseif ready == "waiting" then button.readyMarker:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting"); button.readyMarker:Show()
    else button.readyMarker:Hide() end
    if S.modern then button.targetBorder:Show(); button.targetBorder:SetAlphaFromBoolean(UnitIsUnit(unit, "target"), 1, 0)
    else shown(button.targetBorder, UnitIsUnit(unit, "target")) end
    local threat = UnitThreatSituation and UnitThreatSituation(unit)
    if S.Safe(threat) and threat == nil then threat = 0 end
    local borderR, borderG, borderB = .2, .3, .4
    if S.modern and S.threatCurve then
        local color = S.threatCurve:Evaluate(threat)
        borderR, borderG, borderB = color:GetRGB()
    elseif not S.modern and threat >= 2 then borderR, borderG, borderB = 1, .2, .1 end
    for _, edge in ipairs(button.suiteBorders) do edge:SetVertexColor(borderR, borderG, borderB, 1); shown(edge, S.db.border) end
    if not S.db.border and button.SetBackdropBorderColor then button:SetBackdropBorderColor(0, 0, 0, 0) end
    local state = ""
    if UnitHasIncomingResurrection then
        local incoming = UnitHasIncomingResurrection(unit)
        if S.Safe(incoming) and incoming then state = S.Text("Wiederbelebung", "Resurrection") end
    end
    if C_IncomingSummon and C_IncomingSummon.HasIncomingSummon(unit) then state = S.Text("Beschw\195\182rung", "Summon pending") end
    if not UnitIsConnected(unit) then state = S.Text("Offline", "Offline")
    elseif UnitIsDeadOrGhost(unit) and state == "" then state = S.Text("Tot", "Dead") end
    button.suiteState:SetText(state)
    S.Predictions(button)
    S.UpdateAuraTimers(button)
end
function S.DisplayInit()
    if S.modern and C_CurveUtil then
        S.percentCurve = C_CurveUtil.CreateCurve(); S.percentCurve:AddPoint(0, 0); S.percentCurve:AddPoint(1, 100)
        S.colorCurve = C_CurveUtil.CreateColorCurve(); S.colorCurve:AddPoint(0, CreateColor(1, .1, .1)); S.colorCurve:AddPoint(1, CreateColor(.1, 1, .1))
        S.threatCurve = C_CurveUtil.CreateColorCurve(); S.threatCurve:AddPoint(0, CreateColor(.2, .3, .4)); S.threatCurve:AddPoint(1, CreateColor(1, 1, .2)); S.threatCurve:AddPoint(2, CreateColor(1, .4, .1)); S.threatCurve:AddPoint(3, CreateColor(1, .1, .1))
    end
end
