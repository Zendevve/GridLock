-- GridLock/Modules/SpecialBars.lua
-- Module GL-M2: Specialized Bar Suite for GridLock

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

GridLock.SpecialBars = GridLock.SpecialBars or {}
local SpecialBars = GridLock.SpecialBars
GridLock.specialBars = GridLock.specialBars or {}

local BAR_ALIASES = {
    pet = "PetBar",
    petbar = "PetBar",
    PetBar = "PetBar",

    stance = "StanceBar",
    stancebar = "StanceBar",
    shapeshift = "StanceBar",
    shapeshiftbar = "StanceBar",
    StanceBar = "StanceBar",

    bag = "BagBar",
    bags = "BagBar",
    bagbar = "BagBar",
    BagBar = "BagBar",

    micro = "MicroMenu",
    micromenu = "MicroMenu",
    MicroMenu = "MicroMenu",
    MicroMenuBar = "MicroMenu",

    vehicle = "VehicleExitBar",
    vehicleexit = "VehicleExitBar",
    vehiclebar = "VehicleExitBar",
    vehicleexitbar = "VehicleExitBar",
    VehicleExitBar = "VehicleExitBar",

    totem = "TotemBar",
    totembar = "TotemBar",
    shaman = "TotemBar",
    shamantotem = "TotemBar",
    MultiCastBar = "TotemBar",
    TotemBar = "TotemBar",
}

--- Resolves any alias to its canonical Bar ID string
-- @param barID (string)
-- @return string canonicalID
function GridLock:GetCanonicalBarID(barID)
    if not barID then return nil end
    local key = tostring(barID):lower()
    for alias, canonical in pairs(BAR_ALIASES) do
        if alias:lower() == key then
            return canonical
        end
    end
    return tostring(barID)
end

--- Get registered special bar object by ID
-- @param barID (string)
-- @return table barObj
function GridLock:GetSpecialBar(barID)
    local canonicalID = self:GetCanonicalBarID(barID)
    return canonicalID and self.specialBars[canonicalID]
end

--- Ensure and initialize mover handle frame GridLockMover_<barID>
-- @param canonicalID (string)
-- @param frame (Frame)
-- @return Frame mover
function GridLock:EnsureMoverHandle(canonicalID, frame)
    local moverName = "GridLockMover_" .. canonicalID
    local mover = _G[moverName]

    if not mover and _G.CreateFrame then
        mover = _G.CreateFrame("Frame", moverName, _G.UIParent or frame)
    elseif not mover then
        mover = {
            name = moverName,
            attributes = {},
            SetPoint = function() end,
            ClearAllPoints = function() end,
            SetSize = function() end,
            SetWidth = function() end,
            SetHeight = function() end,
            Show = function() end,
            Hide = function() end,
            SetScript = function(self, evt, fn) self[evt] = fn end,
            StartMoving = function(self) self.isMoving = true end,
            StopMovingOrSizing = function(self) self.isMoving = false end,
        }
        _G[moverName] = mover
    end

    mover.barID = canonicalID
    mover.targetFrame = frame

    if mover.SetScript then
        mover:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not (_G.InCombatLockdown and _G.InCombatLockdown()) then
                self.isDragging = true
                if self.StartMoving then self:StartMoving() end
            end
        end)

        mover:SetScript("OnMouseUp", function(self, button)
            if self.isDragging then
                self.isDragging = false
                if self.StopMovingOrSizing then self:StopMovingOrSizing() end

                -- Trigger GridLock magnetic docking & grid snapping
                if GridLock.SnapFrame then
                    GridLock:SnapFrame(self)
                end

                if self.targetFrame and self.GetPoint then
                    local point, relativeTo, relativePoint, x, y = self:GetPoint()
                    if point and self.targetFrame.ClearAllPoints and self.targetFrame.SetPoint then
                        self.targetFrame:ClearAllPoints()
                        self.targetFrame:SetPoint(point, relativeTo or _G.UIParent, relativePoint, x, y)
                    end
                end
            end
        end)
    end

    local barObj = self:GetSpecialBar(canonicalID)
    if barObj then
        barObj.mover = mover
    end

    self:UpdateMoverHandle(barObj)
    return mover
end

--- Synchronize Mover position and dimensions with parent bar frame
-- @param barObj (table)
function GridLock:UpdateMoverHandle(barObj)
    if not barObj or not barObj.mover or not barObj.frame then return end
    local mover = barObj.mover
    local frame = barObj.frame

    if mover.ClearAllPoints and mover.SetPoint then
        mover:ClearAllPoints()
        mover:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    end
    if mover.SetWidth and frame.GetWidth then
        mover:SetWidth(frame:GetWidth() or 100)
    end
    if mover.SetHeight and frame.GetHeight then
        mover:SetHeight(frame:GetHeight() or 30)
    end
