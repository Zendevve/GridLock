-- GridLock/Modules/ActionBarState.lua
-- Module GL-M1: Secure State Paging & Stance Switching for GridLock

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

local unpack = unpack or table.unpack

GridLock.ActionBarState = GridLock.ActionBarState or {}
local ActionBarState = GridLock.ActionBarState

-- Secure Handler Snippets for SecureHandlerStateTemplate
GridLock.SNIPPET_ONSTATE_PAGE = [[
    local newPage = tonumber(newstate) or 1
    self:SetAttribute("state-page", newPage)
    self:ChildUpdate("state", newPage)
]]

GridLock.SNIPPET_CHILDUPDATE_STATE = [[
    local newPage = tonumber(message) or 1
    local id = self:GetID() or 1
    local actionSlot = (newPage - 1) * 12 + id
    
    self:SetAttribute("actionpage", newPage)
    if newPage == 11 or newPage == 12 then
        self:SetAttribute("type", "action")
        self:SetAttribute("action", actionSlot)
        self:SetAttribute("isVehicle", true)
    else
        self:SetAttribute("type", "action")
        self:SetAttribute("action", actionSlot)
        self:SetAttribute("isVehicle", false)
    end
]]

--- Get Macro Conditional Stance Driver String for a given class
-- @param className (string, optional) e.g., "WARRIOR", "DRUID", "ROGUE", "PRIEST", "WARLOCK"
-- @return string Stance driver macro conditional string
function GridLock:GetClassStanceDriver(className)
    if not className then
        if _G.UnitClass then
            _, className = _G.UnitClass("player")
        end
    end
    className = string.upper(className or "")

    if className == "WARRIOR" then
        return "[bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9"
    elseif className == "DRUID" then
        return "[bonusbar:1,stealth:1]7; [bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9; [bonusbar:4]10"
    elseif className == "ROGUE" then
        return "[bonusbar:1]7; [bonusbar:2]8"
    elseif className == "PRIEST" then
        return "[bonusbar:1]7"
    elseif className == "WARLOCK" then
        return "[form:2]7"
    else
        return ""
    end
end

--- Evaluate macro conditional state driver string in Lua (for simulation / unit testing)
-- @param driverString (string)
-- @param env (table) environment state: { bonusbar, stealth, form, mod, bar, vehicleui, possessbar }
-- @return number Evaluated page number
function GridLock:EvaluateStateDriver(driverString, env)
    if not driverString or driverString == "" then
        return 1
    end
    env = env or {}

    -- Split clauses by semicolon
    for clause in string.gmatch(driverString .. ";", "%s*(.-)%s*;") do
        clause = clause:match("^%s*(.-)%s*$")
        if clause and clause ~= "" then
            local conds, pageStr = clause:match("^%[(.+)%](%d+)$")
            if conds and pageStr then
                local allMatch = true
                -- Split conditions inside brackets by comma
                for cond in string.gmatch(conds .. ",", "%s*(.-)%s*,") do
                    cond = cond:match("^%s*(.-)%s*$")
                    if cond and cond ~= "" then
                        local key, val = cond:match("^([%w_]+):?(.*)$")
                        if key == "bonusbar" then
                            if tonumber(env.bonusbar or 0) ~= tonumber(val) then
                                allMatch = false
                                break
                            end
                        elseif key == "stealth" then
                            local reqStealth = tonumber(val) or 1
                            local actualStealth = tonumber(env.stealth or 0)
                            if actualStealth ~= reqStealth then
                                allMatch = false
                                break
                            end
                        elseif key == "form" then
                            if tonumber(env.form or 0) ~= tonumber(val) then
                                allMatch = false
                                break
                            end
                        elseif key == "bar" then
                            if tonumber(env.bar or 1) ~= tonumber(val) then
                                allMatch = false
                                break
                            end
                        elseif key == "mod" then
                            if (env.mod or "") ~= val then
                                allMatch = false
                                break
                            end
                        elseif key == "vehicleui" then
                            if not env.vehicleui then
                                allMatch = false
                                break
                            end
                        elseif key == "possessbar" then
                            if not env.possessbar then
                                allMatch = false
                                break
                            end
                        else
                            allMatch = false
                            break
                        end
                    end
                end
                if allMatch then
                    return tonumber(pageStr) or 1
                end
            else
                -- Fallback unbracketed number e.g. "1"
                local fallbackPage = tonumber(clause)
                if fallbackPage then
                    return fallbackPage
                end
            end
        end
    end
    return 1
