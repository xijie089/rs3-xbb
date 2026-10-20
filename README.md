# XBB / XijieBuffBars

A Lua RuneScape plugin that displays your buffs and debuffs as stacked,
decreasing progress bars with names and readable countdowns. No icons.

**Beta development build; not yet approved for Plugin Hub distribution.**

## Installation

Build from source with Lua 5.4, `luac`, and Make:

```sh
git clone https://github.com/xijie089/rs3-xbb.git
cd rs3-xbb
make package
```

Copy `dist/XBB/` to `dev_plugins/XBB/` within your beta client's cache folder.
The official tutorial lists these example locations:

| Installation | Cache folder |
| --- | --- |
| Windows | `C:\ProgramData\Jagex\RuneScape-BETA` |
| Linux / Bolt | `~/.local/share/bolt-launcher/jagex/RuneScape-BETA` |

For Steam/Proton, use the `RuneScape-BETA` folder beneath the game's installation
directory.

Open the beta client console with Alt + the key beneath Escape. Refresh the
plugin list with `prf`, enable with `pon XBB`, and reload with `prl XBB`.
Open settings from the XBB header or the Plugin Hub settings icon.

## Getting started

1. Open RuneScape's **Settings > Gameplay > Interfaces > Buff Bar** and turn on
   the items you want to track. XBB follows these visibility filters.
2. Open XBB settings using the **Settings** button on the buff header or the
   Plugin Hub settings icon. **Display** controls bar size, combined or separate
   stacks, and **Replace original bars**.
3. Right-click a bar to hide or pin it. A pinned bar also offers **Reserve slot
   when absent**. For buffs, **Warn when missing** adds an optional reminder.
4. Hold **Ctrl** and left-click a header or bar to move its stack. Release
   **Ctrl** to save the position.

XBB requests no permissions and has no external plugin dependencies. Settings
and observed effect metadata (identities, original and short names, and hover
text) are saved locally between sessions through `PersistentDB`. XBB does not
transmit data or collect information about other players.

## Ordering and appearance

Unpinned effects sort as follows:

1. Untimed effects, alphabetically.
2. Timed effects, longest remaining duration to shortest.
3. Effects whose remaining duration cannot yet be read.

Untimed means no readable duration is supplied, not that an effect can never
end. These bars show **Active**. Timed bars show tenths below ten seconds,
seconds below one minute, then `m:ss` or `h:mm:ss`. Stack counters are shown
before the name without a multiplier prefix (for example, **5 Incite Fear**
or **30 Bone Shield**), never interpreted as seconds.
Percentage values retain their unit, for example **6% Clan avatar boost**.
New bars leave the timer blank until timing is first resolved. If previously
resolved timing becomes unreadable, the timer shows `?`.

Bars use native ability titles where available and shorten Aftershock to
**47% Aftershock**, for example. Hover details appear only when the full text
differs from the displayed name, not just because of a count or percentage prefix.
Long native hover details can be scrolled. Quiver bars show the selected
ammunition, for example **Quiver: Bik arrows**, and update when it changes.
Full native hover text takes precedence over shorter descriptions. Some effects
use a built-in explanation when the API does not expose their full description.
XBB includes compact names for 275 effects.
Cooldowns use **CD**, including **Ritual shard CD** and **Excalibur CD**.
Distinct effects retain separate labels, such as legendary-pet ability
cooldowns and Deep Sea Fishing bonuses. Stack and percentage prefixes remain
separate from the short name; full native details remain available on hover.

Progress uses the native total duration when available. Otherwise it uses the
longest remaining duration observed for that activation. Refreshes can refill a
bar. A countdown reaching zero does not remove a still-observed native effect.
Small countdown corrections blend smoothly; refreshes and native zero readings
apply immediately.

Buffs and debuffs share one stack by default. **Settings > Display** can split
them into independently positioned stacks. The single-line header reads
**XBB / Buffs / Debuffs** when combined, or **XBB / Buffs** and **XBB / Debuffs**
when separated. A second line appears only for source warnings or drag status.
The Settings button appears only on the buff/combined panel.
The settings window header reads **XBB / Xijie Buff Bars / {Tab}**.
Debuffs are rose-coloured; missing-buff warnings are
red and explicitly labelled **Missing**. Width, height, spacing, and native HUD
position are configurable. Scroll over native bars when the list exceeds the
available height.

