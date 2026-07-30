-- GridLock/Modules/BlizzardArt.lua
-- Module GL-M4: Blizzard Action Bar Artwork Controller for GridLock

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

GridLock.BlizzardArt = GridLock.BlizzardArt or {}
local BlizzardArt = GridLock.BlizzardArt

-- Module internal state
BlizzardArt.state = BlizzardArt.state or {
    leftGryphon = true,
    rightGryphon = true,
    mainBarArt = true,
    microMenuArt = true,
}

-- List of MainMenuBar background texture global names
local MAIN_BAR_TEXTURE_NAMES = {
    "MainMenuBarTexture0",
    "MainMenuBarTexture1",
    "MainMenuBarTexture2",
    "MainMenuBarTexture3",
    "MainMenuMaxLevelBar0",
    "MainMenuMaxLevelBar1",
    "MainMenuMaxLevelBar2",
    "MainMenuMaxLevelBar3",
    "MainMenuBarPageNumber",
    "ActionBarUpButton",
    "ActionBarDownButton",
}

-- List of MainMenuBar overlay / container frame global names
local MAIN_BAR_FRAME_NAMES = {
    "MainMenuBarOverlayFrame",
    "MainMenuBarArtFrame",
}

-- List of Micro Menu background frame/texture global names
local MICRO_MENU_ART_NAMES = {
    "MicroButtonAndBagsBar",
    "MicroMenuArtFrame",
}

--- Safely toggle visibility, mouse click-through, and events for a texture or frame object
-- @param obj (Frame or Texture or string name)
-- @param visible (boolean)
local function ToggleElement(obj, visible)
    if type(obj) == "string" then
        obj = _G[obj]
    end
    if not obj then return end

    if visible then
        if obj.Show then obj:Show() end
        if obj.SetAlpha then obj:SetAlpha(1.0) end
        if obj.EnableMouse then obj:EnableMouse(true) end

        -- Restore scripts if previously saved
        if obj._savedOnEvent and obj.SetScript then
            obj:SetScript("OnEvent", obj._savedOnEvent)
            obj._savedOnEvent = nil
        end
        if obj._savedOnUpdate and obj.SetScript then
            obj:SetScript("OnUpdate", obj._savedOnUpdate)
            obj._savedOnUpdate = nil
        end
        obj.eventsDisabled = false
    else
        if obj.Hide then obj:Hide() end
        if obj.SetAlpha then obj:SetAlpha(0.0) end
        if obj.EnableMouse then obj:EnableMouse(false) end

        -- Save and disable event scripts to prevent event interference
        if obj.GetScript and obj.SetScript then
            local onEvt = obj:GetScript("OnEvent")
            if onEvt then
                obj._savedOnEvent = onEvt
                obj:SetScript("OnEvent", nil)
            end
            local onUpd = obj:GetScript("OnUpdate")
            if onUpd then
                obj._savedOnUpdate = onUpd
                obj:SetScript("OnUpdate", nil)
            end
        end
        if obj.UnregisterAllEvents then
            obj:UnregisterAllEvents()
        end
        obj.eventsDisabled = true
    end
end

--- Set visibility of Left and Right Gryphon EndCaps
-- @param leftVisible (boolean or table { left = bool, right = bool })
-- @param rightVisible (boolean, optional)
function GridLock:SetGryphonsVisible(leftVisible, rightVisible)
    local left, right
    if type(leftVisible) == "table" then
        left = leftVisible.left ~= false
        right = leftVisible.right ~= false
    else
        left = leftVisible ~= false
        if rightVisible == nil then
            right = left
        else
            right = rightVisible ~= false
        end
    end

    BlizzardArt.state.leftGryphon = left
    BlizzardArt.state.rightGryphon = right

    ToggleElement("MainMenuBarLeftEndCap", left)
    ToggleElement("MainMenuBarRightEndCap", right)

    return left, right
end

--- Set visibility of MainMenuBar background artwork
-- @param visible (boolean)
function GridLock:SetMainBarArtVisible(visible)
    visible = (visible ~= false and visible ~= 0 and visible ~= "false" and visible ~= "hide")
    BlizzardArt.state.mainBarArt = visible

    -- Toggle MainMenuBar background textures
    for _, name in ipairs(MAIN_BAR_TEXTURE_NAMES) do
        ToggleElement(name, visible)
    end

    -- Toggle MainMenuBar overlay frames
    for _, name in ipairs(MAIN_BAR_FRAME_NAMES) do
        ToggleElement(name, visible)
    end

    return visible
end

--- Set visibility of Micro Menu background artwork
-- @param visible (boolean)
function GridLock:SetMicroMenuArtVisible(visible)
    visible = (visible ~= false and visible ~= 0 and visible ~= "false" and visible ~= "hide")
    BlizzardArt.state.microMenuArt = visible

    for _, name in ipairs(MICRO_MENU_ART_NAMES) do
        ToggleElement(name, visible)
    end

    return visible
end

--- Get current Blizzard artwork visibility state
-- @return table state { leftGryphon = bool, rightGryphon = bool, mainBarArt = bool, microMenuArt = bool }
function GridLock:GetBlizzardArtState()
    return {
        leftGryphon = BlizzardArt.state.leftGryphon,
        rightGryphon = BlizzardArt.state.rightGryphon,
        mainBarArt = BlizzardArt.state.mainBarArt,
        microMenuArt = BlizzardArt.state.microMenuArt,
    }
end

--- Apply a full configuration table to Blizzard action bar artwork
-- @param config (table)
-- @return table state
function GridLock:ApplyBlizzardArtSettings(config)
    config = config or {}

    local leftGryphon = config.leftGryphon
    local rightGryphon = config.rightGryphon

    if leftGryphon == nil and rightGryphon == nil and config.gryphons ~= nil then
        leftGryphon = config.gryphons
        rightGryphon = config.gryphons
    end

    if leftGryphon == nil then leftGryphon = BlizzardArt.state.leftGryphon end
    if rightGryphon == nil then rightGryphon = BlizzardArt.state.rightGryphon end

    local mainBarArt = config.mainBarArt
    if mainBarArt == nil then mainBarArt = BlizzardArt.state.mainBarArt end

    local microMenuArt = config.microMenuArt
    if microMenuArt == nil then microMenuArt = BlizzardArt.state.microMenuArt end

    self:SetGryphonsVisible(leftGryphon, rightGryphon)
    self:SetMainBarArtVisible(mainBarArt)
    self:SetMicroMenuArtVisible(microMenuArt)

    return self:GetBlizzardArtState()
end

--- Initialize BlizzardArt module on load
function GridLock:InitBlizzardArt()
    self:ApplyBlizzardArtSettings(BlizzardArt.state)
end

return BlizzardArt
