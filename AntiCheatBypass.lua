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

        -- Part 1: Hook AnalyticsPipelineController functions in GC
        -- This targets the MODULE script directly, no WaitForChild needed
        task.spawn(function()
            local hooked = 0
            for _, v in pairs(getgc(true)) do
                if typeof(v) == "function" then
                    local ok, src = pcall(function()
                        return debug.info(v, "s")
                    end)
                    if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
                        hooked += 1
                        hookfunction(v, newcclosure(function(...)
                            return wait(9e9)
                        end))
                    end
                end
            end
        end)

        -- Part 2: Hook the RemoteEvent connections
        -- Uses FindFirstChild polling — NEVER blocks the thread
        task.spawn(function()
            local startTime = os.clock()
            local timeout = 8 -- seconds to wait for Rivals to load its remotes
            
            while os.clock() - startTime < timeout do
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local pipeline = remotes:FindFirstChild("AnalyticsPipeline")
                    if pipeline then
                        local remote = pipeline:FindFirstChild("RemoteEvent")
                        if remote and remote.OnClientEvent then
                            for _, conn in pairs(getconnections(remote.OnClientEvent)) do
                                if conn and conn.Function then
                                    pcall(function()
                                        hookfunction(conn.Function, newcclosure(function(...) end))
                                    end)
                                end
                            end
                            return -- Done, hooked successfully
                        end
                    end
                end
                task.wait(0.5) -- Poll every 0.5s, no blocking whatsoever
            end
            -- If we reach here, we're not in Rivals — silently give up
        end)
    end)

    if not success then
        warn("Rivals AC Bypass Failed: " .. tostring(err))
    end
end

return RivalsAC