end

--- Register a specialized bar with container frame and button list
-- @param barID (string)
-- @param frame (Frame or string name)
-- @param buttonList (table of Frame objects or string names)
-- @return table barObj
function GridLock:RegisterSpecialBar(barID, frame, buttonList)
    if not barID then return nil end
    local canonicalID = self:GetCanonicalBarID(barID)

    if type(frame) == "string" then
        frame = _G[frame]
    end

    local resolvedButtons = {}
    if buttonList then
        for _, btn in ipairs(buttonList) do
            if type(btn) == "string" then
                local obj = _G[btn]
                if obj then
                    table.insert(resolvedButtons, obj)
                end
            elseif type(btn) == "table" then
                table.insert(resolvedButtons, btn)
            end
        end
    end

    local barObj = self.specialBars[canonicalID] or {}
    barObj.id = canonicalID
    barObj.frame = frame
    barObj.buttons = resolvedButtons
    barObj.config = barObj.config or {
        rows = 1,
        cols = #resolvedButtons > 0 and #resolvedButtons or 10,
        spacing = 2,
        padding = 2,
        scale = 1.0,
        alpha = 1.0,
        visible = true,
        buttonWidth = (canonicalID == "MicroMenu" and 28 or 36),
        buttonHeight = (canonicalID == "MicroMenu" and 58 or 36),
        verticalOffset = (canonicalID == "MicroMenu" and -21 or 0),
    }

    if frame and resolvedButtons then
        for _, btn in ipairs(resolvedButtons) do
            if btn.SetParent then
                btn:SetParent(frame)
            end
        end
    end

    self.specialBars[canonicalID] = barObj

    self:EnsureMoverHandle(canonicalID, frame)

    if canonicalID == "MicroMenu" then
        self:SetupMicroMenuHooks(barObj)
    elseif canonicalID == "VehicleExitBar" then
        self:SetupVehicleExitBarEvents(barObj)
    elseif canonicalID == "TotemBar" then
        self:SetupTotemBar(barObj)
    end

    if frame then
        self:UpdateSpecialBarLayout(canonicalID, barObj.config)
    end

    return barObj
end

--- Update specialized bar grid layout math and button positioning
-- @param barID (string)
-- @param config (table, optional)
function GridLock:UpdateSpecialBarLayout(barID, config)
    local barObj = self:GetSpecialBar(barID)
    if not barObj then return end

    if config then
        for k, v in pairs(config) do
            barObj.config[k] = v
        end
    end

    local cfg = barObj.config
    local frame = barObj.frame
    local buttons = barObj.buttons or {}
    local numButtons = #buttons

    local rows = tonumber(cfg.rows) or 1
    local cols = tonumber(cfg.cols or cfg.columns)
    if not cols or cols <= 0 then
        if numButtons > 0 then
            cols = math.ceil(numButtons / rows)
        else
            cols = 10
        end
    end
    if rows <= 0 then rows = 1 end

    local spacing = tonumber(cfg.spacing or cfg.buttonSpacing) or 2
    local padding = tonumber(cfg.padding) or 2
    local vOffset = tonumber(cfg.verticalOffset) or (barObj.id == "MicroMenu" and -21 or 0)

    local defaultWidth = (barObj.id == "MicroMenu" and 28 or 36)
    local defaultHeight = (barObj.id == "MicroMenu" and 58 or 36)

    local buttonWidth = tonumber(cfg.buttonWidth) or defaultWidth
    local buttonHeight = tonumber(cfg.buttonHeight) or defaultHeight

    if frame and numButtons > 0 then
        for i, btn in ipairs(buttons) do
            if btn then
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)

                local x = padding + col * (buttonWidth + spacing)
                local y = -(padding + row * (buttonHeight + spacing)) + vOffset

                if btn.ClearAllPoints then btn:ClearAllPoints() end
                if btn.SetPoint then
                    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                end
                if btn.SetWidth then btn:SetWidth(buttonWidth) end
                if btn.SetHeight then btn:SetHeight(buttonHeight) end
                if btn.Show and cfg.visible ~= false then
                    btn:Show()
                end
            end
        end
    end

    if frame and frame.SetWidth and frame.SetHeight then
        local calcCols = math.min(cols, numButtons > 0 and numButtons or cols)
        local calcRows = numButtons > 0 and math.ceil(numButtons / cols) or rows

        local totalWidth = padding * 2 + calcCols * buttonWidth + (math.max(0, calcCols - 1)) * spacing
        local totalHeight = padding * 2 + calcRows * buttonHeight + (math.max(0, calcRows - 1)) * spacing

        frame:SetWidth(totalWidth)
        frame:SetHeight(totalHeight)
    end

    if barObj.mover then
        self:UpdateMoverHandle(barObj)
    end
