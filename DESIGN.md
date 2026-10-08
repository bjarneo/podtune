---
name: Podtune
description: A native Linux tuning bench for the RØDE PodMic USB, drawn as a tick-scale instrument.
colors:
  dark-background: "#17191c"
  dark-surface: "#1d1f23"
  dark-foreground: "#f0f1f3"
  dark-secondary: "#b8b9bb"
  dark-border: "#3e4043"
  dark-line: "#2c2e32"
  dark-tint: "#2a2925"
  dark-accent: "#d0b675"
  dark-high: "#e5a083"
  dark-scrim: "#0607088c"
  dark-mark-rest: "#4b4d50"
  light-background: "#f4f5f7"
  light-surface: "#fbfcfe"
  light-foreground: "#20242a"
  light-secondary: "#575a5f"
  light-border: "#cecfd2"
  light-line: "#e1e2e5"
  light-tint: "#e9e4d8"
  light-accent: "#765b1f"
  light-high: "#a33815"
  light-scrim: "#20242a47"
  light-mark-rest: "#c1c3c6"
  omarchy-observed-background: "#0b170e"
  omarchy-observed-surface: "#0e1d11"
  omarchy-observed-foreground: "#dcd6bc"
  omarchy-observed-secondary: "#a6a48f"
  omarchy-observed-border: "#31392d"
  omarchy-observed-line: "#1f291f"
  omarchy-observed-tint: "#16281a"
  omarchy-observed-accent: "#64a472"
  omarchy-observed-scrim: "#03060499"
  accent-ink-dark: "#101214"
  accent-ink-light: "#ffffff"
  icon-tile: "#24272c"
  icon-rest: "#55585e"
typography:
  value-display:
    fontFamily: "Geist Mono, monospace"
    fontSize: "34px"
    fontWeight: 400
    lineHeight: 1
    letterSpacing: "-1.02px"
    fontFeature: "\"tnum\" 1"
  value-scale:
    fontFamily: "Geist Mono, monospace"
    fontSize: "28px"
    fontWeight: 400
    lineHeight: 1
    letterSpacing: "-0.56px"
    fontFeature: "\"tnum\" 1"
  title-dialog:
    fontFamily: "Geist, sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.4
  title-app:
    fontFamily: "Geist, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "-0.16px"
  title-row:
    fontFamily: "Geist, sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.4
  body:
    fontFamily: "Geist, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.4
  body-strong:
    fontFamily: "Geist, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
  body-reading:
    fontFamily: "Geist, sans-serif"
    fontSize: "13.5px"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "Geist, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.4
  label-action:
    fontFamily: "Geist, sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.4
  label-small:
    fontFamily: "Geist, sans-serif"
    fontSize: "12.5px"
    fontWeight: 400
    lineHeight: 1.4
  caption:
    fontFamily: "Geist, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.4
  readout:
    fontFamily: "Geist Mono, monospace"
    fontSize: "11.5px"
    fontWeight: 400
    lineHeight: 1.4
    fontFeature: "\"tnum\" 1"
  section-label:
    fontFamily: "Geist, sans-serif"
    fontSize: "11px"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "0.99px"
  scale-tick:
    fontFamily: "Geist Mono, monospace"
    fontSize: "10.5px"
    fontWeight: 400
    lineHeight: 1.4
  showcase-display:
    fontFamily: "Geist, Liberation Sans, Arial, sans-serif"
    fontSize: "clamp(2.25rem, 0.9rem + 2.9vw, 3.4rem)"
    fontWeight: 600
    lineHeight: 1.05
    letterSpacing: "-0.035em"
  showcase-headline:
    fontFamily: "Geist, Liberation Sans, Arial, sans-serif"
    fontSize: "clamp(1.75rem, 1.2rem + 1.5vw, 2.5rem)"
    fontWeight: 600
    lineHeight: 1.12
    letterSpacing: "-0.028em"
  showcase-body:
    fontFamily: "Geist, Liberation Sans, Arial, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.6
rounded:
  tick: "1px"
  meter: "2px"
  key: "4px"
  sm: "6px"
  md: "7px"
  lg: "8px"
  xl: "10px"
  tile: "12px"
  full: "9999px"
