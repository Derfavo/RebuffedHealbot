# Changelog

## 0.7.1

- Increase buff and debuff icons to 20 pixels by default and add an icon-size setting.
- Wrap aura icons into rows and reserve enough frame height for them.
- Keep outlined timer and stack text above the cooldown animation and enable Forever countdown numbers explicitly.
- Remove companion frames from both client versions, including previously enabled companion settings.

## 0.7.0

- Add a separate WoW Forever client version alongside WoW 3.3.5a.
- Add mouse buttons 4 and 5, wheel actions, twelve hover keys, targeted macro bindings and fixed spell ranks.
- Add incoming-heal, absorb and supported HoT displays, mana-cost previews and a five-second indicator.
- Add pet frames, a friendly-target frame, ready checks, raid markers and additional status indicators.
- Add Quick Buff with recipient selection, group-buff thresholds and class/role blessing choices.
- Add separate solo, party and raid layouts, growth corners, vertical groups, searchable settings and frame previews.
- Keep existing 3.3.5a bindings, healing suggestions, tank controls and personal reminders.
- Use native Forever displays for protected values. Exact remaining HoT amounts and the complete original-client personal reminder list are not available in the Forever version; see the README for client differences and optional prediction providers.

## 0.6.8

- Arrange raid frames by their actual raid subgroup, with one column per group.
- Keep offline members in their group and preserve the order within each subgroup.
- Apply group moves made during combat after combat ends.

## 0.6.7

- Prevent guild version messages when the character has no confirmed guild membership.
- Handle numeric zero membership flags and wait for a nonempty guild name.
- Recheck membership before sending a delayed message.

## 0.6.6

- Add a pulsing golden glow and twinkling sparks to missing or low-charge personal buffs.
- Stop effects when the buff is restored or the warning no longer applies.
- Keep the compact icon click areas and use native animations without another Lua ticker.

## 0.6.5

- Replace the external checker with automatic version exchanges inside the game, following DBM's approach.
- Require reports from two different players before warning about a newer release.
- Remember confirmed newer versions for later logins.
- Remove the Windows checker and its setup tools. Downloads remain manual.


## 0.6.4

- Publish the addon in its own repository with stable version tags and release notes.
- Add login notices for newer releases found by the optional background checker.
- Add `/rebuffedupdates` to show installed versions and cached check results.
- Keep downloads and installation manual.
