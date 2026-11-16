local addonName, addon = ...
local S = { addon = addon, buttons = {}, catalog = {}, modifier = "", mouse = 1 }
addon.suite = S
S.modern = addon.forever == true
function S.Text(de, en) return GetLocale() == "deDE" and de or en end
function S.Safe(value) return not issecretvalue or not issecretvalue(value) end
function S.Print(message) DEFAULT_CHAT_FRAME:AddMessage("|cff57c8ffRebuffedHealbot|r " .. message) end
local modifiers = {"", "shift-", "ctrl-", "alt-", "alt-ctrl-", "alt-shift-", "ctrl-shift-", "alt-ctrl-shift-"}
S.modifiers = modifiers
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for key, child in pairs(value) do result[key] = copy(child) end
    return result
end
function S.Init()
    ChronixHealDB = type(ChronixHealDB) == "table" and ChronixHealDB or {}
    local db = ChronixHealDB
    db.suite = type(db.suite) == "table" and db.suite or {}
    S.db = db.suite
    local defaults = {
        showPets = false, showTarget = true, showFrames = "always", color = "class", healthText = "percent",
        border = true, showTimers = true, auraSize = 20, showPrediction = true, showAbsorbs = true, showHotPrediction = true,
        showFiveSecond = true, showManaCost = true, hideBlizzard = false, showBuffMarks = true,
        targetBuffs = true, thorns = "tanks", buffRefresh = 30, groupBuffThreshold = 3,
        quickKey = "", toggleKey = "", wheelUp = "MOUSEWHEELUP", wheelDown = "MOUSEWHEELDOWN", keys = {}, bindings = {}, blessings = {}, profiles = {}, welcomed = false,
    }
    for key, value in pairs(defaults) do if S.db[key] == nil then S.db[key] = copy(value) end end
    S.db.showPets = false
    for _, kind in ipairs({"solo", "party", "raid"}) do
        local profile = S.db.profiles[kind] or {}
        local base = {width = addon.config and addon.config.width or 128, height = addon.config and addon.config.height or 52,
            scale = db.scale or 1, grow = "TOPLEFT", vertical = false, x = db.x or 0, y = db.y or 0}
        for key, value in pairs(base) do if profile[key] == nil then profile[key] = value end end
        profile.height = math.max(profile.height, S.RequiredFrameHeight(profile))
        S.db.profiles[kind] = profile
    end
end
function S.RequiredFrameHeight(profile)
    local size = math.max(16, math.min(28, tonumber(S.db.auraSize) or 20))
    local columns = math.max(1, math.floor((profile.width - 6) / (size + 2)))
    return 36 + math.ceil(9 / columns) * (size + 2)
end
function S.GroupType()
    if S.modern then
        if IsInRaid() then return "raid" end
        if IsInGroup() then return "party" end
    else
        if GetNumRaidMembers() > 0 then return "raid" end
        if GetNumPartyMembers() > 0 then return "party" end
    end
    return "solo"
end
function S.Profile() return S.db.profiles[S.GroupType()] end
function S.SavePosition(frame)
    local p = S.Profile()
    local cx, cy = UIParent:GetCenter()
    local x = p.grow:find("RIGHT", 1, true) and frame:GetRight() or frame:GetLeft()
    local y = p.grow:find("BOTTOM", 1, true) and frame:GetBottom() or frame:GetTop()
    p.x, p.y = x * p.scale - cx, y * p.scale - cy
end
function S.BindingDescription(binding)
    if binding.kind == "spell" then return (binding.name or "?") .. (binding.rank == "fixed" and " (" .. (binding.rankName or "") .. ")" or "") end
    if binding.kind == "macro" then return "Macro: " .. (GetMacroInfo(binding.index) or "?") end
    return binding.kind == "target" and "Target" or binding.kind == "menu" and "Player menu" or "Unbound"
end
function S.RememberIcon(frame, key)
    local saved = S.db.iconPositions and S.db.iconPositions[key]
    if saved then frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y) end
    frame:HookScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
        S.db.iconPositions = S.db.iconPositions or {}
        S.db.iconPositions[key] = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
    end)
