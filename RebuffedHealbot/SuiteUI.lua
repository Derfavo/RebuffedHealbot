local addonName, addon = ...
local S = addon.suite
local panel, picker, search, page, rows = nil, nil, nil, "frames", {}
local content
local selectedProfile = "party"
local function frame(kind, name, parent)
    return CreateFrame(kind, name, parent, S.modern and "BackdropTemplate" or nil)
end
local function text(parent, label, x, y, width)
    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value:SetPoint("TOPLEFT", x, y); value:SetJustifyH("LEFT")
    if width then value:SetWidth(width) end
    value:SetText(label); return value
end
local function button(parent, label, width, x, y, callback)
    local value = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    value:SetSize(width, 22); value:SetPoint("TOPLEFT", x, y); value:SetText(label)
    value:SetScript("OnClick", callback); return value
end
local function backdrop(value)
    value:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, tile = true, tileSize = 32, insets = {left = 4, right = 4, top = 4, bottom = 4}})
end
local function blocked()
    if InCombatLockdown() then S.Print(S.Text("Einstellungen nach dem Kampf \195\164ndern.", "Change settings after combat.")); return true end
end
local function refresh()
    local query = search and search:GetText():lower() or ""
    local y = 0
    for _, row in ipairs(rows) do
        local matching = query == "" and row.page == page or query ~= "" and row.search:lower():find(query, 1, true)
        if matching then row:SetParent(content); row:ClearAllPoints(); row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y); row:Show(); row.refresh(); y = y - 27
        else row:Hide() end
    end
    content:SetHeight(math.max(510, -y))
