# RebuffedHealbot

RebuffedHealbot displays your party or raid in healing frames for up to 40 players. Click bindings cast your chosen spells, while suggestions help you choose heals, dispels and tank buffs. In-game text is available in English and German.

## Healing frames

Raid columns follow the actual raid subgroups, from group 1 to group 8. Members stay in roster order within their subgroup, including offline players. Group moves made during combat appear after combat ends.

The **S**, **M** and **F** buttons select Safe Mana, Mixed and Full Heal. Safe Mana favors economical healing, Mixed uses your configured thresholds, and Full Heal responds to smaller health deficits. You can switch modes in combat.

Open settings through `…`, the minimap icon or **Interface → AddOns → RebuffedHealbot**. You can assign learned spells to click combinations outside combat. Bindings appear below each player's name and in the tooltip.

Drag the header to move the frame when it is unlocked in settings. Right-click the minimap icon to show and center the frame outside combat.

Healing suggestions support Restoration Shamans, Holy Paladins, Discipline and Holy Priests, and Restoration Druids. Mages can remove curses. Other classes can use the group frames to select targets.

## Tanks and roles

Automatic tank selection uses assigned Dungeon Finder roles and the raid leader's main tank assignments. You can also choose a tank manually in the tank menu. If no tank is assigned, the addon falls back to your focus target, or to your own character when solo.

Skull and cross icons identify tanks and healers inside the healing frames. They do not set shared raid target markers. The addon does not continually inspect other players' talents to determine their roles.

## Personal buffs

A separate bar shows small buff icons that remain visible and clickable. The selection follows your class and the talent tree with the most points. Only learned spells are offered.

A red border, pulsing golden glow and two twinkling sparks mean a buff is missing or has only one charge left. The effects stop as soon as the buff is restored, while dead or when the reminder is no longer relevant. The glow does not enlarge the clickable area. Animations use the client's native animation system without an extra Lua update loop. Active buffs remain visible with a neutral border. Left-click to refresh the buff on yourself or apply the poison or weapon buff to its assigned weapon slot. The icons also work in combat. Outside combat, hold the right mouse button and drag an icon to move the entire bar independently of the healing frame.

| Class | Examples |
| --- | --- |
| Shaman | Water Shield or Lightning Shield, plus weapon buffs for your specialization |
| Rogue | Instant Poison on the main hand and Deadly Poison on the off hand, when available |
| Priest | Inner Fire, Fortitude, Divine Spirit and Shadow Protection; Shadow also adds Shadowform and Vampiric Embrace |
| Paladin | Seal, aura and blessing; Protection also adds Righteous Fury |
| Mage | Armor and Intellect |
| Warlock | Armor and learned Soul Link with a living pet |
| Druid | Mark of the Wild; Feral also adds Thorns |
| Warrior | Battle Shout or Commanding Shout |
| Hunter | Aspect and learned Trueshot Aura |
| Death Knight | Presence and Horn of Winter |

Poisons must be in your bags. The original client cannot reliably identify the exact type of an existing temporary weapon buff, so an existing effect is accepted. Permanent enchants and Runeforging runes are not monitored.

## Commands and mana warning

- `/rhb mode safe`
- `/rhb mode mixed`
- `/rhb mode full`

You can use `/rebuffedhealbot` instead of `/rhb`. The automatic “Out of Mana!” message is sent in /yell only while you are in a party or raid, at most once per continuous period of insufficient mana.

## Limitations

Suggestions use fixed priorities. They do not predict boss abilities, check line of sight, account for incoming heals from other players or measure the exact distances between group members. The list of dispel exceptions is incomplete. You still need to decide whether a suggested spell fits the situation. Heals and buffs always require your own click.

Priorities draw on the Warmane guides for [Shamans](https://forum.warmane.com/printthread.php?page=1&pp=15&t=271702), [Paladins](https://forum.warmane.com/showthread.php?t=325569), [Discipline Priests](https://forum.warmane.com/showthread.php?t=334926), Holy Priests ([guide 1](https://forum.warmane.com/showthread.php?t=448147), [guide 2](https://forum.warmane.com/showthread.php?t=56440)) and [Druids](https://forum.warmane.com/showthread.php?t=325633). The three modes are a separate implementation based on those guides.

Weapon buff queries and secure click actions follow the interfaces in Blizzard's 3.3.5 UI code: [BuffFrame.lua](https://github.com/tekkub/wow-ui-source/blob/3.3.5/FrameXML/BuffFrame.lua) and [SecureTemplates.lua](https://github.com/tekkub/wow-ui-source/blob/3.3.5/FrameXML/SecureTemplates.lua).

## Upgrading from ChronixHeal

RebuffedHealbot is the new name of ChronixHeal. Close WoW and remove the old `Interface/AddOns/ChronixHeal` folder so both versions cannot load together. Install the `RebuffedHealbot` folder, then restart WoW.

To keep your settings, copy `WTF/Account/<Account>/SavedVariables/ChronixHeal.lua` to `RebuffedHealbot.lua` in the same directory while the game is closed. Back up any existing `RebuffedHealbot.lua` first. Leave the `ChronixHealDB` table name inside the file unchanged. The old `/chheal` and `/chronixheal` commands still work.

## Versions and update notices

Stable versions are published as GitHub Releases using `major.minor.patch` tags. The first number changes for incompatible changes, the second for new features, and the third for fixes. See [Releases](https://github.com/Derfavo/RebuffedHealbot/releases) for downloads and release notes.

Update detection runs entirely inside WoW, using the same approach as DBM: addon messages exchange installed versions with other users in your party, raid and guild. Checks start automatically at login and when group or guild membership changes. Messages are hidden addon traffic, not ordinary chat. Replies are delayed and throttled to avoid repeated traffic during raid invites.

A newer version must be reported by two different players before the addon warns you. Future release dates are rejected. Confirmed versions are saved, so the notice can also appear at later logins. Each addon warns at most once per newer version per session. `/rebuffedupdates` shows your installed versions and any confirmed updates.

This does not contact GitHub or check a central server. If nobody you meet has a newer copy, the addon cannot know that a new release exists. No Windows task, external checker or automatic installation is used. DBM itself is not required.

To update, download the latest release's source ZIP, close WoW, extract it and copy the `RebuffedHealbot` folder into `Interface/AddOns/`, replacing the previous folder. Do not copy the outer repository folder. Your settings in WTF remain untouched.