spacing:
  hair: "2px"
  label-gap: "6px"
  item-gap: "10px"
  heading-gap: "12px"
  card-inset-tight: "15px"
  card-inset: "20px"
  page: "24px"
  gutter: "28px"
  section: "34px"
components:
  button-primary:
    backgroundColor: "{colors.dark-accent}"
    textColor: "{colors.accent-ink-dark}"
    typography: "{typography.label-action}"
    rounded: "{rounded.lg}"
    height: "40px"
  button-outline:
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-action}"
    rounded: "{rounded.lg}"
    height: "40px"
  button-outline-hover:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-foreground}"
    rounded: "{rounded.lg}"
    height: "40px"
  button-bar:
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-action}"
    rounded: "{rounded.md}"
    height: "32px"
  button-bar-hover:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-foreground}"
    rounded: "{rounded.md}"
    height: "32px"
  button-text:
    textColor: "{colors.dark-secondary}"
    typography: "{typography.label-small}"
  button-text-hover:
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-small}"
  segmented-control:
    rounded: "{rounded.lg}"
    padding: "3px"
    height: "32px"
  segmented-item:
    textColor: "{colors.dark-secondary}"
    typography: "{typography.label-small}"
    rounded: "{rounded.sm}"
    height: "26px"
  segmented-item-selected:
    backgroundColor: "{colors.dark-line}"
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-small}"
    rounded: "{rounded.sm}"
    height: "26px"
  preset-card:
    textColor: "{colors.dark-foreground}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: "{spacing.card-inset-tight}"
    width: "139px"
    height: "128px"
  preset-card-hover:
    backgroundColor: "{colors.dark-surface}"
    rounded: "{rounded.lg}"
    width: "139px"
    height: "128px"
  preset-card-selected:
    backgroundColor: "{colors.dark-tint}"
    textColor: "{colors.dark-foreground}"
    rounded: "{rounded.lg}"
    width: "139px"
    height: "128px"
  control-card:
    backgroundColor: "{colors.dark-surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.card-inset}"
  tick-scale:
    height: "32px"
  track-slider:
    height: "20px"
  switch:
    rounded: "{rounded.full}"
    width: "36px"
    height: "20px"
  switch-on:
    backgroundColor: "{colors.dark-accent}"
    rounded: "{rounded.full}"
    width: "36px"
    height: "20px"
  info-tip:
    textColor: "{colors.dark-secondary}"
    rounded: "{rounded.full}"
    size: "14px"
  key-cap:
    textColor: "{colors.dark-secondary}"
    typography: "{typography.scale-tick}"
    rounded: "{rounded.key}"
    height: "18px"
  pill:
    backgroundColor: "{colors.dark-tint}"
    textColor: "{colors.dark-accent}"
    rounded: "{rounded.full}"
    padding: "0 8px"
    height: "18px"
  tooltip:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-small}"
    rounded: "{rounded.md}"
    padding: "8px 10px"
  dialog:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-foreground}"
    rounded: "{rounded.xl}"
    width: "520px"
  drawer-panel:
    backgroundColor: "{colors.dark-background}"
    textColor: "{colors.dark-foreground}"
    width: "473px"
  take-play:
    rounded: "{rounded.full}"
    size: "32px"
  take-play-active:
    backgroundColor: "{colors.dark-accent}"
    textColor: "{colors.accent-ink-dark}"
    rounded: "{rounded.full}"
    size: "32px"
---

# Design System: Podtune

## Overview

**Creative North Star: "The Tick-Scale Bench"**

Podtune looks like a calm measuring instrument. Every value sits on a scale of thin rounded bars. The accent marks the filled range and the set point. The ground stays dark and neutral, so the measured signal carries the color. The same tick bar appears in the tone scales, the preset cards, the waveform, the Set point mark, and the showcase page divider.

The app is a Qt Quick window with custom controls on top of Qt Quick Controls Material. Custom components bind every fill, text, and border to the live `theme` object. Dark, Light, and Omarchy modes therefore keep one hierarchy. The GitHub Pages showcase in `docs/` reuses the same palettes, the same fonts, the same mark, and a CSS tick-scale divider.