end

--- Register State Driver on bar header frame
-- @param barHeader (Frame)
-- @param stateDriverString (string)
function GridLock:RegisterStateDriver(barHeader, stateDriverString)
    if not barHeader then return end

    stateDriverString = stateDriverString or ""
    barHeader._stateDriverString = stateDriverString

    -- Set state snippets
    if barHeader.SetAttribute then
        barHeader:SetAttribute("_onstate-page", GridLock.SNIPPET_ONSTATE_PAGE)
        barHeader:SetAttribute("_childupdate-state", GridLock.SNIPPET_CHILDUPDATE_STATE)

        -- If header has children or buttons table, ensure children have _childupdate-state set
        if barHeader.GetChildren then
            local children = { barHeader:GetChildren() }
            for _, child in ipairs(children) do
                if child and child.SetAttribute then
                    child:SetAttribute("_childupdate-state", GridLock.SNIPPET_CHILDUPDATE_STATE)
                end
            end
        end
        if barHeader.buttons and type(barHeader.buttons) == "table" then
            for _, child in ipairs(barHeader.buttons) do
                if child and child.SetAttribute then
                    child:SetAttribute("_childupdate-state", GridLock.SNIPPET_CHILDUPDATE_STATE)
                end
            end
        end
    end

    -- Call WoW global RegisterStateDriver if available
    if _G.RegisterStateDriver then
        _G.RegisterStateDriver(barHeader, "page", stateDriverString)
    else
        barHeader._stateRegistered = true
    end

    return stateDriverString
end

--- Update bar paging driver for a bar ID given profile settings
-- @param barID (number|string)
-- @param profileSettings (table, optional)
-- @return string driverString, Frame barHeader
function GridLock:UpdateBarPaging(barID, profileSettings)
    barID = tonumber(barID) or barID or 1
    profileSettings = profileSettings or {}

    local barHeader = profileSettings.header
    if not barHeader then
        if GridLock.bars and GridLock.bars[barID] then
            barHeader = GridLock.bars[barID]
        elseif GridLock.GetBarHeader then
            barHeader = GridLock:GetBarHeader(barID)
        end
    end

    local driverString = ""

    if profileSettings.customDriver and profileSettings.customDriver ~= "" then
        driverString = profileSettings.customDriver
    else
        local parts = {}
        local isMainBar = (barID == 1 or barID == "1" or barID == "bar1" or profileSettings.isMainBar)

        -- 1. Vehicle & Possess Bar
        local useVehicle = (profileSettings.useVehicle ~= false) and isMainBar
        if useVehicle then
            table.insert(parts, "[bonusbar:5]11")
        end

        -- 2. Class Stances / Forms
        local useStances = (profileSettings.useStances ~= false) and isMainBar
        if useStances then
            local stanceDriver = self:GetClassStanceDriver(profileSettings.className)
            if stanceDriver and stanceDriver ~= "" then
                table.insert(parts, stanceDriver)
            end
        end

        -- Custom conditions if provided
        if profileSettings.customConditions and profileSettings.customConditions ~= "" then
            table.insert(parts, profileSettings.customConditions)
        end

        -- 3. Modifier Keys
        local useModifiers = (profileSettings.useModifiers ~= false) and (isMainBar or profileSettings.useModifiers)
        if useModifiers then
            local modStr = profileSettings.modifierString or "[mod:ctrl]2; [mod:alt]3; [mod:shift]4"
            table.insert(parts, modStr)
        end

        -- 4. Standard Bar Paging
        local useBarPaging = (profileSettings.useBarPaging ~= false) and isMainBar
        if useBarPaging then
            table.insert(parts, "[bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6")
        end

        -- 5. Fallback Page
        local fallbackPage = profileSettings.defaultPage or (isMainBar and 1 or barID)
        table.insert(parts, tostring(fallbackPage))

        driverString = table.concat(parts, "; ")
    end

    GridLock.barPagingDrivers = GridLock.barPagingDrivers or {}
    GridLock.barPagingDrivers[barID] = driverString

    if barHeader then
        self:RegisterStateDriver(barHeader, driverString)
    end

    return driverString, barHeader
end

return ActionBarState