end
function S.Spells()
    if InCombatLockdown() then return S.catalog end
    local result, highest = {}, {}
    local function add(id, name, rank, texture, passive)
        if not name or passive then return end
        local entry = {id = id, name = name, rank = rank or "", texture = texture}
        result[#result + 1] = entry
        highest[name] = entry
    end
    if S.modern then
        local bank = Enum.SpellBookSpellBank.Player
        for tab = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local line = C_SpellBook.GetSpellBookSkillLineInfo(tab)
            for slot = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
                local info = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                if info and info.spellID then
                    local name, rank = C_SpellBook.GetSpellBookItemName(slot, bank)
                    local spell = C_Spell.GetSpellInfo(info.spellID)
                    add(info.spellID, name, rank, spell and spell.iconID, info.isPassive)
                end
            end
        end
    else
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tab)
            for slot = offset + 1, offset + count do
                local name, rank = GetSpellName(slot, "spell")
                local link = GetSpellLink and GetSpellLink(slot, "spell")
                local id = link and tonumber(link:match("spell:(%d+)"))
                local texture = GetSpellTexture(slot, "spell")
                add(id, name, rank, texture, IsPassiveSpell and IsPassiveSpell(slot, "spell"))
            end
        end
    end
    table.sort(result, function(a,b) if a.name == b.name then return a.rank < b.rank end; return a.name < b.name end)
    S.catalog, S.highest = result, highest
    if S.RefreshDispelCapabilities then S.RefreshDispelCapabilities() end
    return result
end
function S.SpellName(id)
    if S.modern then local info = C_Spell.GetSpellInfo(id); return info and info.name end
    return GetSpellInfo(id)
end
function S.FindSpell(ids)
    for _, id in ipairs(ids) do
        local name = S.SpellName(id)
        if name and S.highest[name] then return S.highest[name] end
    end