Density is medium. Section headings are small uppercase labels. Large mono numbers carry the measured values. Thin hairlines and one tonal step separate the groups. Motion is short and functional. Wheel scrolling has no inertia.

**Key Characteristics:**
- One accent per theme fills the set ranges, the primary action, the selection, and the focus ring.
- Values sit on tick scales of 2 px rounded bars, not on smooth tracks.
- Geist is the text face. Geist Mono carries measured values, units, scale ticks, and key caps.
- Surfaces are flat. Depth comes from one tonal step, hairlines, and a scrim.
- Each control has an info tip that opens the full-window Guide at its topic.
- Advanced controls live in a drawer that slides in from the right.

## Colors

The palette is a neutral graphite ground with one warm accent. Omarchy mode replaces the ground, the text, and the accent with the current desktop theme. The frontmatter is normative. Component tokens use the Dark values because Dark is the default mode.

### Primary

- **Instrument Gold**, `dark-accent`: The Dark accent. It fills tick bars below the set point, the record button, the active switch, the target band, the selected preset border, and every focus ring.
- **Deep Brass**, `light-accent`: The Light accent. It has the same roles as Instrument Gold. Its darker value keeps the bars visible on the pale ground.
- **Observed Omarchy Green**, `omarchy-observed-accent`: The accent of the inspected Omarchy theme. It is a sample, not a fixed color. The app reads the live accent from `~/.local/state/omarchy/current/theme/colors.toml`.
- **Accent Ink**, `accent-ink-dark` and `accent-ink-light`: The text and glyph color on an accent fill. `theme.accentForeground` selects dark ink when the accent luminance is above `0.179`. Otherwise it selects white.

### Tertiary

- **Hot Signal**, `dark-high` and `light-high`: Marks a peak above `-3 dBFS`, waveform bars above `0.7079` linear, clipped-sample counts, the recording dot, and the footer error dot. It warns about headroom. It does not mean clipped audio by itself.

### Neutral

| Role | Dark | Light | Omarchy rule |
| --- | --- | --- | --- |
| Ground | `dark-background` | `light-background` | Imported `background` |
| Raised surface | `dark-surface` | `light-surface` | `lighter(124)` on dark ground, `lighter(103)` on light ground |
| Text | `dark-foreground` | `light-foreground` | Imported `foreground` |
| Supporting text | `dark-secondary` | `light-secondary` | Mix of 0.74 text and 0.26 ground |
| Border | `dark-border` | `light-border` | Mix of 0.18 text and 0.82 ground |
| Inner divider | `dark-line` | `light-line` | Mix of 0.095 text and 0.905 ground |
| Accent tint | `dark-tint` | `light-tint` | Mix of 0.12 accent and 0.88 ground |
| Scrim | `dark-scrim` | `light-scrim` | Ground at 0.25 and alpha 0.6 on dark, text at alpha 0.28 on light |
| Mark rest bar | `dark-mark-rest` | `light-mark-rest` | Mix of 0.24 text and 0.76 ground |

`src/theme.cpp` computes the Omarchy roles with linear RGB mixes. The `omarchy-observed-*` tokens record one inspected theme. They are not fixed values. **Border** outlines cards, buttons, and the header and footer rules. **Inner divider** separates rows inside a card. Use **Accent tint** only behind a selected preset card and behind a pill.

The app icon uses `icon-tile` as its tile and `icon-rest` for the short bar. The icon does not follow the theme.

### Named Rules

**The Live Theme Rule.** Bind every custom color to a `theme` role. The QML contains no hard-coded hex color. The one derived color is the pressed record button, which uses `Qt.darker(theme.accent, 1.14)`.

**The Filled Range Rule.** The accent means "set" or "measured". Use it for filled ranges, set points, the selection, the primary action, and focus. Do not use it for decoration.

## Typography

**Text Font:** Geist, with `Liberation Sans`, Arial, and `sans-serif` as fallbacks on the showcase page
**Value Font:** Geist Mono, with `ui-monospace` and `monospace` as fallbacks on the showcase page

**Character:** Geist is a neutral grotesque that reads well at 11 px to 17 px. Geist Mono with tabular figures makes the measured values feel like an instrument readout.

