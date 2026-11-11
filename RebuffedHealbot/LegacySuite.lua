local addonName, addon = ...
local S = addon.suite
addon.suiteLayout = function(root, buttons) if not S.db then return false end; return S.Position(root, buttons) end
addon.suiteRender = function(button)
    if not button.suiteDisplay then return end
    S.UpdateDisplay(button)
    if button.recommendation and addon.suiteOriginalBinding then
        local original, spell = addon.suiteOriginalBinding(button.recommendation)
        local override = original and S.db.bindings[original.prefix .. original.button]
        if override and not (override.kind == "spell" and override.rank ~= "fixed" and spell and override.name == spell.name) then
            button.recommendation = nil; button.icon:Hide()
            button.actionText:SetText(S.Text("Eigene Belegung", "Custom binding"))
        end
    end
    if button.state and button.state.dead and S.db.bindings["1"] and S.db.bindings["1"].kind ~= "spell" then
        button.icon:Hide(); button.actionText:SetText(S.BindingDescription(S.db.bindings["1"]))
    end
    for _, slot in ipairs(button.auraSlots or {}) do slot:Hide() end
    if button.debuffIcon then button.debuffIcon:Hide() end
end
addon.initializeSuite = function(root, buttons, createButton, refreshSpells)
    S.Init()
    createButton("pet", 1, "[group:raid]hide;[@pet,exists]show;hide"); buttons[#buttons].suiteKind, buttons[#buttons].suiteOwner = "pet", "player"
    for i = 1, 4 do
        local unit = "partypet" .. i
        createButton(unit, 1, "[group:raid]hide;[@" .. unit .. ",exists]show;hide")
        buttons[#buttons].suiteKind, buttons[#buttons].suiteOwner = "pet", "party" .. i
    end
    for i = 1, 40 do
        local unit = "raidpet" .. i
        createButton(unit, 1, "[group:raid,@" .. unit .. ",exists]show;hide")
        buttons[#buttons].suiteKind, buttons[#buttons].suiteOwner = "pet", "raid" .. i
    end
    createButton("target", 1, "[@target,help,exists]show;hide"); buttons[#buttons].suiteKind = "target"
    -- New secure buttons need the same original class defaults as the existing grid.
    refreshSpells()
    for _, button in ipairs(buttons) do S.AttachDisplay(button, button.health) end
    S.Start(root, buttons)
    addon.settingsActions.restoreGrid = function()
        if InCombatLockdown() then S.Print(S.Text("Nach dem Kampf zur\195\188cksetzen.", "Reset after combat.")); return end
        local p = S.Profile(); p.grow, p.x, p.y = "TOPLEFT", -root:GetWidth() * p.scale / 2, root:GetHeight() * p.scale / 2
        S.db.showFrames = "always"; S.Apply()
    end
    S.ExtrasInit()
    local events = CreateFrame("Frame")
    for _, event in ipairs({"RAID_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "UPDATE_MACROS"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent", function() if InCombatLockdown() then S.pending = true else S.Apply() end end)
end