end
-- Add an explicit recipient only where a macro has not already selected one.
function S.TargetMacro(body, unit)
    local lines = {}
    for line in (body .. "\n"):gmatch("(.-)\n") do
        local command, arguments = line:match("^(/[%a]+)%s+(.+)$")
        if command and (command:lower() == "/cast" or command:lower() == "/use"
            or command:lower() == "/castsequence" or command:lower() == "/castrandom") then
            local parts = {}
            for part in (arguments .. ";"):gmatch("(.-);") do
                if part:find("%[") then
                    part = part:gsub("%[([^%]]*)%]", function(condition)
                        if condition:find("@", 1, true) or condition:find("target=", 1, true) then return "[" .. condition .. "]" end
                        return "[@" .. unit .. (condition ~= "" and "," .. condition or "") .. "]"
                    end)
                else part = "[@" .. unit .. "] " .. part end
                parts[#parts + 1] = part
            end
            line = command .. " " .. table.concat(parts, ";")
        end
        lines[#lines + 1] = line
    end
    local text = table.concat(lines, "\n")
    if #text > 1023 then return nil, S.Text("Das Makro ist mit Zielbedingungen zu lang.", "The targeted macro is too long.") end
    return text
end
function S.BindingSpell(binding)
    if not binding or binding.kind ~= "spell" then return end
    if binding.rank == "fixed" then
        for _, spell in ipairs(S.catalog) do
            if spell.id == binding.id and (spell.id ~= nil or spell.name == binding.name) then
                binding.name, binding.rankName = spell.name, spell.rank
                return S.modern and spell.id or spell.name .. (spell.rank ~= "" and "(" .. spell.rank .. ")" or "")
            end
        end
        return -- A saved fixed rank must still be learned.
    end
    local name = binding.id and S.SpellName(binding.id) or binding.name
    local spell = S.highest[name]
    if spell then binding.name = spell.name end
    return spell and (S.modern and spell.id or spell.name)
end
function S.ApplyBindings(button)
    if InCombatLockdown() then return end
    button:RegisterForClicks("AnyUp", "AnyDown")
    -- The native CVar decides which edge fires on modern clients. Legacy uses Up.
    if not S.modern then button:RegisterForClicks("AnyUp") end
    local unit = button.unit
    for _, modifier in ipairs(modifiers) do
        for mouse = 1, 5 do
            local key = modifier .. mouse
            local binding = S.db.bindings[key]
            if binding then
                button:SetAttribute(modifier .. "type" .. mouse, "none")
                button:SetAttribute(modifier .. "spell" .. mouse, nil)
                button:SetAttribute(modifier .. "macrotext" .. mouse, nil)
                if binding.kind == "spell" then
                    local spell = S.BindingSpell(binding)
                    if spell then
                        button:SetAttribute(modifier .. "type" .. mouse, "spell"); button:SetAttribute(modifier .. "spell" .. mouse, spell)
                        if modifier == "" and mouse == 1 then
                            local resurrection = S.FindSpell({2006, 7328, 50769, 2008})
                            local combat = S.FindSpell({20484})
                            if resurrection or combat then
                                local options = {}
                                if combat then options[#options + 1] = "[combat,@" .. unit .. ",help,dead] " .. combat.name end
                                if resurrection then options[#options + 1] = "[@" .. unit .. ",help,dead] " .. resurrection.name end
                                local castName = binding.name
                                if binding.rank == "fixed" and binding.rankName and binding.rankName ~= "" then castName = castName .. "(" .. binding.rankName .. ")" end
                                options[#options + 1] = "[@" .. unit .. ",help,nodead] " .. castName
                                button:SetAttribute("type1", "macro"); button:SetAttribute("macrotext1", "/cast " .. table.concat(options, "; "))
                            end
                        end
                    end
                elseif binding.kind == "macro" then
                    local _, _, body = GetMacroInfo(binding.index)
                    local macro = body and S.TargetMacro(body, unit)
                    if macro then button:SetAttribute(modifier .. "type" .. mouse, "macro"); button:SetAttribute(modifier .. "macrotext" .. mouse, macro) end
                elseif binding.kind == "target" then button:SetAttribute(modifier .. "type" .. mouse, "target")
                elseif binding.kind == "menu" then
                    if S.modern then button:SetAttribute(modifier .. "type" .. mouse, "togglemenu")
                    else
                        if not S.unitMenu then S.unitMenu = CreateFrame("Frame", addonName .. "UnitMenu", UIParent, "UIDropDownMenuTemplate") end
                        button.menu = function(self)
                            local which = self.unit == "player" and "SELF" or self.suiteKind == "pet" and "PET" or self.unit:match("^party") and "PARTY" or "RAID_PLAYER"
                            UIDropDownMenu_Initialize(S.unitMenu, function() UnitPopup_ShowMenu(S.unitMenu, which, self.unit, UnitName(self.unit)) end, "MENU")
                            ToggleDropDownMenu(1, nil, S.unitMenu, "cursor", 0, 0)
                        end
                        button:SetAttribute(modifier .. "type" .. mouse, "menu")
                    end
                end
                button:SetAttribute(modifier .. "unit" .. mouse, unit)
            end
        end
    end
    if not button.suiteHover then
        button.suiteHover = true
        SecureHandlerWrapScript(button, "OnEnter", S.secureHeader, [[
            for index = 1, 14 do
                local key = self:GetAttribute("rhb-key" .. index)
                local action = self:GetAttribute("rhb-action" .. index)
                if key and key ~= "" then self:SetBindingClick(true, key, self:GetName(), action) end
            end
        ]])
        SecureHandlerWrapScript(button, "OnLeave", S.secureHeader, [[ self:ClearBindings() ]])
    end
    for index = 1, 14 do
        local key = index == 1 and S.db.wheelUp or index == 2 and S.db.wheelDown or S.db.keys[index - 2]
        button:SetAttribute("rhb-key" .. index, key or "")
        local action = "rhbkey" .. index
        button:SetAttribute("rhb-action" .. index, action)
        local binding = S.db.bindings[action]
        button:SetAttribute("type-" .. action, "none")
        button:SetAttribute("spell-" .. action, nil)
        button:SetAttribute("macrotext-" .. action, nil)
        button:SetAttribute("unit-" .. action, unit)
        if binding and binding.kind == "spell" then
            local spell = S.BindingSpell(binding)
            if spell then button:SetAttribute("type-" .. action, "spell"); button:SetAttribute("spell-" .. action, spell) end
        elseif binding and binding.kind == "macro" then
            local _, _, body = GetMacroInfo(binding.index)
            local macro = body and S.TargetMacro(body, unit)
            if macro then button:SetAttribute("type-" .. action, "macro"); button:SetAttribute("macrotext-" .. action, macro) end
        end
    end
end
function S.Position(root, buttons)
    if not S.db or InCombatLockdown() then return false end
    local p = S.Profile()
    p.height = math.max(p.height, S.RequiredFrameHeight(p))
    local counts, highest, mostRows = {}, 1, 1
    local raid = S.GroupType() == "raid"
    local normal, pets, positions = {}, {}, {}
    for _, button in ipairs(buttons) do
        if button.suiteKind == "target" then
            button:ClearAllPoints(); button:SetPoint("TOPLEFT", root, "BOTTOMLEFT", 8, -8)
        elseif button.suiteKind == "pet" then pets[#pets + 1] = button
        elseif (raid and button.unit:match("^raid%d+$")) or (not raid and (button.unit == "player" or button.unit:match("^party%d+$"))) then
            normal[#normal + 1] = button
        end
    end
    local function place(button, column, row, pet)
        local xSign = p.grow:find("RIGHT", 1, true) and -1 or 1
        local ySign = p.grow:find("BOTTOM", 1, true) and 1 or -1
        local width = pet and math.floor(p.width * .65) or p.width
        button:SetSize(width, p.height)
        if p.vertical then column, row = row, column end
        button:ClearAllPoints()
        local topInset = ySign == 1 and 8 or 40
        button:SetPoint(p.grow, root, p.grow, xSign * (8 + column * (p.width + 4)), ySign * (topInset + row * (p.height + 3)))
    end
    for index, button in ipairs(normal) do
        local group = 1
        if raid then group = select(3, GetRaidRosterInfo(tonumber(button.unit:match("%d+")))) or 1 end
        counts[group] = (counts[group] or 0) + 1
        place(button, group - 1, counts[group] - 1)
        positions[button.unit] = {group = group, row = counts[group] - 1}
        if UnitExists(button.unit) then highest = math.max(highest, group); mostRows = math.max(mostRows, counts[group]) end
    end
    local anyPet = false
    for index, button in ipairs(pets) do
        local owner = button.suiteOwner
        local ownerPosition = positions[owner]
        if ownerPosition then place(button, highest + ownerPosition.group - 1, ownerPosition.row, true) end
        if ownerPosition and UnitExists(button.unit) then anyPet = true end
    end
    local columns = highest + (S.db.showPets and anyPet and highest or 0)
    local w = p.vertical and mostRows or columns
    local h = p.vertical and columns or mostRows
    root:SetSize(math.max(180, 16 + w * (p.width + 4)), 46 + h * (p.height + 3))
    root:SetScale(p.scale)
    root:ClearAllPoints(); root:SetPoint(p.grow, UIParent, "CENTER", p.x / p.scale, p.y / p.scale)
    return true
end
function S.UpdateVisibility()
    if InCombatLockdown() then return end
    local kind = S.GroupType()
    local show = S.db.showFrames == "always" or S.db.showFrames == kind
    if S.root then if show then S.root:Show() else S.root:Hide() end end
    for _, button in ipairs(S.buttons) do
        if button.suiteKind == "pet" then
            local mode = button.unit:find("^raidpet") and "group:raid," or "nogroup:raid,"
            RegisterStateDriver(button, "visibility", S.db.showPets and ("[" .. mode .. "@" .. button.unit .. ",exists]show;hide") or "hide")
        elseif button.suiteKind == "target" then
            RegisterStateDriver(button, "visibility", S.db.showTarget and "[@target,help,exists]show;hide" or "hide")
        end
    end
end
function S.Apply()
    if InCombatLockdown() then S.pending = true; return end
    S.pending = false
    S.Spells()
    if S.root then S.Position(S.root, S.buttons) end
    for _, button in ipairs(S.buttons) do
        S.ApplyBindings(button)
        if button.suiteDisplay then S.DisplaysSize(button); if UnitExists(button.unit) then S.Auras(button) end end
    end
    S.UpdateVisibility()
    if S.RefreshNativeFrames then S.RefreshNativeFrames() end
    if S.RefreshPreview then S.RefreshPreview() end
    if S.UpdateToggleKey then S.UpdateToggleKey() end
    if S.UpdateOwnBuffs then S.UpdateOwnBuffs() end
    if S.UpdateQuickBuff then S.UpdateQuickBuff() end
end
function S.Start(root, buttons)
    S.Init(); S.root, S.buttons = root, buttons
    S.secureHeader = CreateFrame("Frame", addonName .. "SecureHover", UIParent, "SecureHandlerBaseTemplate")
    S.Spells()
    if S.DisplayInit then S.DisplayInit() end
    if S.BuffsInit then S.BuffsInit() end
    S.Apply()
end
local delayed, jobs = nil, {}
function S.Delay(key, seconds, callback)
    jobs[key] = {at = GetTime() + seconds, callback = callback}
    if not delayed then delayed = CreateFrame("Frame") end
    delayed:SetScript("OnUpdate", function(self)
        local ready = {}
        for id, job in pairs(jobs) do if GetTime() >= job.at then jobs[id] = nil; ready[#ready + 1] = job.callback end end
        for _, fn in ipairs(ready) do fn() end
        if not next(jobs) then self:SetScript("OnUpdate", nil) end
    end)
end
function S.After(callback)
    if S.buffRefreshScheduled then return end
    S.buffRefreshScheduled = true
    S.Delay("buff-refresh", .2, function() S.buffRefreshScheduled = false; callback() end)
end
