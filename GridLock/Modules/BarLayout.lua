-- GridLock/Modules/BarLayout.lua
-- Module GL-M3: Action Button Styling & Grid Customization + Combat Lockdown Queue

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

GridLock.BarLayout = GridLock.BarLayout or {}
local BarLayout = GridLock.BarLayout

-- Pending Combat Lockdown Queue
GridLock.pendingQueue = GridLock.pendingQueue or {}
BarLayout.pendingQueue = GridLock.pendingQueue

-- Helper: Get list of buttons for a bar frame
function BarLayout:GetBarButtons(barFrame)
    if not barFrame then return {} end
    if barFrame.buttons and type(barFrame.buttons) == "table" then
        return barFrame.buttons
    end
    
    local buttons = {}
    local name = barFrame.GetName and barFrame:GetName()
    if name then
        for i = 1, 12 do
            local btn = _G[name .. "Button" .. i] or _G[name .. "ActionButton" .. i] or _G[name .. "Btn" .. i]
            if btn then
                table.insert(buttons, btn)
            end
        end
    end
    
    if #buttons == 0 and barFrame.GetChildren then
        local children = { barFrame:GetChildren() }
        for _, child in ipairs(children) do
            if type(child) == "table" then
                table.insert(buttons, child)
            end
        end
    end
    
    return buttons
end

-- 1. Format Hotkey Text (Key text shortening)
function GridLock:FormatHotkeyText(text)
    if text == nil or text == "" then return "" end
    local s = tostring(text)
    
    -- Modifier replacements (order matters: longer / more specific first if needed)
    s = s:gsub("SHIFT%-", "s")
    s = s:gsub("Shift%-", "s")
    s = s:gsub("CTRL%-", "c")
    s = s:gsub("Ctrl%-", "c")
    s = s:gsub("STRG%-", "c")
    s = s:gsub("ALT%-", "a")
    s = s:gsub("Alt%-", "a")
    
    -- Key name replacements
    s = s:gsub("NUMPAD", "N")
    s = s:gsub("Num Pad ", "N")
    s = s:gsub("BUTTON", "M")
    s = s:gsub("Button ", "M")
    s = s:gsub("Mouse Button ", "M")
    s = s:gsub("MOUSEWHEELUP", "WU")
    s = s:gsub("Mouse Wheel Up", "WU")
    s = s:gsub("WheelUp", "WU")
    s = s:gsub("MOUSEWHEELDOWN", "WD")
    s = s:gsub("Mouse Wheel Down", "WD")
    s = s:gsub("WheelDown", "WD")
    s = s:gsub("PAGEUP", "PU")
    s = s:gsub("Page Up", "PU")
    s = s:gsub("PgUp", "PU")
    s = s:gsub("PAGEDOWN", "PD")
    s = s:gsub("Page Down", "PD")
    s = s:gsub("PgDn", "PD")
    s = s:gsub("INSERT", "Ins")
    s = s:gsub("Insert", "Ins")
    s = s:gsub("DELETE", "Del")
    s = s:gsub("Delete", "Del")
    s = s:gsub("HOME", "Hm")
    s = s:gsub("Home", "Hm")
    s = s:gsub("SPACE", "Spc")
    s = s:gsub("Space", "Spc")
    s = s:gsub("ESCAPE", "Esc")
    s = s:gsub("Escape", "Esc")
    
    return s
end

-- 2. Combat Lockdown Queue API
function GridLock:QueueCombatAction(actionFunc)
    if type(actionFunc) ~= "function" then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        table.insert(GridLock.pendingQueue, actionFunc)
    else
        actionFunc()
    end
end

function GridLock:FlushCombatQueue()
    local queue = GridLock.pendingQueue
    GridLock.pendingQueue = {}
    BarLayout.pendingQueue = GridLock.pendingQueue
    for _, actionFunc in ipairs(queue) do
        actionFunc()
    end
end

-- Register event listener for PLAYER_REGEN_ENABLED
local eventFrame = (_G.CreateFrame and _G.CreateFrame("Frame")) or {}
if eventFrame.RegisterEvent then
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            GridLock:FlushCombatQueue()
        end
    end)
end
BarLayout.eventFrame = eventFrame