In the native client, hold **Ctrl**, then **left-click** a stack's header or
one of its bars to start moving it. Move the mouse while keeping Ctrl held;
the mouse button does not need to stay down. Release **Ctrl** to save.
Dragging preserves the grab offset, accounts for interface scaling, and keeps
the stack within the game area. Buffs and debuffs remember independent positions
when separated; the combined stack uses the buff position.
**Settings > Display > Lock dragging** disables Ctrl-click movement.
**Reset positions** restores both stacks without changing other settings,
including the drag lock.

## Hiding and pins

**Hide in XBB** hides that effect across subsequent appearances and reloads.
**Settings > Hidden > Restore** makes it eligible to appear again.

Pins override automatic sorting. Right-click a bar to pin its current slot;
**Settings > Pins** changes its slot and reservation or removes the pin.
In the native **Observed** page, **Pin** selects the first free slot in that
effect's stack. The controls switch to **Unpin** and **Unhide** for pinned or
hidden effects, so both actions can be undone without leaving Observed.
Open settings refresh after bar-menu actions without changing tabs. Hidden,
Pins, Missing, and Observed use the same compact names as the bars, including
previously saved entries. Custom missing bars and reserved pins use those names too.

- An active pin occupies its configured slot.
- A **reserved** pin leaves a dim, labelled placeholder while absent.
- A non-reserved absent pin collapses, shifting later pins up one slot.
- Hiding a pinned effect suppresses its reservation too. Restoring it retains
  its pin configuration.

Slots range from 1 to 100 per stack. Moving into an occupied pin slot swaps
the two pins. Separate stacks have independent positions. When combining them,
colliding positions move to the next free slot in stable identity order.

Effect identity uses the native buff struct ID when available, otherwise
the effect's name and buff/debuff category. It does not use the changing
on-screen icon slot. Name-based identities can change with client language.

## Missing combat buffs

Missing checks start disabled. A missing effect is displayed as an untimed
pseudo-debuff, for example **Missing: Overload** or **Missing: Pocket book**.
It can be hidden and pinned like any other row.

**Settings > Missing** contains nineteen upkeep presets: overload variants,
pocket books/scriptures/grimoires, weapon poison, antifire, antipoison, prayer
renewal, aggression, familiar, Animate Dead, Darkness, bonfire boost,
five incense types, and three combat powders. Any matching member satisfies
a preset; an elder overload does not require a regular overload as well.
Pocket-book checks look for an active buff, not an equipped inventory item
or the occasional damage proc.

Coverage is not limited to these presets or to Magic. **Any observed combat
buff** can be watched using **Warn when missing** or **Settings > Observed**,
including prayers, ability buffs, stacks, and buffs added in later game
updates. Observed identities are saved so inactive effects remain configurable.
Observed displays and sorts by short names, with a **Buff** or
**Debuff** label. Compact names and available hover details
are retained across settings reloads; original names and effect identities stay
unchanged.

Preset families use English display-name matching. Exact client names and the
meaning of each native activation indicator still need beta verification;
the preset list is not a claim that every variant has been verified in-game.
Custom observed-buff monitors use effect identity instead.
In **Observed**, **Warn when missing** adds a custom warning and **Remove warning**
deletes it. The equivalent right-click action is **Remove missing warning**.
Custom warnings also have a **Delete** action in **Missing**;
deletion clears the warning's reserved pin and hidden state without changing the
original buff's settings. Global presets retain their enabled/disabled controls.
While an active buff's name is unavailable, name-based family checks pause to
avoid false missing warnings. Exact-identity monitors continue to work, and
family checks resume when every active buff has a known name.

Warnings use actual observed buff presence, even if its bar is hidden in XBB.
They do not activate abilities, select a prayer or combat style, or predict
upcoming mechanics. All missing warnings are suppressed when the source is
unavailable. They are not restricted to being in combat.

## Native integration

Native buff scans run after server updates. Layout and labels update at 10 Hz;
countdowns and drag input update at the 50 Hz client-logic cadence. Repeated
rounded timer samples retain their expiry. Downward corrections of at most one
second blend over two seconds; increases, larger corrections, and zero readings
apply immediately.

`xbb/short_names.lua` holds the compact names, struct IDs, original text, and
optional heading aliases. Native effect configs take precedence, followed by
stable effect IDs, including absent reserved pins. Full-text lookup ignores
case and surrounding spaces. Heading aliases match text before a colon or line
break; all lookup tables are derived from the same entries.
Title-only effects use `COMBATV2_ABILITY_INFO` description fields, including
Bone Shield and Gladiator's Rage. Scripted effects without an exposed
description use `nativeDetails` in `xbb/catalog.lua`; Searing Winds describes
its 20% bonus ranged damage.

