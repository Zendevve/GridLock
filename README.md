# ZenAlign

**ZenAlign** is a premium frame positioning, scaling, grid alignment, and UI customization addon designed specifically for **World of Warcraft 3.3.5a (Wrath of the Lich King)**.

Built by **Zendevve**, ZenAlign supersedes lightweight grid overlays and clunky frame movers by offering a unified master dashboard, top control HUD, interactive mouseover picker, and real-time smart snapping.

---

## Key Features

### 1. Top HUD Control Bar
* Pins a sleek, semi-transparent control banner to the top of your screen during Edit Mode.
* Provides quick toggles for **Grid Size** (`32px`), **Snap** (`ON/OFF`), **Pick Frame**, **Reset All**, and **Done & Save**.
* Press `ESC` or click **Done & Save** at any time to exit Edit Mode and lock in your layout.

### 2. Unified Master Dashboard (`/za list` or `/za gui`)
* **Left Panel (Frame Registry)**:
  * Categorized list of Blizzard and custom frames (*Unit Frames, Action Bars, Minimap, Bags, Chat, Buffs, Cast Bars, Misc*).
  * Real-time search filter box.
  * **Green status badges** clearly indicating modified frames.
  * Inline quick action buttons (`[Edit]`, `[Hide]`, `[Reset]`).
* **Right Panel (Active Frame Inspector)**:
  * Direct **numeric input boxes** alongside smooth sliders for **X Position**, **Y Position**, **Scale %**, and **Alpha %**.
  * 4-Way Directional Nudge Pad (`▲`, `▼`, `◄`, `►`).
  * Action controls (`[Pick Frame]`, `[Reset]`, `[Detach]`).

### 3. Interactive Mouseover Frame Picker (`/za pick`)
* Hover over any frame or UI element in game to highlight it with a visual golden border and frame label.
* Left-click to immediately select and inspect the frame in the Dashboard.
* Right-click or press `ESC` to exit picker mode.

### 4. On-Mover Handle Ergonomics
* **Quick Action Buttons**: Pinned directly to the top-right of active green mover handles:
  * `[⚙]` Inspect frame in Dashboard
  * `[↺]` Reset frame to default
  * `[✖]` Detach mover handle
* **Mouse Wheel Ergonomics**: Hover over an active mover handle and scroll your mouse wheel to adjust frame scale ±5% (`Ctrl + Wheel` adjusts opacity/alpha ±5%).
* **Keyboard Nudging**: Press arrow keys (`Up`, `Down`, `Left`, `Right`) while a mover handle is selected to nudge the frame by 1px (`Shift + Arrow` for 10px).

### 5. Grid Overlay & Smart Snapping
* Configurable screen grid overlay (`/za grid [size]`, default 32px, configurable 8px–256px) with center-axis highlights.
* Real-time visual guide lines for **Grid Snapping**, **Screen Center Snapping**, and **Screen Edge Snapping**.
* Hold `Ctrl` while dragging to temporarily bypass snapping.

### 6. Full Persistence
* Automatically saves frame positions, custom scale (`SetScale`), and opacity (`SetAlpha`) in `ZenAlignDB`.
* Safely reapplies all saved frame parameters on login or UI reload (`/reload`).

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/za` or `/zenalign` | Open command help menu |
| `/za edit [frame]` | Enter Edit Mode (or edit a specific frame name) |
| `/za pick` or `/za target` | Activate interactive mouseover frame targeter |
| `/za grid [size]` | Toggle grid overlay (optional size: 8–256) |
| `/za snap` | Toggle snap-to-grid ON/OFF |
| `/za list` or `/za gui` | Toggle Unified Master Dashboard |
| `/za scale <frame> <val>` | Set frame scale directly (e.g. `/za scale TargetFrame 1.15`) |
| `/za alpha <frame> <val>` | Set frame alpha directly (e.g. `/za alpha PlayerFrame 0.85`) |
| `/za reset [frame]` | Reset a specific frame to default position, scale, and alpha |
| `/za done` | Exit Edit Mode and save changes |

---

## Installation

1. Download the latest release from the repository.
2. Extract the `ZenAlign` folder into your World of Warcraft installation directory:
   `World of Warcraft/Interface/AddOns/`
3. Verify that the file path matches:
   `Interface/AddOns/ZenAlign/ZenAlign.toc`
4. Launch World of Warcraft 3.3.5a and enable **ZenAlign** in your AddOn list.

---

## License

Copyright (c) 2026 **Zendevve**. All rights reserved.

Licensed under the **ZenAlign Copyright Notice and Limited Personal Use Terms**. See the [LICENSE](file:///d:/COMPROG/ZenAlign/LICENSE) file for complete details.
