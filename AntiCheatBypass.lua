-- Rivals Anti-Cheat Bypass
-- Based on: github.com/swish-hub/rivals-ac (BETA)
-- Integrated into combowick ESP framework

local cloneref = cloneref or function(...) return ... end

local RivalsAC = {}

function RivalsAC:Init()
    -- Verify executor has the required capabilities
    if not (type(getgc) == "function" and type(hookfunction) == "function" and type(newcclosure) == "function") then
        warn("[RivalsAC] Executor missing required functions (getgc, hookfunction, newcclosure). Bypass skipped.")
        return false
    end
    if not (type(debug) == "table" and type(debug.info) == "function" and type(debug.traceback) == "function") then
        warn("[RivalsAC] Executor missing debug library. Bypass skipped.")
        return false
    end

    local hooked = 0
    local errors = 0

    -- ========================================================================
    -- LAYER 1: Hook setmetatable in the Roblox environment
    -- Rivals' LocalScript3 and MiscellaneousController use weak tables (__mode = "kv")
    -- to track players/objects. We intercept those calls and return a dummy table,
    -- making the AC unable to properly track anything.
    -- ========================================================================
    pcall(function()
        local oldSetmetatable
        oldSetmetatable = hookfunction(getrenv().setmetatable, newcclosure(function(Table, Metatable)
            if Metatable and type(Metatable) == "table" and rawget(Metatable, "__mode") == "kv" then
                local ok, trace = pcall(debug.traceback)
                if ok and type(trace) == "string" then
                    if trace:find("LocalScript3") or trace:find("MiscellaneousController") then
                        -- Return a useless dummy table so AC can't track anything
                        return oldSetmetatable({1, 2, 3}, {})
                    end
                end
            end
            return oldSetmetatable(Table, Metatable)
        end))
        hooked = hooked + 1
    end)

    -- ========================================================================
    -- LAYER 2: Filter getgc to hide LocalScript3 / MiscellaneousController functions
    -- The AC uses getgc to find and inspect executor functions.
    -- We filter the results so AC scripts are invisible to any getgc calls.
    -- ========================================================================
    pcall(function()
        local oldGetgc = getgc
        getgc = function(...)
            local gc = oldGetgc(...)
            local filtered = {}
            for _, v in ipairs(gc) do
                if typeof(v) == "function" then
                    local ok, src = pcall(debug.info, v, "s")
                    if ok and src and (src:find("LocalScript3") or src:find("MiscellaneousController")) then
                        -- Hide this function from the AC's view
                    else
                        table.insert(filtered, v)
                    end
                else
                    table.insert(filtered, v)
                end
            end
            return filtered
        end
        hooked = hooked + 1
    end)

    -- ========================================================================
    -- LAYER 3: Direct function hook — freeze all AC functions from those scripts
    -- Walk the GC and hook any function originating from LocalScript3 or
    -- MiscellaneousController to wait(9e9), effectively disabling them.
    -- ========================================================================
    pcall(function()
        for _, v in ipairs(getgc(true)) do
            if typeof(v) == "function" then
                local ok, src = pcall(debug.info, v, "s")
                if ok and type(src) == "string" then
                    if src:find("LocalScript3") or src:find("MiscellaneousController") then
                        pcall(function()
                            hookfunction(v, newcclosure(function()
                                return task.wait(9e9)
                            end))
                            hooked = hooked + 1
                        end)
                    end
                end
            end
        end
    end)

    -- ========================================================================
    -- LAYER 4 (bonus): Block Kick metamethod on LocalPlayer
    -- Even if AC bypasses layers 1-3, this prevents it from kicking you
    -- ========================================================================
    pcall(function()
        local Players = cloneref(game:GetService("Players"))
        local LocalPlayer = cloneref(Players.LocalPlayer)
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if self == LocalPlayer and (m == "Kick" or m == "kick") then
                return -- Block kick silently
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        hooked = hooked + 1
    end)

    return hooked > 0
end

return RivalsAC
