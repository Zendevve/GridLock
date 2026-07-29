-- ZenAlign Modules/BarLayout.lua
-- Action Bar Grid & Row/Column Layout Engine for WoW 3.3.5a

local addonName, ZenAlign = ...
local BarLayout = {}
ZenAlign:RegisterModule("BarLayout", BarLayout)

-- Internal State
BarLayout.pendingLayouts = {}
BarLayout.containers = {}
BarLayout.configs = {}

-- Dedicated event frame for combat status monitoring
local eventFrame = CreateFrame("Frame", "ZenAlignBarLayoutFrame", UIParent)

function BarLayout:OnInitialize()
    self.pendingLayouts = self.pendingLayouts or {}
    self.containers = self.containers or {}
    self.configs = self.configs or {}

    -- Register combat regen event handler
    eventFrame:SetScript("OnEvent", function(f, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            BarLayout:ProcessPendingLayouts()
        end
    end)
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

-- Get action buttons associated with a given bar frame name or table
function BarLayout:GetBarButtons(barName)
    if type(barName) == "table" then
        return barName
    end

    local buttons = {}
    local prefixMap = {
        MainMenuBar = "ActionButton",
        MainMenuBarArtFrame = "ActionButton",
        MultiBarBottomLeft = "MultiBarBottomLeftButton",
        MultiBarBottomRight = "MultiBarBottomRightButton",
        MultiBarRight = "MultiBarRightButton",
        MultiBarLeft = "MultiBarLeftButton",
        PetActionBarFrame = "PetActionButton",
        ShapeshiftBarFrame = "ShapeshiftButton",
    }

    local prefix = prefixMap[barName]
    if prefix then
        if prefix == "ShapeshiftButton" then
            for i = 1, 12 do
                local btn = _G["ShapeshiftButton" .. i] or _G["StanceButton" .. i]
                if btn then
                    table.insert(buttons, btn)
                end
            end
        else
            for i = 1, 12 do
                local btn = _G[prefix .. i]
                if btn then
                    table.insert(buttons, btn)
                end
            end
        end
    else
        -- Fallback: lookup using custom bar name as prefix
        for i = 1, 12 do
            local btn = _G[barName .. "Button" .. i] or _G[barName .. i]
            if btn then
                table.insert(buttons, btn)
            end
        end
    end

    return buttons
end

-- Create or retrieve container frame for an action bar
function BarLayout:CreateBarContainer(barName)
    if type(barName) == "string" and self.containers[barName] then
        return self.containers[barName]
    end

    local containerName = type(barName) == "string" and ("ZenAlign_BarContainer_" .. barName) or "ZenAlign_BarContainer_Custom"
    local container = _G[containerName] or CreateFrame("Frame", containerName, UIParent)

    if type(barName) == "string" then
        self.containers[barName] = container
    end

    return container
end

-- Set bar layout configuration with combat lockdown protection
function BarLayout:SetBarLayout(barName, rows, cols, spacing, padding)
    spacing = spacing or 4
    padding = padding or 6

    if InCombatLockdown and InCombatLockdown() then
        self.pendingLayouts[barName] = {
            rows = rows,
            cols = cols,
            spacing = spacing,
            padding = padding,
        }
        return false, "Queued due to combat lockdown"
    end

    local config = {
        rows = rows,
        cols = cols,
        spacing = spacing,
        padding = padding,
    }
    self.pendingLayouts[barName] = nil
    return self:ApplyLayout(barName, config)
end

-- Apply mathematical grid layout calculations to buttons and container
function BarLayout:ApplyLayout(barName, config)
    local rows = config.rows or 1
    local cols = config.cols or 12
    local spacing = config.spacing or 4
    local padding = config.padding or 6

    local sx = type(spacing) == "table" and spacing.x or tonumber(spacing) or 4
    local sy = type(spacing) == "table" and spacing.y or tonumber(spacing) or 4
    local P = tonumber(padding) or 6

    local buttons = self:GetBarButtons(barName)
    local container = self:CreateBarContainer(barName)

    -- Determine button size (default 36x36px for standard WoW action buttons)
    local W_b, H_b = 36, 36
    if buttons[1] then
        local w = buttons[1]:GetWidth()
        local h = buttons[1]:GetHeight()
        if w and w > 0 then W_b = w end
        if h and h > 0 then H_b = h end
    end

    -- Mathematical container size calculations:
    -- W_container = C * W_b + (C - 1) * S_x + 2 * P
    -- H_container = R * H_b + (R - 1) * S_y + 2 * P
    local W_container = cols * W_b + (cols - 1) * sx + 2 * P
    local H_container = rows * H_b + (rows - 1) * sy + 2 * P

    container:SetWidth(W_container)
    container:SetHeight(H_container)

    -- If container is not anchored, anchor to original bar frame or center of UIParent
    if not container:GetPoint() then
        if type(barName) == "string" and _G[barName] and _G[barName]:GetPoint() then
            local p, rel, rp, x, y = _G[barName]:GetPoint()
            container:SetPoint(p, rel, rp, x, y)
        else
            container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end

    -- Position buttons in a grid using row/col coordinate mapping
    for i, button in ipairs(buttons) do
        local idx = i - 1
        local row = math.floor(idx / cols)
        local col = idx % cols

        local X_i = P + col * (W_b + sx)
        local Y_i = -P - row * (H_b + sy)

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", container, "TOPLEFT", X_i, Y_i)
    end

    -- Store active layout configuration
    local key = type(barName) == "string" and barName or "custom"
    self.configs[key] = {
        rows = rows,
        cols = cols,
        spacing = spacing,
        padding = padding,
        container = container,
        width = W_container,
        height = H_container,
        numButtons = #buttons,
    }

    return container, W_container, H_container
end

-- Process all queued layout requests after leaving combat
function BarLayout:ProcessPendingLayouts()
    if InCombatLockdown and InCombatLockdown() then return end

    for barName, config in pairs(self.pendingLayouts) do
        self:ApplyLayout(barName, config)
        self.pendingLayouts[barName] = nil
    end
end
