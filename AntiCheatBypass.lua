local cloneref = cloneref or function(...) return ... end
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = cloneref(Players.LocalPlayer)

local RivalsAC = {}

function RivalsAC:Init()
    local success, err = pcall(function()
        assert(getgc, "executor missing required function getgc")
        assert(debug and debug.info, "executor missing required function debug.info")
        assert(hookfunction, "executor missing required function hookfunction")
        assert(getconnections, "executor missing required function getconnections")
        assert(newcclosure, "executor missing required function newcclosure")

        local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

        -- Hook AnalyticsPipelineController functions in GC (original logic restored)
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
        end)

        -- Hook Analytics RemoteEvent connections
        -- Uses WaitForChild with a short timeout so it only applies when in Rivals
        task.spawn(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
            if not remotes then return end
            local pipeline = remotes:WaitForChild("AnalyticsPipeline", 10)
            if not pipeline then return end
            local remote = pipeline:WaitForChild("RemoteEvent", 10)
            if not remote or not remote.OnClientEvent then return end
            for _, conn in pairs(getconnections(remote.OnClientEvent)) do
                if conn and conn.Function then
                    pcall(function()
                        hookfunction(conn.Function, newcclosure(function(...) end))
                    end)
                end
            end
        end)
    end)

    if not success then
        warn("Rivals AC Bypass Failed: " .. tostring(err))
    end
end

return RivalsAC