The native adapter uses documented UI inspection APIs to read the built-in
`BUFF_BAR` and `DEBUFF_BAR` slots,
their names, typed progress overlays, and visible timer text. The exact
component/metadata layout is provisional.
Known structs without an ability-name parameter have explicit display names in
`xbb/catalog.lua`, including the clan avatar boost and pocket-book activation.
Client-provided names take precedence, followed by referenced item display
names. When a book uses an object override but exposes no readable override
item, the active book timer uses the item in the worn pocket slot instead.
Its remaining charge comes from the native client book-timer end variable,
converted from 50 Hz client-clock units to seconds. If that inventory or timer
data is unavailable, the name falls back to **Pocket book** and the timer stays
blank initially, or shows `?` after earlier successful readings.
Selected quiver ammunition comes from the typed `QUIVER_ACTIVE_AMMO` player
variable. An unreadable selection is labelled **Quiver ammo (unavailable)**.
Other unnamed effects display **Unknown buff #123** or
**Unknown debuff #123**, using their stable struct ID. Their bars, readable
timers, hiding, pins, and identity-based monitors still work. A nonblocking
status warning reports unavailable names; internal config names are not
converted into guessed display names. A slot without either a name or a
stable identity remains a source error.
Visible layout containers with no visible content, name, buff metadata, or
actions are empty slots, not unnamed effects. Unrelated layout parameters do
not establish an active buff. Child visibility is read locally, independently
of ancestor visibility.

The adapter reads the fifty exposed slots in each bar. Buffs suppressed by the
game's own visibility filters are not observable through this source. Open
**Settings > Gameplay > Interfaces > Buff Bar** and turn on the items you want
XBB to track.

The original render layers and their visible components are made transparent
only after a complete readable snapshot. Icons, timer labels, and progress
overlays are updated individually rather than relying on inherited opacity.
They remain active so native timers keep updating while XBB replaces their visuals.
Opacity is reapplied on each [draw event](https://developer.runescape.com/rs/core/events.html#draw)
after a visual-only walk of both bars' fifty slots. Newly created icons and
labels are discovered on the next draw instead of waiting for a server update.
These frame updates do not read buff metadata or timers or rebuild XBB's layout.
On source failure, replacement is disabled, the original opacity is restored,
an error is displayed/logged, and missing warnings are suppressed. The original
opacity is also restored on logout, disable, or shutdown.
An unnamed effect logs an `XBB diagnostic:` line in the client console with
its visible component types, labels, and available metadata. Diagnostics are
logged once per unchanged warning or error until recovery, with the first
unnamed effect's details when multiple names are unavailable.

Numeric-only text is treated as seconds only when metadata identifies it as
non-stack content. Unsupported text remains unknown rather than inventing a
duration. Legacy `paramsConfig` metadata access is documented as potentially
removable; this adapter may need updates as the API evolves.

## Development

```sh
make test       # Lua model, native adapter, UI/lifecycle mocks, syntax
make package    # Validate and assemble dist/XBB
make submission # Also create dist/XBB.zip for Mod.io
```

Local checks require `lua`, `luac`, and Make. The beta client runs Lua 5.4.8.
The submission target additionally uses Python 3's standard-library ZIP tool;
no Python packages are required. Packaging recreates `dist/XBB/` from runtime
source files so removed modules cannot remain in the output.
The test suites exercise model behavior and the native UI through mocks.
Use the beta client to verify actual rendering, native timer updates, and
RuneScape API integration.

## Mod.io submission

Version **0.1.0** has been submitted to Mod.io and is awaiting moderation.
[`MODIO.md`](MODIO.md) records the listing fields, submitted description, and
required disclosures. [`media/listing.png`](media/listing.png) is the 1280x720
listing artwork; its editable source is [`media/listing.svg`](media/listing.svg), which uses the
native-client crop [`media/native-bars.png`](media/native-bars.png). The banner
combines branding with an actual XBB capture. Additional native captures can be
used for the gallery.

`make submission` builds `dist/XBB.zip` with `main.lua`, `plugin.json`, and `xbb/`
directly at the archive root. The Mod.io upload form offers Windows, Mac, Linux,
and Source as platform selections.

Combat overlays, missing-buff reminders, and menu customization are subject to
additional review. Submission does not constitute moderation approval.
