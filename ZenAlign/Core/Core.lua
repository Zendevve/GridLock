-- ZenAlign Core
-- Main addon initialization and event handling

local addonName, ZenAlign = ...
_G.ZenAlign = ZenAlign

-- Version info
ZenAlign.version = "1.0.0"
ZenAlign.wowVersion = 30300

-- Module registry
ZenAlign.modules = {}

-- State
ZenAlign.editMode = false
ZenAlign.gridShown = false

-- Main frame for events
local frame = CreateFrame("Frame", "ZenAlignCore", UIParent)
ZenAlign.frame = frame

-- Register module
function ZenAlign:RegisterModule(name, module)
    self.modules[name] = module
    if module.OnRegister then
        module:OnRegister()
    end
end

-- Get module
function ZenAlign:GetModule(name)
    return self.modules[name]
end

-- Initialize addon
function ZenAlign:Initialize()
    -- Init config first
    self:InitConfig()

    -- Initialize all modules
    for name, module in pairs(self.modules) do
        if module.OnInitialize then
            module:OnInitialize()
        end
    end

    -- Register slash commands
    self:RegisterSlashCommands()

    -- Apply saved positions
    self:ApplySavedPositions()

    ZenAlign.Utils.Print(ZENALIGN.ADDON_LOADED)
end

-- Apply saved positions to frames
function ZenAlign:ApplySavedPositions()
    local Position = self:GetModule("Position")
    if Position then
        for frameName, posData in pairs(self.db.frames) do
            local f = _G[frameName]
            if f and not ZenAlign.Utils.IsProtectedInCombat(f) then
                Position:ApplyPosition(frameName, posData)
            end
        end
    end

    local Visibility = self:GetModule("Visibility")
    if Visibility then
        Visibility:ApplySavedHiddenStates()
    end
end

-- Register slash commands
function ZenAlign:RegisterSlashCommands()
    SLASH_ZENALIGN1 = "/zenalign"
    SLASH_ZENALIGN2 = "/za"

    SlashCmdList["ZENALIGN"] = function(msg)
        self:HandleSlashCommand(msg)
    end
end

-- Handle slash commands
function ZenAlign:HandleSlashCommand(msg)
    local args = { strsplit(" ", msg) }
    local cmd = string.lower(args[1] or "")

    if cmd == "" or cmd == "help" then
        ZenAlign.Utils.Print(ZENALIGN.CMD_HELP)

    elseif cmd == "grid" then
        local Grid = self:GetModule("Grid")
        if Grid then
            local size = tonumber(args[2])
            if size then
                if size >= 8 and size <= 256 then
                    Grid:SetSize(size)
                    ZenAlign.Utils.Print(ZENALIGN.GRID_SIZE_CHANGED, size)
                    if not Grid.shown then
                        Grid:Show()
                    end
                else
                    ZenAlign.Utils.Print(ZENALIGN.GRID_SIZE_INVALID)
                    return
                end
            else
                Grid:Toggle()
            end
        end


    elseif cmd == "edit" then
        local frameName = args[2]
        if frameName then
            self:EditFrame(frameName)
        else
            self:ToggleEditMode()
        end

    elseif cmd == "done" then
        self:ExitEditMode()

    elseif cmd == "snap" then
        self.db.snapEnabled = not self.db.snapEnabled
        if self.db.snapEnabled then
            ZenAlign.Utils.Print(ZENALIGN.SNAP_ENABLED)
        else
            ZenAlign.Utils.Print(ZENALIGN.SNAP_DISABLED)
        end

    elseif cmd == "reset" then
        local frameName = args[2]
        if frameName == "all" then
            self:ResetAllFrames()
        elseif frameName then
            self:ResetFrame(frameName)
        else
            ZenAlign.Utils.Print("Usage: /za reset <framename> or /za resetall")
        end

    elseif cmd == "resetall" then
        self:ResetAllFrames()

    elseif cmd == "pick" or cmd == "target" or cmd == "hover" then
        local Picker = self:GetModule("Picker")
        if Picker then
            Picker:Toggle()
        end

    elseif cmd == "bind" or cmd == "keybind" then
        local Keybind = self:GetModule("Keybind")
        if Keybind then
            Keybind:Toggle()
        end

    elseif cmd == "bar" or cmd == "layout" then
        local BarLayout = self:GetModule("BarLayout")
        if BarLayout then
            local barName = args[2]
            local rows = tonumber(args[3])
            local cols = tonumber(args[4])
            if barName and rows and cols then
                BarLayout:SetBarLayout(barName, rows, cols)
                ZenAlign.Utils.Print("Set layout of %s to %dx%d", barName, rows, cols)
            else
                ZenAlign.Utils.Print("Usage: /za bar <barName> <rows> <cols>")
            end
        end

    elseif cmd == "scale" then
        local frameName = args[2]
        local val = tonumber(args[3])
        if frameName and val then
            val = math.min(3.0, math.max(0.2, val))
            local f = _G[frameName]
            if f then
                f:SetScale(val)
                self:SaveFrameScale(frameName, val)
                ZenAlign.Utils.Print("Set scale of %s to %.2f", frameName, val)
            else
                ZenAlign.Utils.Print(ZENALIGN.FRAME_NOT_FOUND, frameName)
            end
        else
            ZenAlign.Utils.Print("Usage: /za scale <framename> <scale>")
        end

    elseif cmd == "alpha" then
        local frameName = args[2]
        local val = tonumber(args[3])
        if frameName and val then
            val = math.min(1.0, math.max(0.0, val))
            local f = _G[frameName]
            if f then
                f:SetAlpha(val)
                self:SaveFrameAlpha(frameName, val)
                ZenAlign.Utils.Print("Set alpha of %s to %.2f", frameName, val)
            else
                ZenAlign.Utils.Print(ZENALIGN.FRAME_NOT_FOUND, frameName)
            end
        else
            ZenAlign.Utils.Print("Usage: /za alpha <framename> <alpha>")
        end

    elseif cmd == "list" or cmd == "gui" or cmd == "dashboard" then
        local Dashboard = self:GetModule("Dashboard")
        if Dashboard then
            Dashboard:Toggle()
        end

    else
        ZenAlign.Utils.Print(ZENALIGN.CMD_USAGE)
    end