end

--- Set scale adjustment ratio for special bar
-- @param barID (string)
-- @param scale (number) 1.0 = 100%, 0.8 = 80%, etc.
function GridLock:SetSpecialBarScale(barID, scale)
    local barObj = self:GetSpecialBar(barID)
    if not barObj then return end
    scale = tonumber(scale) or 1.0
    if scale > 5 then
        scale = scale / 100.0
    end
    barObj.config.scale = scale
    if barObj.frame and barObj.frame.SetScale then
        barObj.frame:SetScale(scale)
    end
    if barObj.mover and barObj.mover.SetScale then
        barObj.mover:SetScale(scale)
    end
end

--- Set alpha opacity adjustment ratio for special bar
-- @param barID (string)
-- @param alpha (number) 0.0 to 1.0
function GridLock:SetSpecialBarAlpha(barID, alpha)
    local barObj = self:GetSpecialBar(barID)
    if not barObj then return end
    alpha = tonumber(alpha) or 1.0
    if alpha > 1.0 then
        alpha = alpha / 100.0
    end
    barObj.config.alpha = alpha
    if barObj.frame and barObj.frame.SetAlpha then
        barObj.frame:SetAlpha(alpha)
    end
end

--- Set visibility toggle for special bar
-- @param barID (string)
-- @param visible (boolean)
function GridLock:SetSpecialBarVisibility(barID, visible)
    local barObj = self:GetSpecialBar(barID)
    if not barObj then return end
    visible = (visible == true or visible == 1 or visible == "show" or visible == "true")
    barObj.config.visible = visible
    if barObj.frame then
        if visible then
            if barObj.frame.Show then barObj.frame:Show() end
        else
            if barObj.frame.Hide then barObj.frame:Hide() end
        end
    end
end

--- Hook UpdateMicroButtons to preserve GridLock layout anchors and reparenting
-- @param barObj (table)
function GridLock:SetupMicroMenuHooks(barObj)
    if self._microMenuHooked then return end
    self._microMenuHooked = true

    local onUpdate = function()
        local bar = self:GetSpecialBar("MicroMenu")
        if bar and bar.frame then
            for _, btn in ipairs(bar.buttons or {}) do
                if btn.SetParent then btn:SetParent(bar.frame) end
                if btn.Show and bar.config.visible ~= false then btn:Show() end
            end
            self:UpdateSpecialBarLayout("MicroMenu")
        end
    end

    if _G.hooksecurefunc and _G.UpdateMicroButtons then
        _G.hooksecurefunc("UpdateMicroButtons", onUpdate)
    elseif _G.UpdateMicroButtons then
        local orig = _G.UpdateMicroButtons
        _G.UpdateMicroButtons = function(...)
            orig(...)
            onUpdate(...)
        end
    else
        _G.UpdateMicroButtons = function(...)
            onUpdate(...)
        end
    end
end

--- Register vehicle events for Vehicle Exit Bar
-- @param barObj (table)
function GridLock:SetupVehicleExitBarEvents(barObj)
    if barObj.eventFrame then return end
    local eventFrame
    if _G.CreateFrame then
        eventFrame = _G.CreateFrame("Frame")
    else
        eventFrame = {
            RegisterEvent = function(self, evt) self.events = self.events or {}; self.events[evt] = true end,
            SetScript = function(self, name, fn) self[name] = fn end,
        }
    end
    barObj.eventFrame = eventFrame

    local events = {
        "UNIT_ENTERING_VEHICLE",
        "UNIT_ENTERED_VEHICLE",
        "UNIT_EXITING_VEHICLE",
        "UNIT_EXITED_VEHICLE",
        "VEHICLE_UPDATE",
    }
    for _, evt in ipairs(events) do
        if eventFrame.RegisterEvent then
            eventFrame:RegisterEvent(evt)
        end
    end

    local handler = function(self, event, unit, ...)
        if unit and unit ~= "player" then return end
        local bar = GridLock:GetSpecialBar("VehicleExitBar")
        if not bar or not bar.frame then return end

        local inVehicle = false
        local canExit = _G.CanExitVehicle and _G.CanExitVehicle()
        local unitInVeh = _G.UnitInVehicle and _G.UnitInVehicle("player")
        if canExit or unitInVeh then
            inVehicle = true
        elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_ENTERING_VEHICLE" then
            inVehicle = true
        elseif event == "UNIT_EXITED_VEHICLE" or event == "UNIT_EXITING_VEHICLE" then
            inVehicle = false
        end

        bar.inVehicle = inVehicle
        if inVehicle then
            if bar.config.visible ~= false then
                if bar.frame.Show then bar.frame:Show() end
            end
            for _, btn in ipairs(bar.buttons or {}) do
                if btn.Show then btn:Show() end
            end
        else
            if bar.frame.Hide then bar.frame:Hide() end
        end
    end

    if eventFrame.SetScript then
        eventFrame:SetScript("OnEvent", handler)
    end
    barObj.OnVehicleEvent = handler