end
local function option(label, key, values, target, ownerPage)
    local row = CreateFrame("Frame", nil, panel); row:SetSize(690, 25)
    row.page, row.search = ownerPage or "frames", label .. " " .. key
    row.label = text(row, label, 0, -5, 350)
    local b = button(row, "", 285, 365, 0, function()
        if blocked() then return end
        local record = target == "profile" and S.db.profiles[selectedProfile] or S.db
        local current, index = record[key], 0
        for i, choice in ipairs(values) do if choice[1] == current then index = i end end
        record[key] = values[index % #values + 1][1]
        S.Apply(); refresh()
    end)
    row.refresh = function()
        local record = target == "profile" and S.db.profiles[selectedProfile] or S.db
        local label = tostring(record[key])
        for _, choice in ipairs(values) do if choice[1] == record[key] then label = choice[2] end end
        b:SetText(label)
    end
    rows[#rows + 1] = row
end
local function check(label, key, ownerPage)
    option(label, key, {{true, S.Text("An", "On")}, {false, S.Text("Aus", "Off")}}, nil, ownerPage)
end
local function input(label, key, target, ownerPage)
    local row = CreateFrame("Frame", nil, panel); row:SetSize(690, 25); row.page, row.search = ownerPage or "keys", label .. " " .. tostring(key)
    text(row, label, 0, -5, 350)
    local box = CreateFrame("EditBox", nil, row, "InputBoxTemplate"); box:SetSize(275, 22); box:SetPoint("TOPLEFT", 372, 0); box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); refresh() end)
    box:SetScript("OnEnterPressed", function(self)
        if blocked() then return end
        local value = self:GetText():upper():gsub("%s", "")
        if #value > 40 or value:find("[^A-Z0-9%-]") then S.Print(S.Text("Ung\195\188ltige Taste.", "Invalid key.")); return end
        local record = target == "keys" and S.db.keys or S.db
        record[key] = value; self:ClearFocus(); S.Apply(); refresh()
    end)
    row.refresh = function() local record = target == "keys" and S.db.keys or S.db; box:SetText(record[key] or "") end
    rows[#rows + 1] = row
end
local function bindingLabel(key)
    local binding = S.db.bindings[key]
    if not binding then return S.Text("Standard", "Default") end
    if binding.kind == "spell" then return binding.name .. " - " .. (binding.rank == "fixed" and (binding.rankName or "") or S.Text("H\195\182chster Rang", "Highest rank")) end
    if binding.kind == "macro" then return "Macro - " .. (GetMacroInfo(binding.index) or "?") end
    return binding.kind
end
local function showPicker(key)
    if blocked() then return end
    if not picker then
        picker = frame("Frame", addonName .. "SpellPicker", UIParent); picker:SetSize(490, 540); picker:SetPoint("CENTER"); picker:SetFrameStrata("FULLSCREEN_DIALOG"); backdrop(picker); picker:EnableMouse(true)
        picker.search = CreateFrame("EditBox", nil, picker, "InputBoxTemplate"); picker.search:SetSize(320, 22); picker.search:SetPoint("TOPLEFT", 20, -18); picker.search:SetAutoFocus(false)
        picker.buttons = {}; picker.offset = 0
        local function update()
            local list, query = {}, picker.search:GetText():lower()
            list[#list + 1] = {label = S.Text("Belegung l\195\182schen", "Clear binding"), value = {kind = "none"}}
            list[#list + 1] = {label = S.Text("Spieler anvisieren", "Target player"), value = {kind = "target"}}
            list[#list + 1] = {label = S.Text("Spielermen\195\188", "Player menu"), value = {kind = "menu"}}
            for _, spell in ipairs(S.catalog) do
                if (picker.fixed or S.highest[spell.name] == spell) and (query == "" or spell.name:lower():find(query, 1, true)) then
                    list[#list + 1] = {label = spell.name .. " - " .. (picker.fixed and spell.rank or S.Text("H\195\182chster Rang", "Highest rank")),
                        value = {kind = "spell", id = spell.id, name = spell.name, rank = picker.fixed and "fixed" or "highest", rankName = spell.rank}}
                end
            end
            local global, character = GetNumMacros()
            for index = 1, global do local name = GetMacroInfo(index); if name and (query == "" or name:lower():find(query, 1, true)) then list[#list + 1] = {label = "Macro - " .. name, value = {kind = "macro", index = index}} end end
            local base = MAX_ACCOUNT_MACROS or 120
            for index = base + 1, base + character do local name = GetMacroInfo(index); if name and (query == "" or name:lower():find(query, 1, true)) then list[#list + 1] = {label = "Macro - " .. name, value = {kind = "macro", index = index}} end end
            picker.offset = math.max(0, math.min(picker.offset, #list - 18))
            for i, b in ipairs(picker.buttons) do
                local entry = list[picker.offset + i]; b.entry = entry
                if entry then b:SetText(entry.label); b:Show() else b:Hide() end
            end
        end
        picker.update = update
        picker.search:SetScript("OnTextChanged", function() picker.offset = 0; update() end)
        picker.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        button(picker, S.Text("Rang umschalten", "Toggle exact rank"), 170, 20, -48, function() picker.fixed = not picker.fixed; update() end)
        button(picker, "X", 32, 435, -16, function() picker:Hide() end)
        for i = 1, 18 do
            local b = button(picker, "", 450, 20, -78 - (i - 1) * 24, function(self)
                if blocked() or not self.entry then return end
                S.db.bindings[picker.key] = self.entry.value; S.Apply(); picker:Hide(); refresh()
            end)
            b:SetScript("OnEnter", function(self)
                if self.entry and self.entry.value.kind == "macro" then
                    local name, _, body = GetMacroInfo(self.entry.value.index)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(name)
                    GameTooltip:AddLine(body, 1, 1, 1, true); GameTooltip:Show()
                end
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            picker.buttons[i] = b
        end
        picker:EnableMouseWheel(true); picker:SetScript("OnMouseWheel", function(self, delta) self.offset = self.offset - delta * 3; update() end)
        UISpecialFrames[#UISpecialFrames + 1] = picker:GetName()
    end
    picker.key, picker.fixed, picker.offset = key, false, 0; picker.search:SetText(""); picker:Show(); picker.update()
end
local function binding(label, key, ownerPage)
    local row = CreateFrame("Frame", nil, panel); row:SetSize(690, 25); row.page, row.search = ownerPage, label
    text(row, label, 0, -5, 350)
    local b = button(row, "", 285, 365, 0, function() showPicker(type(key) == "function" and key() or key) end)
    row.refresh = function() b:SetText(bindingLabel(type(key) == "function" and key() or key)) end
    rows[#rows + 1] = row
end
function S.OpenSettings()
    if not S.db then return end
    if panel then panel:Show(); refresh(); return end
    panel = frame("Frame", addonName .. "SuiteSettings", UIParent); panel:SetSize(730, 690); panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG"); backdrop(panel)
    panel:EnableMouse(true); panel:SetMovable(true); panel:RegisterForDrag("LeftButton"); panel:SetScript("OnDragStart", panel.StartMoving); panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetScale(math.min(1, (UIParent:GetHeight() - 30) / 690))
    local scroll = CreateFrame("ScrollFrame", addonName .. "SuiteScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -96); scroll:SetPoint("BOTTOMRIGHT", -33, 83)
    content = CreateFrame("Frame", nil, scroll); content:SetSize(680, 510); scroll:SetScrollChild(content)
    text(panel, "RebuffedHealbot", 18, -15)
    button(panel, "X", 32, 680, -8, function() panel:Hide() end)
    search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate"); search:SetSize(300, 22); search:SetPoint("TOPLEFT", 210, -10); search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", refresh); search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local pages = {{"frames", "Frames"}, {"layout", "Layout"}, {"bindings", S.Text("Klicks", "Clicks")}, {"keys", S.Text("Tasten", "Keys")}, {"buffs", "Buffs"}}
    for i, entry in ipairs(pages) do local key = entry[1]; button(panel, entry[2], 130, 18 + (i - 1) * 138, -45, function() page = key; search:SetText(""); refresh() end) end
    option(S.Text("Frames anzeigen", "Show frames"), "showFrames", {{"always", "Always"}, {"solo", "Solo"}, {"party", "Party"}, {"raid", "Raid"}, {"never", "Never"}})
    check(S.Text("Freundliches Ziel anzeigen", "Show friendly target"), "showTarget")
    option(S.Text("Lebensfarbe", "Health color"), "color", {{"class", "Class"}, {"green", "Green"}, {"gradient", "Gradient"}})
    option(S.Text("Gesundheitstext", "Health text"), "healthText", {{"percent", "%"}, {"missing", "Missing"}, {"absolute", "Absolute"}, {"none", "Off"}})
    option(S.Text("Buff-/Debuff-Icongr\195\182\195\159e", "Buff/debuff icon size"), "auraSize", {{16, "16"}, {18, "18"}, {20, "20"}, {22, "22"}, {24, "24"}, {28, "28"}})
    for _, entry in ipairs({{"Incoming healing", "showPrediction"}, {"Remaining own HoT healing", "showHotPrediction"}, {"Absorb shields", "showAbsorbs"}, {"Aura timers", "showTimers"}, {"Mana cost preview", "showManaCost"}, {"Five-second rule", "showFiveSecond"}, {"Frame border", "border"}, {"Hide Blizzard group frames", "hideBlizzard"}}) do
        if not S.modern or entry[2] ~= "showHotPrediction" then check(entry[1], entry[2]) end
    end
    local row = CreateFrame("Frame", nil, panel); row:SetSize(690, 25); row.page, row.search = "layout", "Solo Party Raid profile group layout"
    local select = button(row, "", 285, 365, 0, function() selectedProfile = selectedProfile == "solo" and "party" or selectedProfile == "party" and "raid" or "solo"; S.editProfile = selectedProfile; if S.RefreshPreview then S.RefreshPreview() end; refresh() end)
    text(row, S.Text("Layout bearbeiten", "Edit layout"), 0, -5); row.refresh = function() select:SetText(selectedProfile) end; rows[#rows + 1] = row
    local sizes = {}; for n = 80, 220, 10 do sizes[#sizes + 1] = {n, tostring(n)} end
    option(S.Text("Breite", "Width"), "width", sizes, "profile", "layout")
    local heights = {}; for n = 36, 160, 4 do heights[#heights + 1] = {n, tostring(n)} end
    option(S.Text("H\195\182he", "Height"), "height", heights, "profile", "layout")
    local scales = {}; for n = 5, 20 do scales[#scales + 1] = {n / 10, n * 10 .. "%"} end
    option(S.Text("Skalierung", "Scale"), "scale", scales, "profile", "layout")
    option(S.Text("Wachstumsrichtung / Ecke", "Growth corner"), "grow", {{"TOPLEFT", "Top left"}, {"TOPRIGHT", "Top right"}, {"BOTTOMLEFT", "Bottom left"}, {"BOTTOMRIGHT", "Bottom right"}}, "profile", "layout")
    option(S.Text("Gruppen vertikal anordnen", "Arrange groups vertically"), "vertical", {{true, "Vertical"}, {false, "Horizontal"}}, "profile", "layout")
    local modifier = CreateFrame("Frame", nil, panel); modifier:SetSize(690, 25); modifier.page, modifier.search = "bindings", "Shift Ctrl Alt modifier combination"
    local modButton = button(modifier, "", 285, 365, 0, function() for i, value in ipairs(S.modifiers) do if value == S.modifier then S.modifier = S.modifiers[i % #S.modifiers + 1]; break end end; refresh() end)
    text(modifier, S.Text("Tastenkombination", "Modifier combination"), 0, -5); modifier.refresh = function() modButton:SetText(S.modifier ~= "" and S.modifier or "None") end; rows[#rows + 1] = modifier
    for i = 1, 5 do local index = i; binding("Mouse " .. i, function() return S.modifier .. index end, "bindings") end
    input(S.Text("Mausrad hoch (MOUSEWHEELUP)", "Mouse wheel up (MOUSEWHEELUP)"), "wheelUp")
    binding("Mouse wheel up spell", "rhbkey1", "keys")
    input(S.Text("Mausrad runter (MOUSEWHEELDOWN)", "Mouse wheel down (MOUSEWHEELDOWN)"), "wheelDown")
    binding("Mouse wheel down spell", "rhbkey2", "keys")
    -- Twelve keys are configured on their own numbered page through a selector.
    local keyRow = CreateFrame("Frame", nil, panel); keyRow:SetSize(690, 25); keyRow.page, keyRow.search = "keys", "12 custom keys MMO mouse"
    S.keySlot = 1
    local keySlot = button(keyRow, "", 285, 365, 0, function() S.keySlot = S.keySlot % 12 + 1; refresh() end)
    text(keyRow, "Custom key slot", 0, -5); keyRow.refresh = function() keySlot:SetText(tostring(S.keySlot)) end; rows[#rows + 1] = keyRow
    local keyEdit = CreateFrame("Frame", nil, panel); keyEdit:SetSize(690, 25); keyEdit.page, keyEdit.search = "keys", "custom key keyboard binding"
    text(keyEdit, "Key (press Enter to save)", 0, -5)
    local box = CreateFrame("EditBox", nil, keyEdit, "InputBoxTemplate"); box:SetSize(275, 22); box:SetPoint("TOPLEFT", 372, 0); box:SetAutoFocus(false)
    box:SetScript("OnEnterPressed", function(self) if blocked() then return end; local key = self:GetText():upper():gsub("%s", ""); if #key <= 40 and not key:find("[^A-Z0-9%-]") then S.db.keys[S.keySlot] = key; self:ClearFocus(); S.Apply() end end)
    keyEdit.refresh = function() box:SetText(S.db.keys[S.keySlot] or "") end; rows[#rows + 1] = keyEdit
    binding("Custom key spell", function() return "rhbkey" .. (S.keySlot + 2) end, "keys")
    input("Toggle frames key", "toggleKey", nil, "keys")
    input("Quick Buff key", "quickKey", nil, "buffs")
    check("Show missing buff marks", "showBuffMarks", "buffs"); check("Include friendly target", "targetBuffs", "buffs")
    option("Thorns recipients", "thorns", {{"self", "Self"}, {"tanks", "Self and tanks"}, {"all", "Everyone"}}, nil, "buffs")
    option("Shaman shield", "shield", {{"water", "Water Shield"}, {"lightning", "Lightning Shield"}}, nil, "buffs")
    local imbues = {{"default", "Auto"}, {"windfury", "Windfury"}, {"flametongue", "Flametongue"}, {"earthliving", "Earthliving"}, {"frostbrand", "Frostbrand"}, {"rockbiter", "Rockbiter"}, {"off", "Off"}}
    option("Shaman main-hand enchant", "mainhandEnchant", imbues, nil, "buffs")
    option("Shaman off-hand enchant", "offhandEnchant", imbues, nil, "buffs")
    option("Refresh buffs below (seconds)", "buffRefresh", {{0, "Missing only"}, {10, "10"}, {30, "30"}, {60, "60"}}, nil, "buffs")
    option("Group spell from missing players", "groupBuffThreshold", {{2, "2"}, {3, "3"}, {4, "4"}, {5, "5"}}, nil, "buffs")
    S.db.disabledBuffs = S.db.disabledBuffs or {}
    for _, spell in ipairs(S.TrackedBuffs()) do
        local name = spell.name
        local r = CreateFrame("Frame", nil, panel); r:SetSize(690, 25); r.page, r.search = "buffs", "Track buff " .. name
        text(r, "Track " .. name, 0, -5)
        local b = button(r, "", 285, 365, 0, function()
            if blocked() then return end
            S.db.disabledBuffs[name] = not S.db.disabledBuffs[name]; S.UpdateQuickBuff(); refresh()
        end)
        r.refresh = function() b:SetText(S.db.disabledBuffs[name] and "Off" or "On") end; rows[#rows + 1] = r
    end
    for _, key in ipairs({"TANK", "HEALER", "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}) do
        local recordKey = key
        local r = CreateFrame("Frame", nil, panel); r:SetSize(690, 25); r.page, r.search = "buffs", "Blessing " .. key
        text(r, "Blessing " .. key, 0, -5)
        local b = button(r, "", 285, 365, 0, function()
            if blocked() then return end
            local current = S.db.blessings[recordKey]
            local index = 0; for i, name in ipairs(S.blessingNames) do if name == current then index = i end end
            S.db.blessings[recordKey] = S.blessingNames[index % #S.blessingNames + 1]; S.UpdateQuickBuff(); refresh()
        end)
        r.refresh = function() b:SetText(S.db.blessings[recordKey] or "Default") end; rows[#rows + 1] = r
    end
    button(panel, "Preview 5 / 10 / 20 / 40", 220, 18, -620, function() if not blocked() and S.Preview then S.Preview() end end)
    button(panel, S.Text("Frames umschalten", "Toggle frames"), 180, 255, -620, function() if blocked() then return end; S.db.showFrames = S.db.showFrames == "never" and "always" or "never"; S.Apply(); refresh() end)
    text(panel, S.Text("Suche filtert alle Seiten. Tasten mit Enter speichern.", "Search filters all pages. Press Enter to save keys."), 18, -657, 690)
    UISpecialFrames[#UISpecialFrames + 1] = panel:GetName()
    refresh()
end
