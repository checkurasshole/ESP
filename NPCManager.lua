local cloneref = cloneref or function(...) return ... end
local Players = cloneref(game:GetService("Players"))

local NPCManager = {}
local Cache = {}
local Connection

function NPCManager:GetNPCs()
    local validNPCs = {}
    for _, npc in ipairs(Cache) do
        if npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 and (npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart")) then
            table.insert(validNPCs, npc)
        end
    end
    return validNPCs
end

local function CheckNPC(obj)
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
        if not Players:GetPlayerFromCharacter(obj) then
            if not table.find(Cache, obj) then
                table.insert(Cache, obj)
            end
        end
    end
end

function NPCManager:Init()
    if Connection then return end
    
    table.clear(Cache)
    
    -- Initial scan
    for _, obj in ipairs(workspace:GetDescendants()) do
        CheckNPC(obj)
    end
    
    -- Listen for new NPCs spawning
    Connection = workspace.DescendantAdded:Connect(function(obj)
        task.wait() -- wait a frame in case Humanoid is added slightly after Model
        CheckNPC(obj)
    end)
    
    -- We don't need DescendantRemoving because GetNPCs() filters out invalid parents/destroyed objects automatically
end

function NPCManager:Stop()
    if Connection then
        Connection:Disconnect()
        Connection = nil
    end
    table.clear(Cache)
end

-- Auto-init
NPCManager:Init()

return NPCManager