-- 3. Set Bar Layout (Rows, Columns, Spacing Sx/Sy, Padding P)
function GridLock:SetBarLayout(barFrame, rows, cols, spacing, padding)
    if not barFrame then return end
    
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        GridLock:QueueCombatAction(function()
            GridLock:SetBarLayout(barFrame, rows, cols, spacing, padding)
        end)
        return
    end
    
    local buttons = BarLayout:GetBarButtons(barFrame)
    local numButtons = #buttons
    if numButtons == 0 then return end
    
    cols = (cols and cols > 0 and cols) or 1
    rows = (rows and rows > 0 and rows) or math.ceil(numButtons / cols)
    
    local Sx, Sy
    if type(spacing) == "table" then
        Sx = spacing.x or spacing[1] or 2
        Sy = spacing.y or spacing[2] or 2
    else
        Sx = tonumber(spacing) or 2
        Sy = tonumber(spacing) or 2
    end
    
    local P = tonumber(padding) or 2
    
    -- Position each button based on col and row
    for i, btn in ipairs(buttons) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        
        local Wb = (btn.GetWidth and btn:GetWidth() > 0 and btn:GetWidth()) or barFrame.buttonWidth or 36
        local Hb = (btn.GetHeight and btn:GetHeight() > 0 and btn:GetHeight()) or barFrame.buttonHeight or 36
        
        local x = P + col * (Wb + Sx)
        local y = -P - row * (Hb + Sy)
        
        if btn.ClearAllPoints then btn:ClearAllPoints() end
        if btn.SetPoint then btn:SetPoint("TOPLEFT", barFrame, "TOPLEFT", x, y) end
    end
    
    -- Calculate container width W and height H
    local sampleWb = (buttons[1] and buttons[1].GetWidth and buttons[1]:GetWidth() > 0 and buttons[1]:GetWidth()) or barFrame.buttonWidth or 36
    local sampleHb = (buttons[1] and buttons[1].GetHeight and buttons[1]:GetHeight() > 0 and buttons[1]:GetHeight()) or barFrame.buttonHeight or 36
    
    local actualRows = math.max(rows, math.ceil(numButtons / cols))
    local actualCols = math.max(cols, math.ceil(numButtons / actualRows))

    local W = actualCols * sampleWb + (actualCols - 1) * Sx + 2 * P
    local H = actualRows * sampleHb + (actualRows - 1) * Sy + 2 * P
    
    if barFrame.SetWidth then barFrame:SetWidth(W) end
    if barFrame.SetHeight then barFrame:SetHeight(H) end
    
    barFrame.rows = rows
    barFrame.cols = cols
    barFrame.spacing = spacing
    barFrame.padding = padding
end

-- 4. Set Bar Grid Visibility (showgrid attribute)
function GridLock:SetBarGridVisibility(barFrame, showGrid)
    if not barFrame then return end
    
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        GridLock:QueueCombatAction(function()
            GridLock:SetBarGridVisibility(barFrame, showGrid)
        end)
        return
    end
    
    local gridVal = 0
    if type(showGrid) == "number" then
        gridVal = showGrid
    elseif showGrid then
        gridVal = 1
    end
    
    if barFrame.SetAttribute then
        barFrame:SetAttribute("showgrid", gridVal)
    end
    
    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        if btn.SetAttribute then
            btn:SetAttribute("showgrid", gridVal)
        end
        if gridVal > 0 then
            if _G.ActionButton_ShowGrid then
                _G.ActionButton_ShowGrid(btn)
            end
            btn.showgrid = gridVal
        else
            if _G.ActionButton_HideGrid then
                _G.ActionButton_HideGrid(btn)
            end
            btn.showgrid = 0
        end
    end
    
    barFrame.showGrid = (gridVal > 0)
end

-- 5. Toggle Bar Hotkeys
function GridLock:ToggleBarHotkeys(barFrame, showHotkeys)
    if not barFrame then return end
    
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        GridLock:QueueCombatAction(function()
            GridLock:ToggleBarHotkeys(barFrame, showHotkeys)
        end)
        return
    end
    
    local show = not not showHotkeys
    barFrame.showHotkeys = show
    
    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        local btnName = btn.GetName and btn:GetName()
        local hotkey = (btnName and _G[btnName .. "HotKey"]) or btn.HotKey or btn.hotKey
        if hotkey then
            if show then
                if hotkey.Show then hotkey:Show() end
                local text = hotkey.GetText and hotkey:GetText()
                if text and text ~= "" then
                    local formatted = GridLock:FormatHotkeyText(text)
                    if hotkey.SetText then hotkey:SetText(formatted) end
                end
            else
                if hotkey.Hide then hotkey:Hide() end
            end
        end
    end
end

-- 6. Toggle Bar Macro Text
function GridLock:ToggleBarMacroText(barFrame, showMacroText)
    if not barFrame then return end
    
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        GridLock:QueueCombatAction(function()
            GridLock:ToggleBarMacroText(barFrame, showMacroText)
        end)
        return
    end
    
    local show = not not showMacroText
    barFrame.showMacroText = show
    
    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        local btnName = btn.GetName and btn:GetName()
        local macroText = (btnName and _G[btnName .. "Name"]) or btn.Name or btn.macroName
        if macroText then
            if show then
                if macroText.Show then macroText:Show() end
            else
                if macroText.Hide then macroText:Hide() end
            end
        end
    end
end

return BarLayout
