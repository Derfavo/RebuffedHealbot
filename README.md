# RebuffedHealbot

Party and raid healing frames with click casting, hover keys, buff reminders and separate layouts for solo play, parties and raids. Supports WoW 3.3.5a and WoW Forever's Interface 16001 client.

## Installation

Close WoW before replacing the addon. Keep the folder name `RebuffedHealbot`.

- **3.3.5a:** copy the addon folder into `Interface/AddOns/`. The included main TOC loads the original-client version.
- **WoW Forever:** copy the folder into `_forever_/Interface/AddOns/`, then copy `RebuffedHealbot_Forever.toc` over `RebuffedHealbot.toc` inside it. The Forever download package already has the correct main TOC.

For GitHub's Source code ZIP, use the addon folder inside the archive, not the outer repository folder. Settings remain in `ChronixHealDB` for compatibility. Each game installation keeps its own settings.

## Frames and layouts

Open `/rhb`, the header settings button or the minimap icon. Search finds options across all pages. Solo, party and raid layouts have separate width, height, scale, position, growth corner and group direction. The preview cycles through 5, 10, 20 and 40 sample players.

Raid frames follow the actual subgroups and roster order, including offline members. Pets have smaller frames aligned with their owners in a separate bank. An optional frame shows a friendly target. You can limit visibility to a group type and hide Blizzard's group frames while the addon grid is visible.

Drag the header outside combat to move the current layout. On Forever you can also drag it while Edit Mode is open; size and growth remain in `/rhb`. The grid is a separate addon frame, not a registered Blizzard Edit Mode system.

Frames show health, mana, aura timers, range fading, threat borders, a target outline, actual raid markers, ready checks and supported resurrection/summon status. Health can use class colors, green or a gradient, with percentage, absolute or missing-health text.

## Clicks, keys and macros

Configure mouse buttons 1–5 with Shift, Ctrl, Alt and their combinations. Mouse-wheel actions and twelve hover keys are available on the Keys page. Hover keys apply while the pointer is over a healing frame and release when it leaves. Quick Buff and grid visibility also have optional keys.

Choose a learned spell, macro, targeting or player menu. Spells normally use the highest learned rank; the picker can select an exact rank instead. An unlearned fixed rank is not silently replaced. A normal left-click spell binding keeps resurrection for dead friendly players, including a learned Druid combat resurrection.

Macro bindings copy the current macro body for each frame. Untargeted `/cast`, `/use`, `/castsequence` and `/castrandom` lines receive that frame's unit. Explicit targets such as `@focus` and `@player` stay intact. Other commands retain their normal behavior, and the original macro is unchanged. Binding and protected layout changes wait until combat ends.

On 3.3.5a, existing class bindings remain the defaults until overridden. Suggestions that conflict with a custom binding are suppressed. The older threshold and tank controls remain under Interface → AddOns.

## Healing and mana displays

Green segments show incoming direct healing, darker green shows supported own HoT healing, and light blue shows absorbs. Orange and blue edges indicate healing or absorbs beyond the available display space. Your mana bar can show a cast's cost and a five-second indicator after a successful mana-cost spell.

| Prediction | WoW 3.3.5a | WoW Forever |
| --- | --- | --- |
| Incoming direct healing | Native API if available, otherwise loaded LibHealComm-4.0 | Native heal prediction calculator |
| Remaining own HoT healing | Loaded LibHealComm-4.0 | HoT icons and timers; no separate remaining-healing amount |
| Absorb amounts | Native API if available, otherwise loaded AbsorbsMonitor-1.0 | Native heal prediction calculator |

The optional libraries are not bundled. Without a provider, that amount stays empty. LibHealComm depends on other healers sharing casts; its formulas may differ from private-server custom spells. AbsorbsMonitor values are estimates.

Forever's protected values go directly to native bars, text, cooldowns and color curves. They do not drive hidden healing decisions or automatic casts. Restricted buff readings and spell costs cannot be inferred, and exact remaining HoT healing is not fabricated from tooltips.

## Quick Buff and reminders

