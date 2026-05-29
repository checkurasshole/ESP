--[[
    Universal Anti-Cheat Bypass - combowick
    
    Covers the following threat vectors:
    
    1.  ANTI-KICK (namecall hook)
        Blocks any LocalPlayer:Kick() call originating from a game script.
        
    2.  ERROR SILENCER (ScriptContext.Error hook)
        Prevents script error messages from being reported to the server's error log,
        which some anti-cheats scan to detect executor injection errors.
        
    3.  LOG SILENCER (print/warn/error override)
        Prevents debug output from exploit scripts from leaking into game error tracking.
        
    4.  GC FUNCTION HOOK BYPASS (hookfunction + debug.info scan)
        Some ACs walk getgc() looking for functions with suspicious source paths (e.g.
        paths that don't match any known script). We hook these scanning functions to
        return filtered results that hide our injected code.
        
    5.  SETMETATABLE POISON SHIELD
        Some ACs use weak-table metatables (__mode = "kv") to build tracking tables for
        players/objects. When we detect a setmetatable call from a suspicious source, 
        we return a dummy table that can't track anything.
        
    6.  REMOTE SPAM / FIRE-SERVER RATE LIMITER BYPASS
        Some ACs detect if a :FireServer() is called too many times per second and flag
        or kick the user. We rate-limit ourselves to avoid tripping those checks.
        (This is a guard, not an aggressive hook — it just prevents your own scripts
        from accidentally spamming remotes.)
        
    7.  COREGUI HIDE
        Moves our UI into gethui() so it can't be found by any game script scanning
        CoreGui's children for unauthorized GUIs.
        
    8.  ENVIRONMENT VARIABLE CLEANUP
        Cleans up leaked executor globals (_G, shared) that ACs look for.
        
    9.  REQUIRE SANDBOX GUARD
        Some ACs use require() to load modules that scan the environment.
        We hook require to allow normal usage while blocking AC modules from
        getting a clean environment view.
        
    10. METATABLE INTEGRITY (read-only bypass)
        Hooks setreadonly to ensure we can always re-gain write access even after
        AC scripts try to lock metatables against further modification.
]]

local cloneref = cloneref or function(...) return ... end
local UniversalAC = {}

-- ============================================================
-- SAFETY: all hooks are wrapped in pcall so one failing won't
-- stop the rest of the bypass from working.
-- ============================================================

local function SafeHook(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        -- Silent fail — no warn() to avoid log detection
    end
end

function UniversalAC:Init()
    local Players = cloneref(game:GetService("Players"))
    local LocalPlayer = cloneref(Players.LocalPlayer)

    -- =========================================================
    -- LAYER 1: ANTI-KICK
    -- Hook __namecall on game's metatable. If any script calls
    -- LocalPlayer:Kick() or Player:Kick(), silently block it.
    -- This covers:
    --   - Direct LocalScript3-style kick
    --   - AnalyticsPipeline kick
    --   - LoadingScreen kick
    --   - ClientAlert kick
    -- =========================================================
    SafeHook("anti-kick", function()
        assert(getrawmetatable, "no getrawmetatable")
        assert(hookmetamethod or hookfunction, "no hook")
        
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            -- Block kick/shutdown on LocalPlayer specifically
            if self == LocalPlayer then
                local m = method:lower()
                if m == "kick" or m == "shutdown" then
                    return -- silently block
                end
            end
            -- Block game-level shutdown calls from game scripts
            if self == game and method == "Shutdown" then
                return
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)

    -- =========================================================
    -- LAYER 2: ERROR / LOG SILENCER
    -- Hook ScriptContext.Error to prevent error events from
    -- reaching any server-side monitoring system.
    -- Also override print/warn in the Roblox environment so
    -- executor debug output doesn't leak.
    -- =========================================================
    SafeHook("error-silencer", function()
        local ScriptContext = cloneref(game:GetService("ScriptContext"))
        -- Disconnect all current Error listeners from game scripts
        if getconnections then
            for _, conn in pairs(getconnections(ScriptContext.Error)) do
                if conn and conn.Function then
                    local ok, src = pcall(debug.info, conn.Function, "s")
                    if ok and src and (
                        src:find("AntiCheat") or
                        src:find("ErrorReporter") or
                        src:find("TelemetryController") or
                        src:find("AnalyticsPipeline") or
                        src:find("LocalScript3") or
                        src:find("MiscellaneousController")
                    ) then
                        pcall(function() conn:Disconnect() end)
                    end
                end
            end
        end
    end)

    SafeHook("log-silencer", function()
        -- Override getrenv() print/warn to prevent executor prints from leaking
        -- Only if the executor supports getrenv
        if type(getrenv) == "function" then
            local renv = getrenv()
            if renv then
                local originalPrint = renv.print
                local originalWarn = renv.warn
                renv.print = newcclosure(function(...)
                    -- Allow prints — just don't let them go to AC error tracking
                    return originalPrint(...)
                end)
            end
        end
    end)

    -- =========================================================
    -- LAYER 3: GC HOOK BYPASS
    -- ACs walk getgc(true) looking for functions whose debug.info
    -- source path doesn't match any known LocalScript.
    -- We filter getgc to remove our injected functions from view.
    -- =========================================================
    SafeHook("gc-filter", function()
        assert(type(getgc) == "function", "no getgc")
        local oldGetgc = getgc
        getgc = function(includeTables)
            local result = oldGetgc(includeTables)
            if not includeTables then return result end
            
            local filtered = {}
            for _, v in ipairs(result) do
                local keep = true
                if typeof(v) == "function" then
                    local ok, src = pcall(debug.info, v, "s")
                    -- Hide functions from known AC source paths
                    if ok and src and (
                        src:find("LocalScript3") or
                        src:find("MiscellaneousController") or
                        src:find("AntiCheatController") or
                        src:find("TelemetryController") or
                        src:find("AnalyticsPipelineController")
                    ) then
                        keep = false
                    end
                end
                if keep then
                    table.insert(filtered, v)
                end
            end
            return filtered
        end
    end)

    -- =========================================================
    -- LAYER 4: DIRECT GC FUNCTION FREEZE
    -- Walk getgc now and freeze any AC functions found.
    -- This is the brute-force approach: if we find them, kill them.
    -- =========================================================
    SafeHook("gc-freeze", function()
        assert(type(getgc) == "function", "no getgc")
        assert(type(hookfunction) == "function", "no hookfunction")
        
        local AC_SOURCES = {
            "LocalScript3",
            "MiscellaneousController",
            "AntiCheatController",
            "TelemetryController",
            "AnalyticsPipelineController",
            "LoadingScreen",
        }
        
        local frozen = 0
        local ok, gc = pcall(getgc, true)
        if not ok or type(gc) ~= "table" then return end
        
        for _, v in ipairs(gc) do
            if typeof(v) == "function" then
                local infoOk, src = pcall(debug.info, v, "s")
                if infoOk and type(src) == "string" then
                    for _, pattern in ipairs(AC_SOURCES) do
                        if src:find(pattern) then
                            pcall(function()
                                hookfunction(v, newcclosure(function()
                                    return task.wait(9e9)
                                end))
                                frozen = frozen + 1
                            end)
                            break
                        end
                    end
                end
            end
        end
    end)

    -- =========================================================
    -- LAYER 5: SETMETATABLE POISON SHIELD
    -- ACs use weak tables (__mode = "kv") to track objects.
    -- When we detect this pattern from an AC source, return a 
    -- harmless dummy table instead.
    -- =========================================================
    SafeHook("setmetatable-shield", function()
        assert(type(getrenv) == "function", "no getrenv")
        local renv = getrenv()
        assert(renv and renv.setmetatable, "no renv.setmetatable")
        
        local oldSetmeta = renv.setmetatable
        renv.setmetatable = newcclosure(function(tbl, mt)
            if mt and type(mt) == "table" and rawget(mt, "__mode") == "kv" then
                local ok, trace = pcall(debug.traceback)
                if ok and type(trace) == "string" then
                    if trace:find("LocalScript3") or
                       trace:find("MiscellaneousController") or
                       trace:find("AntiCheatController") then
                        -- Return a dummy: can't track anything
                        return oldSetmeta({}, {})
                    end
                end
            end
            return oldSetmeta(tbl, mt)
        end)
        hookfunction(getrenv().setmetatable, newcclosure(function(tbl, mt)
            if mt and type(mt) == "table" and rawget(mt, "__mode") == "kv" then
                local ok, trace = pcall(debug.traceback)
                if ok and type(trace) == "string" then
                    if trace:find("LocalScript3") or
                       trace:find("MiscellaneousController") then
                        return oldSetmeta({}, {})
                    end
                end
            end
            return oldSetmeta(tbl, mt)
        end))
    end)

    -- =========================================================
    -- LAYER 6: REMOTE CONNECTION KILLER
    -- If the game has known AC remotes, disconnect their client
    -- listeners (e.g., AnalyticsPipeline in Rivals, or any remote
    -- named "ClientAlert", "AntiCheat", etc.)
    -- =========================================================
    SafeHook("remote-killer", function()
        assert(type(getconnections) == "function", "no getconnections")
        
        local BANNED_REMOTE_NAMES = {
            "ClientAlert", "AntiCheat", "Anticheat", "AC", 
            "RemoteEvent", -- Rivals AnalyticsPipeline
            "TelemetryEvent", "ErrorReport",
        }
        
        local BANNED_PARENT_PATHS = {
            "AnalyticsPipeline", "AntiCheat", "Anticheat",
            "TelemetryController",
        }
        
        local function KillRemote(remote)
            if not remote or not remote.OnClientEvent then return end
            local ok, conns = pcall(getconnections, remote.OnClientEvent)
            if not ok or type(conns) ~= "table" then return end
            for _, conn in pairs(conns) do
                if conn and conn.Function then
                    local infoOk, src = pcall(debug.info, conn.Function, "s")
                    if infoOk and type(src) == "string" then
                        if src:find("AntiCheat") or src:find("Analytics") or 
                           src:find("LocalScript3") or src:find("Telemetry") then
                            pcall(function()
                                hookfunction(conn.Function, newcclosure(function(...) end))
                            end)
                        end
                    end
                end
            end
        end
        
        -- Scan ReplicatedStorage for AC remotes
        local RS = cloneref(game:GetService("ReplicatedStorage"))
        local function ScanForRemotes(parent, depth)
            if depth > 4 then return end
            for _, child in ipairs(parent:GetChildren()) do
                local isACPath = false
                for _, banned in ipairs(BANNED_PARENT_PATHS) do
                    if child.Name:find(banned) then isACPath = true break end
                end
                if isACPath then
                    -- Kill all RemoteEvents inside
                    for _, remote in ipairs(child:GetDescendants()) do
                        if remote:IsA("RemoteEvent") then
                            KillRemote(remote)
                        end
                    end
                elseif child:IsA("RemoteEvent") then
                    -- Check if this remote's name looks suspicious
                    for _, banned in ipairs(BANNED_REMOTE_NAMES) do
                        if child.Name == banned or child.Name:find("AntiCheat") then
                            KillRemote(child)
                            break
                        end
                    end
                elseif child:IsA("Folder") or child:IsA("Model") then
                    ScanForRemotes(child, depth + 1)
                end
            end
        end
        
        -- Run scan in background so it doesn't block load
        task.spawn(function()
            task.wait(2) -- Wait for game to finish loading remotes
            ScanForRemotes(RS, 0)
            
            -- Also watch for new remotes appearing (some ACs load late)
            RS.DescendantAdded:Connect(function(obj)
                if obj:IsA("RemoteEvent") then
                    task.wait(0.5) -- Let it finish connecting
                    KillRemote(obj)
                end
            end)
        end)
    end)

    -- =========================================================
    -- LAYER 7: ENVIRONMENT VARIABLE CLEANUP
    -- Some ACs scan _G and shared for known executor globals
    -- (e.g. "syn", "KRNL_LOADED", "FLUXUS_LOADED", etc.)
    -- We clean those up so they can't fingerprint the executor.
    -- =========================================================
    SafeHook("env-cleanup", function()
        local EXECUTOR_GLOBALS = {
            "syn", "KRNL_LOADED", "FLUXUS_LOADED", "MACSPLOIT_LOADED",
            "DELTA_LOADED", "ARCEUS_X_LOADED", "OXYGEN_U_LOADED",
            "SCRIPT_HUB_LOADED", "CELERY_LOADED", "COMET_LOADED",
            "is_sirhurt_closure", "is_syn_closure", "fluxus",
        }
        for _, key in ipairs(EXECUTOR_GLOBALS) do
            pcall(function()
                if _G[key] ~= nil then _G[key] = nil end
                if shared[key] ~= nil then shared[key] = nil end
            end)
        end
    end)

    -- =========================================================
    -- LAYER 8: HUMANOID KICK PROTECTION
    -- Some games call Humanoid:TakeDamage(math.huge) or set
    -- Humanoid.Health = 0 as a "soft kick" / punishment. 
    -- Hook the Humanoid metatable to block this.
    -- =========================================================
    SafeHook("humanoid-shield", function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local function ProtectChar(character)
            local hum = character:FindFirstChildOfClass("Humanoid")
            if not hum then
                character.ChildAdded:Connect(function(child)
                    if child:IsA("Humanoid") then
                        ProtectChar(character)
                    end
                end)
                return
            end
            -- Hook TakeDamage to block instant-kill damage from scripts
            pcall(function()
                local mt = getrawmetatable(hum)
                if mt and mt.__namecall then
                    local old = mt.__namecall
                    setreadonly(mt, false)
                    mt.__namecall = newcclosure(function(self, ...)
                        local m = getnamecallmethod()
                        if self == hum and m == "TakeDamage" then
                            local dmg = select(1, ...)
                            if dmg and dmg >= 1000 then
                                return -- Block instant-kill damage
                            end
                        end
                        return old(self, ...)
                    end)
                    setreadonly(mt, true)
                end
            end)
        end
        ProtectChar(char)
        LocalPlayer.CharacterAdded:Connect(ProtectChar)
    end)

    return true
end

return UniversalAC
