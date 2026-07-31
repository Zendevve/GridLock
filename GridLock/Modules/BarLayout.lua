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
    local strName = nil
    if type(barFrame) == "string" then
        strName = barFrame
        barFrame = _G[barFrame]
    end
    if not barFrame and not strName then return {} end

    if barFrame and type(barFrame) == "table" and barFrame.buttons and type(barFrame.buttons) == "table" then
        return barFrame.buttons
    end
    
    local buttons = {}
    local name = (barFrame and type(barFrame) == "table" and barFrame.GetName and barFrame:GetName()) or strName
    if name then
        for i = 1, 12 do
            local btn = _G[name .. "Button" .. i] or _G[name .. "ActionButton" .. i] or _G[name .. "Btn" .. i]
            if btn then
                table.insert(buttons, btn)
            end
        end
    end
    
    if #buttons == 0 and barFrame and type(barFrame) == "table" and barFrame.GetChildren then
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

-- 7. Set Bar Icon Zoom (Crop button border textures for clean borderless aesthetic)
function GridLock:SetBarIconZoom(barFrame, zoomEnabled)
    if not barFrame then return end
    local frame = (type(barFrame) == "string" and _G[barFrame]) or barFrame
    local zoom = not not zoomEnabled
    if type(barFrame) == "table" then
        barFrame.iconZoomed = zoom
    elseif frame then
        frame.iconZoomed = zoom
    end

    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        local btnName = (btn.GetName and btn:GetName())
        local icon = (btnName and _G[btnName .. "Icon"]) or btn.icon or btn.Icon
        if icon and icon.SetTexCoord then
            if zoom then
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            else
                icon:SetTexCoord(0, 1, 0, 1)
            end
        end
    end
end

-- 8. Set Bar Click-Through (Disable mouse interaction per bar)
function GridLock:SetBarClickThrough(barFrame, clickThroughEnabled)
    if not barFrame then return end
    local frame = (type(barFrame) == "string" and _G[barFrame]) or barFrame
    local clickThrough = not not clickThroughEnabled
    if type(barFrame) == "table" then
        barFrame.clickThrough = clickThrough
    elseif frame then
        frame.clickThrough = clickThrough
    end

    if frame and frame.EnableMouse then
        frame:EnableMouse(not clickThrough)
    end

    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        if btn.EnableMouse then
            btn:EnableMouse(not clickThrough)
        end
    end
end

-- 9. Set Bar Normal Texture Visibility
function GridLock:SetBarNormalTextureVisibility(barFrame, visible)
    if not barFrame then return end
    local frame = (type(barFrame) == "string" and _G[barFrame]) or barFrame
    local showNorm = not not visible
    if type(barFrame) == "table" then
        barFrame.showNormalTexture = showNorm
    elseif frame then
        frame.showNormalTexture = showNorm
    end

    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        local btnName = (btn.GetName and btn:GetName())
        local norm = (btn.GetNormalTexture and btn:GetNormalTexture()) or (btnName and _G[btnName .. "NormalTexture"]) or btn.NormalTexture or btn.normalTexture
        if norm then
            if showNorm then
                if norm.Show then norm:Show() end
            else
                if norm.Hide then norm:Hide() end
            end
        end
    end
end

-- 10. Set Bar Custom Border Color
function GridLock:SetBarBorderColor(barFrame, r, g, b, a)
    if not barFrame then return end
    local frame = (type(barFrame) == "string" and _G[barFrame]) or barFrame
    r, g, b, a = r or 1, g or 1, b or 1, a or 1
    if type(barFrame) == "table" then
        barFrame.borderColor = { r = r, g = g, b = b, a = a }
    elseif frame then
        frame.borderColor = { r = r, g = g, b = b, a = a }
    end

    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        local btnName = btn.GetName and btn:GetName()
        local border = (btnName and _G[btnName .. "Border"]) or btn.Border or btn.border
        if border and border.SetVertexColor then
            border:SetVertexColor(r, g, b, a)
        elseif btn.SetBackdropBorderColor then
            btn:SetBackdropBorderColor(r, g, b, a)
        end
    end
end

-- 11. Register Bar with Masque / ButtonFacade (if present)
function GridLock:RegisterMasqueGroup(barFrame, groupName)
    if not barFrame then return end
    local LibMasque = _G.LibStub and _G.LibStub("Masque", true) or _G.LibStub and _G.LibStub("ButtonFacade", true)
    if not LibMasque then return end

    local group = LibMasque:Group("GridLock", groupName or (barFrame.GetName and barFrame:GetName()) or "ActionBar")
    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        group:AddButton(btn)
    end
end

-- 12. Font String Customizer Engine
function GridLock:SetFontStringStyle(fontString, config)
    if not fontString or type(config) ~= "table" then return false end

    local currentFont, currentSize, currentFlags
    if fontString.GetFont then
        currentFont, currentSize, currentFlags = fontString:GetFont()
    end

    local font = config.font or config.fontFamily or currentFont or "Fonts\\FRIZQT__.TTF"
    local size = config.size or config.fontSize or currentSize or 12
    local flags = config.flags or config.outline or currentFlags or ""

    if fontString.SetFont then
        fontString:SetFont(font, size, flags)
    end

    if config.color or config.textColor then
        local color = config.color or config.textColor
        local r = color.r or color[1] or 1
        local g = color.g or color[2] or 1
        local b = color.b or color[3] or 1
        local a = color.a or color[4] or 1
        if fontString.SetTextColor then
            fontString:SetTextColor(r, g, b, a)
        end
    end

    if config.shadow or config.shadowOffset then
        local shadow = config.shadow or config.shadowOffset
        local sx = shadow.x or shadow[1] or 1
        local sy = shadow.y or shadow[2] or -1
        if fontString.SetShadowOffset then
            fontString:SetShadowOffset(sx, sy)
        end
        if config.shadowColor and fontString.SetShadowColor then
            local sc = config.shadowColor
            fontString:SetShadowColor(sc.r or sc[1] or 0, sc.g or sc[2] or 0, sc.b or sc[3] or 0, sc.a or sc[4] or 1)
        end
    end

    return true
end

function GridLock:SetBarFontStringStyle(barFrame, targetType, config)
    if not barFrame then return false end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        GridLock:QueueCombatAction(function()
            GridLock:SetBarFontStringStyle(barFrame, targetType, config)
        end)
        return true
    end

    targetType = (targetType or "all"):lower()
    local buttons = BarLayout:GetBarButtons(barFrame)
    for _, btn in ipairs(buttons) do
        local btnName = btn.GetName and btn:GetName()
        
        -- Hotkey Text
        if targetType == "hotkey" or targetType == "all" then
            local hotkey = (btnName and _G[btnName .. "HotKey"]) or btn.HotKey or btn.hotKey
            if hotkey then
                GridLock:SetFontStringStyle(hotkey, config)
            end
        end

        -- Count Text
        if targetType == "count" or targetType == "all" then
            local count = (btnName and _G[btnName .. "Count"]) or btn.Count or btn.count
            if count then
                GridLock:SetFontStringStyle(count, config)
            end
        end

        -- Macro Text / Name
        if targetType == "macro" or targetType == "name" or targetType == "all" then
            local macro = (btnName and _G[btnName .. "Name"]) or btn.Name or btn.macroName
            if macro then
                GridLock:SetFontStringStyle(macro, config)
            end
        end
    end
    return true
end

return BarLayout

