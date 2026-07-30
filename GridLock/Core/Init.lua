-- GridLock Core Initialization
-- Namespace setup, environment defaults, and addon core hooks

local addonName, GridLock = ...
_G.GridLock = GridLock

GridLock.addonName = addonName
GridLock.title = "GridLock"
GridLock.version = "1.0.0"
GridLock.wowVersion = 30300

-- Global texture constant for solid textures (compatible with WoW 3.3.5a)
GridLock.SOLID_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- Core event registry helper
GridLock.events = GridLock.events or {}

function GridLock:RegisterEventCallback(event, callback)
    if not self.events[event] then
        self.events[event] = {}
    end
    table.insert(self.events[event], callback)
end

function GridLock:FireEvent(event, ...)
    if self.events[event] then
        for _, cb in ipairs(self.events[event]) do
            cb(event, ...)
        end
    end
end
