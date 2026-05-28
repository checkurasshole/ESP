local TargetManager = {}

TargetManager.Settings = {
    IncludeNPCs = false,
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Cache for NPCs
local cachedNPCs = {}

local function isPlayerCharacter(model)
    if Players:GetPlayerFromCharacter(model) then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then return true end
    end
    return false
end

local function scanForNPCs()
    local newCache = {}
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("Model") and desc ~= LocalPlayer.Character then
            if desc:FindFirstChild("Humanoid") and desc.PrimaryPart then
                if not isPlayerCharacter(desc) then
                    table.insert(newCache, desc)
                end
            elseif desc:FindFirstChild("Humanoid") and desc:FindFirstChild("HumanoidRootPart") then
                if not isPlayerCharacter(desc) then
                    table.insert(newCache, desc)
                end
            end
        end
    end
    cachedNPCs = newCache
end

-- Re-scan workspace every 5 seconds to find new NPCs without lagging the game
local lastScan = 0
RunService.Heartbeat:Connect(function()
    if not TargetManager.Settings.IncludeNPCs then return end
    if tick() - lastScan > 5 then
        lastScan = tick()
        -- Use a coroutine so the scan doesn't block the render step
        coroutine.wrap(scanForNPCs)()
    end
end)

-- Listens to workspace additions to quickly catch newly spawned NPCs
Workspace.DescendantAdded:Connect(function(desc)
    if not TargetManager.Settings.IncludeNPCs then return end
    if desc:IsA("Model") then
        task.delay(1, function() -- wait for humanoid to load
            if desc.Parent and desc:FindFirstChild("Humanoid") and (desc.PrimaryPart or desc:FindFirstChild("HumanoidRootPart")) then
                if not isPlayerCharacter(desc) then
                    table.insert(cachedNPCs, desc)
                end
            end
        end)
    end
end)

function TargetManager.GetTargets()
    local targets = {}
    
    -- 1. Add Players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            table.insert(targets, {
                Type = "Player",
                Player = p,
                Character = p.Character,
                Team = p.Team,
                TeamColor = p.TeamColor
            })
        end
    end
    
    -- 2. Add NPCs if enabled
    if TargetManager.Settings.IncludeNPCs then
        for i = #cachedNPCs, 1, -1 do
            local npc = cachedNPCs[i]
            if npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("Humanoid").Health > 0 then
                table.insert(targets, {
                    Type = "NPC",
                    Player = nil, -- NPCs don't have a player object
                    Character = npc,
                    Team = nil,
                    TeamColor = nil
                })
            else
                -- Remove invalid/dead NPCs from cache
                table.remove(cachedNPCs, i)
            end
        end
    end
    
    return targets
end

return TargetManager