The app embeds Geist Regular, Medium, and SemiBold, and Geist Mono Regular and Medium from `third_party/geist`. `src/main.cpp` registers them with `QFontDatabase::addApplicationFont`. The window default is Geist at 14 px.

### The Txt primitive

All app text goes through `src/Txt.qml`. Qt rounds font sizes to whole pixels. When `size` is fractional, `Txt` renders the text at twice the size and scales it by 0.5. Sizes such as 12.5 px and 13.5 px therefore render exactly. `Txt` uses a CSS-style line box. Each line is `size * lh` tall, with a default `lh` of 1.4. The glyphs sit in the vertical center of the line. `tracking` sets letter spacing in pixels. `mono` selects Geist Mono. `tnum` turns on tabular figures.

### Hierarchy

- **Value display**, `value-display`: The live peak number in the voice test card.
- **Value scale**, `value-scale`: The 0 to 100 value at the right end of each tone scale. A value of 0 shows `Off` at 15 px in supporting text.
- **Dialog title**, `title-dialog`: Dialog titles and Guide topic titles.
- **App title**, `title-app`: The wordmark and the titles of the Advanced drawer and the Guide.
- **Row title**, `title-row`: Tone row titles.
- **Body**, `body` and `body-strong`: Preset names at weight 600, control labels at weight 500, and general text.
- **Reading**, `body-reading`: Guide steps and dialog prose. Guide steps use a line height of 1.55.
- **Label**, `label` and `label-action`: Header identity, menu entries, and button labels.
- **Small label**, `label-small`: Subtitles, text buttons, tooltips, and the theme switch.
- **Caption**, `caption`: Hints, the footer notice, and helper text in the drawer.
- **Readout**, `readout`: Units, hardware detail values, and take statistics.
- **Section label**, `section-label`: Uppercase section headings such as Presets, Tone, Headphones, and Takes, in supporting text.
- **Scale tick**, `scale-tick`: Meter and curve tick labels and key caps.

The showcase page uses `showcase-display` for its one `h1`, `showcase-headline` for section `h2` titles, and `showcase-body` for prose.

### Named Rules

**The Measured Mono Rule.** Use Geist Mono only for numbers, units, scale ticks, commands, and keys. Set tabular figures on any value that changes live.

## Layout

The window opens at 1280 by 860 and has a minimum size of 480 by 480. A 64 px header and a 36 px footer frame the page. Each has a 1 px border rule. The content frame is centered and has a maximum width of 1440 px.

From a frame width of 960 px, the page has two columns. The left column holds Presets, Tone, and Headphones, and fills the remaining width. The right column holds the voice test. Its width is `(frame - 105) * 0.375`, limited to the range 360 px to 440 px. A 1 px vertical border rule separates the columns, with a 28 px gutter on each side. The outer margin is 24 px, and the top and bottom inset is 22 px.

Below 960 px, the page has one centered column. Its width is `min(frame - 48, 680)`. The voice test moves below the tune sections, and a horizontal border rule separates the two. The header removes the firmware text below 900 px, the identity below 720 px, the Help label below 600 px, and the wordmark below 540 px. The footer removes its key hints below 760 px.

Each section has a 20 px heading row, then a 12 px gap, then the content. Sections are 34 px apart. Card rows use a 20 px inset. Preset cards use a 15 px inset and sit 10 px apart in a horizontal list. A 32 px edge fade shows that more cards are outside the row. A tone row stacks its title above its scale below 600 px. The headphones card stacks its two cells below 560 px.

The Advanced drawer is `min(473, window width)` wide. The Guide page has a reading column of up to 640 px. From 900 px, a 200 px table of contents sits to its left.

All scroll areas use `WheelScroll.qml`. A mouse wheel step moves 96 px and animates for 110 ms with an out-cubic curve. A touchpad moves the content by the exact pixel delta. There is no inertia or overshoot. At the end of its range, a nested view passes the scroll to the outer view.

The showcase page uses a 1200 px wrap with 24 px side margins, and 16 px side margins below 560 px. Its grids collapse to one column below 900 px.

## Elevation & Depth