Quick Buff selects a missing or expiring buff and a friendly recipient outside combat. Left-click once per cast. It considers learned spells, group members and optionally your friendly target. When enough recipients need a buff in the same applicable group, it chooses the learned group version. You still need its mana and reagents. Quick Buff never changes recipients or casts by itself during combat.

The Buffs page has tracked-buff switches, refresh and group-spell thresholds, Thorns recipients, Shaman shield/weapon choices, and Paladin blessings by class or assigned role. Off-hand Shaman reminders require a weapon. A question mark marks a player missing a tracked buff; this can be disabled. Right-drag Quick Buff outside combat to save a separate position.

On 3.3.5a, the existing personal reminder bar follows your class and talent tree. Small icons stay visible and clickable. A missing buff or one remaining charge gets a red border, golden pulse and twinkling sparks. Left-click refreshes the buff, poison or weapon effect. Right-drag outside combat moves the bar independently.

Original-client reminders cover all ten classes, including Rogue poisons, Shaman weapon buffs, Paladin seals/auras, Priest Shadow effects, Warlock Soul Link, Hunter aspects and Death Knight presences. Only learned spells are offered. Poisons must be in your bags. Existing temporary weapon effects are accepted when their exact type cannot be identified. Permanent enchants and Runeforging are not monitored.

Forever has a spell-based personal reminder row for its supported Quick Buff selections, including Shaman weapon effects. Secure actions stay fixed in combat; readable buff states and native charge curves update the warning. It does not include the original-client Rogue poison inventory selection or the full talent-specific reminder list. Each icon can be right-dragged outside combat and remembers its position.

## Original-client healing suggestions

The 3.3.5a version retains Restoration Shaman, Holy Paladin, Discipline/Holy Priest and Restoration Druid suggestions, plus Mage curse removal. **S**, **M** and **F** select Safe Mana, Mixed and Full Heal. Other classes can use targeting and custom bindings.

Automatic tank selection uses Dungeon Finder roles and raid main-tank assignments. Manual tank, focus and solo-self fallbacks remain available. Skull and cross role indicators do not set shared raid markers. The addon does not repeatedly inspect everyone's talents.

Suggestions use fixed priorities. They do not predict boss abilities, line of sight or exact distances. Prediction bars provide extra information; they do not make the older suggestion engine account for incoming heals. Forever uses click casting and displays rather than running the original numeric suggestion engine on protected health values.

Use `/rhb mode safe`, `/rhb mode mixed` or `/rhb mode full` on 3.3.5a. Its automatic English “Out of Mana!” yell only runs in a party or raid, once per continuous period of insufficient mana.

## Updates

Versions use `major.minor.patch`. Update notices run automatically inside WoW through hidden addon messages with party, raid and guild members. Two different players must confirm a newer release. Confirmed versions are remembered for later logins. `/rebuffedupdates` shows installed versions and confirmed updates.

There is no Windows helper, direct GitHub connection from WoW or automatic installation. Download updates from [Releases](https://github.com/Derfavo/RebuffedHealbot/releases).

## Upgrading from ChronixHeal

Close WoW and remove `Interface/AddOns/ChronixHeal` so both copies cannot load. To retain settings, copy `WTF/Account/<Account>/SavedVariables/ChronixHeal.lua` to `RebuffedHealbot.lua` in the same directory, backing up an existing destination first. Keep the `ChronixHealDB` name inside the file. `/chheal` and `/chronixheal` remain available on 3.3.5a.

## Credits and compatibility

The additional features were independently implemented from HealKit's published descriptions. No HealKit code or artwork is included. This is not a complete one-for-one port: the client sections and prediction table describe the differences and API limits.

Client integration follows Blizzard's [3.3.5 secure templates](https://github.com/tekkub/wow-ui-source/blob/3.3.5/FrameXML/SecureTemplates.lua) and [Forever UI sources](https://github.com/Gethe/wow-ui-source/tree/forever). Original healing priorities draw on the Warmane guides for [Shamans](https://forum.warmane.com/printthread.php?page=1&pp=15&t=271702), [Paladins](https://forum.warmane.com/showthread.php?t=325569), [Priests](https://forum.warmane.com/showthread.php?t=334926) and [Druids](https://forum.warmane.com/showthread.php?t=325633).