end

--- Configure Shaman Totem Bar (MultiCastActionBarFrame)
-- @param barObj (table)
function GridLock:SetupTotemBar(barObj)
    local _, englishClass
    if _G.UnitClass then
        _, englishClass = _G.UnitClass("player")
    end
    if englishClass and englishClass:upper() ~= "SHAMAN" then
        barObj.enabled = false
        if barObj.frame and barObj.frame.Hide then
            barObj.frame:Hide()
        end
        return
    end

    barObj.enabled = true
    local frame = barObj.frame or _G.MultiCastActionBarFrame
    if frame then
        barObj.frame = frame
        frame.ignoreFramePositionManager = true
        if frame.SetScript then
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
            frame:SetScript("OnEvent", nil)
            frame:SetScript("OnUpdate", nil)
        end
        if frame.UnregisterAllEvents then
            frame:UnregisterAllEvents()
        end
    end
end

--- Automatically register and initialize standard WoW 3.3.5a special bars
function GridLock:InitSpecialBars()
    -- 1. Pet Bar
    local petButtons = {}
    for i = 1, 10 do
        table.insert(petButtons, _G["PetActionButton" .. i] or ("PetActionButton" .. i))
    end
    self:RegisterSpecialBar("PetBar", _G["PetActionBarFrame"], petButtons)

    -- 2. Stance Bar
    local stanceButtons = {}
    for i = 1, 10 do
        table.insert(stanceButtons, _G["ShapeshiftButton" .. i] or ("ShapeshiftButton" .. i))
    end
    self:RegisterSpecialBar("StanceBar", _G["ShapeshiftBarFrame"], stanceButtons)

    -- 3. Bag Bar
    local bagButtons = {
        _G["MainMenuBarBackpackButton"] or "MainMenuBarBackpackButton",
        _G["CharacterBag0Slot"] or "CharacterBag0Slot",
        _G["CharacterBag1Slot"] or "CharacterBag1Slot",
        _G["CharacterBag2Slot"] or "CharacterBag2Slot",
        _G["CharacterBag3Slot"] or "CharacterBag3Slot",
        _G["KeyRingButton"] or "KeyRingButton",
    }
    local bagFrame = _G["GridLockBagBar"]
    if not bagFrame and _G.CreateFrame then
        bagFrame = _G.CreateFrame("Frame", "GridLockBagBar", _G.UIParent)
    end
    self:RegisterSpecialBar("BagBar", bagFrame, bagButtons)

    -- 4. Micro Menu Bar
    local microButtons = {
        _G["CharacterMicroButton"] or "CharacterMicroButton",
        _G["SpellbookMicroButton"] or "SpellbookMicroButton",
        _G["TalentMicroButton"] or "TalentMicroButton",
        _G["AchievementMicroButton"] or "AchievementMicroButton",
        _G["QuestLogMicroButton"] or "QuestLogMicroButton",
        _G["SocialsMicroButton"] or "SocialsMicroButton",
        _G["PVPMicroButton"] or "PVPMicroButton",
        _G["LFGMicroButton"] or _G["LFDMicroButton"] or "LFGMicroButton",
        _G["MainMenuMicroButton"] or "MainMenuMicroButton",
        _G["HelpMicroButton"] or "HelpMicroButton",
    }
    local microFrame = _G["GridLockMicroMenu"]
    if not microFrame and _G.CreateFrame then
        microFrame = _G.CreateFrame("Frame", "GridLockMicroMenu", _G.UIParent)
    end
    self:RegisterSpecialBar("MicroMenu", microFrame, microButtons)

    -- 5. Vehicle Exit Bar
    local vehicleButtons = {
        _G["VehicleMenuBarLeaveButton"] or "VehicleMenuBarLeaveButton",
        _G["VehicleMenuBarPitchUpButton"] or _G["PitchUp"] or "PitchUp",
        _G["VehicleMenuBarPitchDownButton"] or _G["PitchDown"] or "PitchDown",
    }
    local vehicleFrame = _G["VehicleMenuBar"] or _G["GridLockVehicleExitBar"]
    if not vehicleFrame and _G.CreateFrame then
        vehicleFrame = _G.CreateFrame("Frame", "GridLockVehicleExitBar", _G.UIParent)
    end
    self:RegisterSpecialBar("VehicleExitBar", vehicleFrame, vehicleButtons)

    -- 6. Totem Bar
    local totemFrame = _G["MultiCastActionBarFrame"]
    if totemFrame then
        self:RegisterSpecialBar("TotemBar", totemFrame, {})
    end
end

return SpecialBars