The app is flat. It defines no shadows. Depth comes from three tools. A raised surface is one tonal step above the ground. A 1 px border outlines a card. A scrim covers the page behind the drawer and the dialogs. Overlays are separate layers, not lifted cards. The drawer and the Guide use the ground color, and the dialogs use the raised surface.

### Shadow Vocabulary

- **Screenshot lift**, `box-shadow: 0 28px 48px -28px var(--shadow), 0 2px 6px -2px var(--shadow)`: Used only on the showcase demo video. Theme screenshots use `0 24px 44px -26px var(--shadow)`. These shadows separate a captured app window from the page. App surfaces do not use them.

### Named Rules

**The Flat Bench Rule.** App surfaces never cast shadows. To raise a surface, use the raised surface color, a border, or a scrim.

## Shapes

Corners are soft and small. They range from 6 px to 12 px by component size:

- Menu entries, segmented items, and small icon buttons use 6 px.
- Header buttons, tooltips, the save field, and the Quit and Save buttons use 7 px.
- Cards, the theme switch frame, the Check levels button, and the record button use 8 px.
- Dialogs and the showcase code block use 10 px.
- The app icon tile and showcase screenshots use 12 px.

Smaller parts follow their own size. Key caps use 4 px, and the level meter uses 2 px. Pills, dots, switch tracks, the info tip ring, and the play button are fully round. A focus ring sits 3 px to 6 px outside its control and adds that distance to the control radius. For example, a preset card has an 8 px radius and an 11 px ring.

The recurring form is the rounded tick bar. It is 2 px wide with a 1 px radius in the controls. In the Set point mark, it is 6 units wide with a 3 unit radius on a 64 unit grid. Lines are 1 px. Focus rings, the selection indicator in the Guide, and the take progress bar are 2 px.

The **Set point mark** in `src/Logo.qml` has five bars. Three equal accent bars show the filled range. One tall foreground bar shows the set point. One short bar shows the remaining range in a 0.24 mix of foreground and ground. The header draws it at 28 px. `pkgbuild/podtune.svg` places the mark at scale 0.72 on the `icon-tile` color with a 12 px corner radius.

Icons are drawn shapes, not text. The play triangle is a Canvas path. The stop and record marks are rectangles. The showcase uses inline SVG.

## Components

### Buttons

Buttons are quiet. Only one primary action has an accent fill in a group.

- **Primary:** The Record test button and the Quit and Save buttons. They have an accent fill, accent ink, and SemiBold text. Record test is 40 px tall with an 8 px radius. It shows a 9 px round dot that becomes a 10 px square with a 2 px radius while recording. When pressed, it darkens to `Qt.darker(theme.accent, 1.14)`. Its focus ring is a 2 px foreground ring.
- **Outline:** Check levels, Advanced, and Keep working. They are transparent with a border. On hover they get the raised surface fill. The border of Advanced changes to supporting text color on hover.
- **Bar:** Help, Undo, Redo, and close buttons. They are transparent until hover, then get the raised surface fill. Help pairs its label with a key cap.
- **Text:** Save current, Reset to the preset, and Trash. They have no frame. Their text changes from supporting text to text color on hover.
- **Mute:** A 26 px outline button. When the input is muted, it inverts to a text-color fill with ground-color text.

### Segmented theme switch

The header switch has Dark, Light, and Omarchy segments. A 32 px frame with an 8 px radius and a border holds 26 px segments with a 6 px radius. The selected segment gets the inner divider fill and text color. The others use supporting text. The showcase page uses the same control to re-theme the whole page.

### Preset cards

Each card is 139 by 128 px with an 8 px radius and a border. It shows the name, a status word, and three 18-bar mini scales for Warmth, Presence, and Leveling. When selected, the card gets the accent tint fill, an accent border, and accent bars. On hover it gets the raised surface fill. Color changes animate for 150 ms.

### Tone scale

The signature control. Each tone row is a 64-tick slider from 0 to 100. Ticks are 2 px wide with a 1 px radius. Ticks below the set point are 20 px tall in the accent. The set point tick is 30 px tall in the foreground color. The remaining ticks are 10 px tall in the border color. At 0, the set point tick is 20 px in supporting text. Arrow keys move 3 steps and Page keys move 30. The row also shows a large mono value and a link to the hardware detail.