end


-- Toggle edit mode (all frames)
function ZenAlign:ToggleEditMode()
    if self.editMode then
        self:ExitEditMode()
    else
        self:EnterEditMode()
    end
end

-- Enter edit mode
function ZenAlign:EnterEditMode()
    self.editMode = true

    local Grid = self:GetModule("Grid")
    if Grid and not self.gridShown then
        Grid:Show()
    end

    local HUD = self:GetModule("HUD")
    if HUD then
        HUD:Show()
    end

    local Dashboard = self:GetModule("Dashboard")
    if Dashboard then
        Dashboard:Show()
    end

    ZenAlign.Utils.Print(ZENALIGN.EDIT_MODE_ENTER)
end

-- Exit edit mode
function ZenAlign:ExitEditMode()
    if not self.editMode then return end

    self.editMode = false

    -- Stop picker if active
    local Picker = self:GetModule("Picker")
    if Picker then
        Picker:Stop()
    end

    -- Hide HUD and Dashboard
    local HUD = self:GetModule("HUD")
    if HUD then
        HUD:Hide()
    end

    local Dashboard = self:GetModule("Dashboard")
    if Dashboard then
        Dashboard:Hide()
    end

    -- Detach all movers
    local Mover = self:GetModule("Mover")
    if Mover then
        Mover:DetachAll()
    end

    -- Hide grid
    local Grid = self:GetModule("Grid")
    if Grid then
        Grid:Hide()
    end

    ZenAlign.Utils.Print(ZENALIGN.EDIT_MODE_EXIT)
end

-- Edit specific frame
function ZenAlign:EditFrame(frameName)
    local f = _G[frameName]
    if not f then
        ZenAlign.Utils.Print(ZENALIGN.FRAME_NOT_FOUND, frameName)
        return
    end

    if ZenAlign.Utils.IsProtectedInCombat(f) then
        ZenAlign.Utils.Print(ZENALIGN.FRAME_PROTECTED)
        return
    end

    -- Show grid if not visible
    local Grid = self:GetModule("Grid")
    if Grid and not self.gridShown then
        Grid:Show()
    end

    local HUD = self:GetModule("HUD")
    if HUD then
        HUD:Show()
    end

    -- Select in Dashboard
    local Dashboard = self:GetModule("Dashboard")
    if Dashboard then
        Dashboard:SelectFrame(frameName)
    end

    -- Attach mover
    local Mover = self:GetModule("Mover")
    if Mover then
        Mover:AttachToFrame(f)
        ZenAlign.Utils.Print(ZENALIGN.EDIT_MODE_SINGLE, frameName)
    end
end

-- Reset frame position
function ZenAlign:ResetFrame(frameName)
    local f = _G[frameName]
    if not f then
        ZenAlign.Utils.Print(ZENALIGN.FRAME_NOT_FOUND, frameName)
        return
    end

    local Position = self:GetModule("Position")
    if Position then
        Position:ResetPosition(frameName)
        ZenAlign.Utils.Print(ZENALIGN.POSITION_RESET, frameName)
    end
end

-- Reset ALL frames
function ZenAlign:ResetAllFrames()
    local Position = self:GetModule("Position")
    if Position then
        Position:ResetAll()
    end

    local Dashboard = self:GetModule("Dashboard")
    if Dashboard then
        Dashboard:UpdateInspector()
        Dashboard:UpdateList()
    end
end

-- Event handling
frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ZenAlign:Initialize()
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        -- Reapply positions after login (some frames created late)
        ZenAlign:ApplySavedPositions()

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended, apply pending changes
        ZenAlign:ApplySavedPositions()
        local BarLayout = ZenAlign:GetModule("BarLayout")
        if BarLayout then
            BarLayout:ProcessPendingLayouts()
        end

    elseif event == "PLAYER_LOGOUT" then
        -- Cleanup before logout
        if ZenAlign.editMode then
            ZenAlign:ExitEditMode()
        end
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_LOGOUT")
