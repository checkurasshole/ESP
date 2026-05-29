local cloneref = cloneref or function(...) return ... end
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = cloneref(Players.LocalPlayer)

local UniversalAC = {}

function UniversalAC:Init()
    local success, err = pcall(function()
        assert(hookfunction, "executor missing required function hookfunction")
        assert(getconnections, "executor missing required function getconnections")
        assert(newcclosure, "executor missing required function newcclosure")

        local LogService = cloneref(game:GetService("LogService"))
        local ScriptContext = cloneref(game:GetService("ScriptContext"))

        task.spawn(function()
            for _, conn in pairs(getconnections(LogService.MessageOut)) do
                if conn and conn.Function then
                    pcall(function()
                        hookfunction(conn.Function, newcclosure(function(...) end))
                    end)
                end
            end
        end)

        task.spawn(function()
            for _, conn in ipairs(getconnections(ScriptContext.Error)) do
                pcall(function() conn:Disable() end)
            end
            pcall(function()
                hookfunction(ScriptContext.Error.Connect, newcclosure(function(...)
                    return nil
                end))
            end)
        end)

        task.spawn(function()
            local KickNames = { "Kick", "kick" }
            for _, name in ipairs(KickNames) do
                local fn = LocalPlayer[name]
                if type(fn) == "function" then
                    local oldkick
                    oldkick = hookfunction(fn, newcclosure(function(self, ...)
                        if self == LocalPlayer then
                            return
                        end
                        return oldkick(self, ...)
                    end))
                end
            end
        end)
    end)

    if not success then
        warn("Universal AC Bypass Failed: " .. tostring(err))
    end
end

return UniversalAC