### Track slider and switch

**Track slider:** A thin rounded track in the border color with an accent fill and a round foreground knob. The size is configurable. The headphone slider uses a 3 px track and a 14 px knob.

**Switch:** A 36 by 20 px track with a 14 px knob. When off, it has a border and a supporting-text knob. When on, it has an accent fill and an accent-ink knob. The knob slides in 150 ms.

### Cards

- **Corner Style:** 8 px.
- **Background:** Raised surface.
- **Shadow Strategy:** None. See Elevation & Depth.
- **Border:** 1 px border color. Inner rows divide with the inner divider color.
- **Internal Padding:** 20 px for control rows and 19 px for the voice test card.

### Info tip and Guide

Each section heading and each control title can have an info tip. The tip is a 14 px ring in the border color with a 22 px hit area. On hover or focus, the ring changes to supporting text and a tooltip opens after 250 ms. The tooltip shows the topic summary and the line "Select to read more". Selecting the tip opens the Guide page at its topic.

The Guide is a full-window page on the ground color. It fades in and rises 12 px in 180 ms. It scrolls to the topic and shows a 3 px accent bar beside the title for 1600 ms. From 900 px, a table of contents marks the current topic with a 2 px accent bar. `Esc` closes the Guide.

### Advanced drawer

The drawer slides in from the right in 300 ms with the curve `[0.2, 0.75, 0.2, 1]`. The scrim fades in 250 ms. The panel uses the ground color with a 1 px border on its left edge. It has a 64 px header with the title, Undo, Redo, and close. Its body holds every verified hardware control in divided sections, the compressor transfer curve, the level meter, and Save preset. A click on the scrim or `Esc` closes it.

### Waveform

The waveform shows the last 100 measured intervals as symmetric bars. The newest bars are fully opaque, and the oldest bars are at 40 percent. A shaded accent band and dashed guides at 35 percent opacity mark the target range of `-18` to `-6 dBFS`. Bars above the high threshold use Hot Signal.

### Takes

Each take row has a 32 px round play button, a name, an optional preset pill with a border, and a mono statistics line. While a take plays, the button fills with the accent and a 2 px accent bar shows the progress.

### Key caps and pills

**Key cap:** A transparent 18 px cap with a 4 px radius, a border, and Geist Mono text. It shows shortcuts in the header, the footer, and the help dialog.

**Pill:** An 18 px fully round label with the accent tint fill and accent text.

### Dialogs

Dialogs are centered and modal over the scrim. They have no enter or exit animation. The help dialog is up to 520 px wide, and the exit dialog is up to 420 px wide. Both use the raised surface fill, a border, and a 10 px radius.

## Do's and Don'ts

### Do:

- **Do** bind every custom color to a `theme` role, so Dark, Light, and Omarchy keep one hierarchy.
- **Do** show a value on a tick scale of 2 px rounded bars, with the accent for the filled range and the foreground color for the set point.
- **Do** render all app text through `Txt.qml`, so fractional sizes and centered line boxes stay exact.
- **Do** use Geist Mono with tabular figures for live numbers, units, and scale ticks.
- **Do** give each new control an info tip and a Guide topic in `Guide.js`.
- **Do** put secondary hardware controls in the Advanced drawer, not in the main page.
- **Do** keep radii between 6 px and 12 px by component size, and draw a 2 px accent focus ring outside the control.
- **Do** use `WheelScroll.qml` for every scroll area, so scrolling stays exact and without inertia.
- **Do** draw icons as shapes or inline SVG.

### Don't:

- **Don't** add shadows to app surfaces. Use the raised surface, a border, or the scrim.
- **Don't** use the accent for decoration. It marks set ranges, measured signal, the selection, the primary action, and focus.
- **Don't** put more than one accent-filled action in one group.
- **Don't** hard-code hex colors in QML. The pressed record button is the only derived color.
- **Don't** freeze the observed Omarchy colors into code. Omarchy mode reads the live theme file.
- **Don't** add a third font family or use a system display face.
