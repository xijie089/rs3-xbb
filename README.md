# XBB / Xijie Buff Bars

XBB shows your RuneScape buffs and debuffs as bars with names, countdowns,
and stack counts. No icons.

**Beta build. Awaiting Plugin Hub approval.**

Requires [PrettyUI](https://mod.io/g/runescape/m/prettyui).

## Getting started

1. Open RuneScape's **Settings > Gameplay > Interfaces > Buff Bar** and turn on
   the effects you want to track. XBB follows these filters.
2. Open **Plugins > XB > Open full settings**. The tab's full name is
   **Xijie Buff Bars**. You can also open settings through Plugin Hub.
3. Right-click a bar to hide or pin it. Buffs also offer **Warn when missing**.
4. To move the bars, hold **Ctrl**, left-click a header or bar, then move the
   mouse. Release **Ctrl** to save. The mouse button does not need to stay held.

The Plugins launcher has quick options for separate stacks, replacing the
original bars, and locking bar dragging.

| Settings tab | Controls |
| --- | --- |
| Display | Separate stacks, original bars, bar size and spacing, drag lock, position reset |
| Hidden | Restore hidden effects |
| Pins | Slot numbers, reservations, and unpinning |
| Missing | Missing-buff presets and custom warnings |
| Observed | Pin, hide, watch, or color effects XBB has seen |
| Colors | Default colors and individual overrides |

## Bars and timers

Buffs and debuffs share one stack by default. Enable **Separate buff/debuff
stacks** in Display to split them. Scroll over the bars if the list is too tall.

Pins take priority. The remaining effects sort in this order:

1. Untimed effects, alphabetically.
2. Timed effects, longest remaining duration first.
3. Effects whose timing cannot yet be read.

Untimed effects show **Active**. Countdowns show tenths below ten seconds,
seconds below one minute, then `m:ss` or `h:mm:ss`. Stack counts and percentages
appear before the name. Cooldowns are labelled **CD**.

XBB remembers effect durations and uses them when the game's timer is pending
or rounded. A `~` marks an estimate. A blank timer means no timing is available
yet; `?` means a previously readable timer has become unavailable.

Bars start full when XBB first sees an effect. Refreshes can refill them.
An effect stays visible while the game reports it, even if its countdown
reaches zero.

Hover over a bar for its description, when available. Long tooltips can be
scrolled.

## Colors

**Colors** sets the default color and opacity for buffs, debuffs, and missing
warnings. A category's **Reset** restores its original color.

Use **Observed > Custom color** to give an effect its own color. Custom colors
are listed below the defaults in Colors. **Reset**, or **Reset color** in
Observed, removes the override and restores the category color.

## Hiding and pins

Undo **Hide in XBB** with **Hidden > Restore** or **Observed > Unhide**.

Right-click a bar to pin its current slot, or use **Observed > Pin** to take
the first free slot. Change its slot or reservation in Pins.

- A reserved pin leaves a dim placeholder while the effect is absent.
- An absent pin without a reservation collapses.
- Hiding a pinned effect also hides its reservation.

Slots range from 1 to 100 per stack. Moving a pin into an occupied slot swaps
the two. Separate stacks have independent slots; combining them moves
collisions to the next free slot.

## Missing-buff warnings

Missing-buff warnings are off by default. Enable a preset in Missing, or choose **Warn when
missing** for a buff in Observed or its right-click menu.

Presets cover potions, pocket books, incense, combat powders, and other upkeep
buffs. Any matching overload satisfies the overload preset. A pocket book
needs an active buff; equipping it alone does not count.

Use **Remove warning** in Observed, **Remove missing warning** in the right-click
menu, or **Missing > Delete** to remove a custom warning. Presets can be enabled
or disabled instead.

Warnings also show outside combat. Hidden buffs still count as present.
Warnings pause when XBB cannot read the native bars. Presets match English
names; custom warnings track the selected effect. Not every preset variant
has been checked in-game.

## Position and dragging

Buffs and debuffs keep separate positions when split. The combined stack uses
the buff position. **Display > Reset positions** resets both bar stacks, not
the settings window.

Drag the settings window by its title bar. Window and bar positions are saved
between sessions.

## Local data and native bars

XBB requests no permissions and sends no data to external services. Settings
and observed effect data are saved locally through `PersistentDB`.
See [MODIO.md](MODIO.md#required-disclosures) for the full disclosures.

**Replace original bars** hides the game's bars while XBB is running. The
originals return if XBB cannot read them, when you log out, or when the plugin
stops.

Unnamed effects show **Unknown buff #123** or **Unknown debuff #123**.
Errors and diagnostic details are written to the client console.

## Build and install

Requires Lua 5.4, `luac`, and Make:

```sh
git clone https://github.com/xijie089/rs3-xbb.git
cd rs3-xbb
make package
```

Copy `dist/XBB/` to `dev_plugins/XBB/` in the beta client's cache folder:

| Installation | Cache folder |
| --- | --- |
| Windows | `C:\ProgramData\Jagex\RuneScape-BETA` |
| Linux / Bolt | `~/.local/share/bolt-launcher/Jagex/RuneScape-BETA` |

For Steam/Proton, use `RuneScape-BETA` beneath the game's installation directory.

Open the beta console with Alt + the key beneath Escape. Run `prf` to refresh
the plugin list, `pon XBB` to enable XBB, and `prl XBB` to reload it.

## Development

```sh
make test       # Lua tests and syntax checks
make package    # Test and assemble dist/XBB
make submission # Also build dist/XBB.zip
```

The ZIP target requires Python 3. The archive contains `main.lua`, `plugin.json`,
and `xbb/` at its root.

To run the settings tests against an extracted PrettyUI release:

```sh
lua tests/prettyui_contract.lua /path/to/prettyui
```

## Feedback and collaboration

Use the [XBB Discord channel](https://discord.com/channels/1523582684109082645/1561934868353384458)
for issue reports and collaboration requests.

## Release files

[CHANGELOG.md](CHANGELOG.md) covers each version.
[MODIO.md](MODIO.md) contains the listing text and required disclosures.

The listing banner is [media/listing.png](media/listing.png). Its editable source
is [media/listing.svg](media/listing.svg), using the client capture
[media/native-bars.png](media/native-bars.png).
