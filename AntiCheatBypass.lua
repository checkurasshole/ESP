local cloneref = cloneref or function(...) return ... end
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = cloneref(Players.LocalPlayer)

local AntiCheatBypass = {
    Enabled = false
}

function AntiCheatBypass:Init()
    local success, err = pcall(function()
        assert(getgc, "executor missing required function getgc")
        assert(debug and debug.info, "executor missing required function debug.info (somehow)")
        assert(hookfunction, "executor missing required function hookfunction")
        assert(getconnections, "executor missing required function getconnections")
        assert(newcclosure, "executor missing required function newcclosure")
        
        local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
        local LogService = cloneref(game:GetService("LogService"))
        local ScriptContext = cloneref(game:GetService("ScriptContext"))
        
        -- Bypass AnalyticsPipelineController (Server AntiCheat Reporting)
        task.spawn(function()
            local hooked = 0
            for _, v in pairs(getgc(true)) do
                if typeof(v) == "function" then
                    local ok, src = pcall(function()
                        return debug.info(v, "s")
                    end)
                    if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
                        hooked += 1
                        local oldfn
                        oldfn = hookfunction(v, newcclosure(function(...)
                            return wait(9e9)
                        end))
                    end
                end
            end
            print("Hanged " .. hooked .. " Analytics functions")
        end)
        
        -- Bypass Analytics Remote Events
        task.spawn(function()
            local ok, remote = pcall(function()
                return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AnalyticsPipeline"):WaitForChild("RemoteEvent")
            end)
            if ok and remote and remote.OnClientEvent then
                local hooked = 0
                for _, conn in pairs(getconnections(remote.OnClientEvent)) do
                    if conn and conn.Function then
                        if pcall(function()
                            hookfunction(conn.Function, newcclosure(function(...)
                            end))
                        end) then 
                            hooked += 1
                        end
                    end
                end
                print("Hooked " .. hooked .. " anticheat remotes")
            end
        end)
        
        -- Block Console Logs
        task.spawn(function()
            local hooked = 0
            for _, conn in pairs(getconnections(LogService.MessageOut)) do
                if conn and conn.Function then
                    if pcall(function()
                        hookfunction(conn.Function, newcclosure(function(...)
                        end))
                    end) then
                        hooked += 1
                    end
                end
            end
            print("Hooked " .. hooked .. " MessageOut connections")
        end)
        
        -- Block Client Errors
        task.spawn(function()
            local hooked = 0
            for _, conn in ipairs(getconnections(ScriptContext.Error)) do
                if pcall(function()
                    conn:Disable()
                end) then
                    hooked += 1
                end
            end
            print("Hooked " .. hooked .. " error connections")
            pcall(function()
                hookfunction(ScriptContext.Error.Connect, newcclosure(function(...)
                    return nil
                end))
            end)
        end)
        
        -- Universal Anti-Kick
        task.spawn(function()
            local KickNames = {
                "Kick",
                "kick"
            }
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
        warn("AntiCheat Bypass Failed: " .. tostring(err))
    end
end

return AntiCheatBypass
