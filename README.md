# GridLock

**GridLock** is a premium frame positioning, scaling, grid alignment, hover keybinding, and UI customization addon designed specifically for **World of Warcraft 3.3.5a (Wrath of the Lich King)**.

Built by **Zendevve**, GridLock supersedes lightweight grid overlays and legacy frame movers by offering a unified master dashboard, top control HUD, interactive mouseover picker, magnetic frame-to-frame docking, hover keybinding mode, multi-state combat alpha manager, and action bar grid reformatting.

---

## Key Features

### 1. Top HUD Control Bar
* Pins a sleek, semi-transparent control banner to the top of your screen during Edit Mode.
* Provides quick toggles for **Grid Size** (`32px`), **Snap** (`ON/OFF`), **Mouseover Picker**, **Dashboard**, **Reset All**, and **Save / Exit**.
* Press `ESC` or click **Save / Exit** at any time to exit Edit Mode and lock in your layout.

### 2. Unified Master Dashboard (`/gl list` or `/gl gui`)
* **Left Panel (Frame Registry)**:
  * Categorized list of Blizzard and custom frames (*Unit Frames, Action Bars, Minimap, Bags, Chat, Buffs, Cast Bars, Misc*).
  * Real-time search filter box + **[Reset All]** header button.
  * **Green status badges** clearly indicating modified frames.
  * Inline quick action buttons (`[Edit]`, `[Hide]`, `[Reset]`).
* **Right Panel (Active Frame Inspector)**:
  * Direct **numeric input boxes** alongside smooth sliders for **X Position**, **Y Position**, **Scale %**, and **Alpha %**.
  * 4-Way Directional Nudge Pad (`^`, `v`, `<`, `>`).
  * Action controls (`[Pick Frame]`, `[Reset]`, `[Detach]`, `[Hide]`).

### 3. Interactive Mouseover Frame Picker (`/gl pick`)
* Hover over any frame or UI element in game to highlight it with a visual golden border and frame label.
* Left-click to immediately select and inspect the frame in the Dashboard.
* Right-click or press `ESC` to exit picker mode.

### 4. Interactive Hover Keybinding Mode (`/gl bind`)
* Type `/gl bind` to enter keybinding mode.
* Hover over any action button to display a golden highlight frame and tooltip showing current keybinds.
* Press any key or combination (`Shift+`, `Ctrl+`, `Alt+`, NumPad, Mouse buttons) to assign keybinds live without opening Blizzard menus.

### 5. Multi-State Combat & Mouseover Alpha Manager
* Configure per-frame state-based alpha settings for In-Combat, Out-of-Combat, and Mouseover states.
* Smooth `OnUpdate` opacity transition fading without FPS stutters.

### 6. Action Bar Grid & Row/Column Layout Engine (`/gl bar`)
* Reformat 12-button action bars into custom grid configurations (1x12, 2x6, 3x4, 4x3, 6x2, 12x1) with custom padding.
* Combat lockdown safety: changes requested during combat are queued until combat ends.

### 7. Magnetic Docking & Smart Snapping
* Edge-to-edge and center-to-center frame-to-frame magnetic docking with visual snap guide lines.
* Configurable screen grid overlay (`/gl grid [size]`, default 32px) with center-axis highlights.
* Hold `Ctrl` while dragging to temporarily bypass snapping.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/gl` or `/gridlock` | Open command help menu |
| `/gl edit [frame]` | Enter Edit Mode (or edit a specific frame name) |
| `/gl pick` or `/gl target` | Activate interactive mouseover frame targeter |
| `/gl bind` or `/gl keybind` | Activate interactive hover keybinding mode |
| `/gl bar <name> <rows> <cols>` | Format action bar grid dimensions |
| `/gl grid [size]` | Toggle grid overlay (optional size: 8–256) |
| `/gl snap` | Toggle snap-to-grid ON/OFF |
| `/gl reset [frame]` | Reset specific frame position/scale/alpha |
| `/gl resetall` | Reset ALL frames to default positions and visibilities |
| `/gl list` or `/gl gui` | Toggle Unified Master Dashboard |
| `/gl done` | Exit Edit Mode and save changes |

---

## Installation

1. Copy the `GridLock` folder into your World of Warcraft directory:
   `Interface\AddOns\GridLock\`
2. Restart World of Warcraft or run `/reload` in game.
