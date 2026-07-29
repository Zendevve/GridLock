-- ZenAlign Core Initialization
-- Namespace setup, environment defaults, and addon core hooks

local addonName, ZenAlign = ...
_G.ZenAlign = ZenAlign

ZenAlign.addonName = addonName
ZenAlign.title = "ZenAlign"
ZenAlign.version = "1.0.0"
ZenAlign.wowVersion = 30300

-- Global texture constant for solid textures (compatible with WoW 3.3.5a)
ZenAlign.SOLID_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- Core event registry helper
ZenAlign.events = ZenAlign.events or {}

function ZenAlign:RegisterEventCallback(event, callback)
    if not self.events[event] then
        self.events[event] = {}
    end
    table.insert(self.events[event], callback)
end

function ZenAlign:FireEvent(event, ...)
    if self.events[event] then
        for _, cb in ipairs(self.events[event]) do
            cb(event, ...)
        end
    end
end
