local cloneref = cloneref or function(...) return ... end
local Players = cloneref(game:GetService("Players"))

local NPCManager = {}
local Cache = {}
local Connections = {}

-- Check if a model is a valid NPC (has Humanoid, not a player character)
local function IsValidNPC(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end -- skip player chars
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    if not (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")) then return false end
    return true
end

function NPCManager:GetNPCs()
    local validNPCs = {}
    for i = #Cache, 1, -1 do
        local npc = Cache[i]
        if npc and npc.Parent then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(validNPCs, npc)
            else
                table.remove(Cache, i) -- prune dead/no-humanoid entries
            end
        else
            table.remove(Cache, i) -- prune destroyed entries
        end
    end
    return validNPCs
end

local function TryAddNPC(obj)
    -- Must be a Model at workspace top-level or immediate child of workspace
    if not obj or not obj:IsA("Model") then return end
    if Players:GetPlayerFromCharacter(obj) then return end
    if table.find(Cache, obj) then return end

    -- Check for Humanoid now, or wait briefly in case it's being built
    if obj:FindFirstChildOfClass("Humanoid") then
        if obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") then
            table.insert(Cache, obj)
        end
    else
        -- Wait up to 3 seconds for the Humanoid to appear
        task.spawn(function()
            local hum = obj:WaitForChild("Humanoid", 3)
            if hum and obj.Parent then
                -- Re-check it's not a player char (could have changed)
                if not Players:GetPlayerFromCharacter(obj) then
                    if not table.find(Cache, obj) then
                        table.insert(Cache, obj)
                    end
                end
            end
        end)
    end
end

function NPCManager:Init()
    if #Connections > 0 then return end

    table.clear(Cache)

    -- Initial scan: only look at direct children of workspace that are Models
    -- (NPCs are almost always top-level workspace children)
    for _, obj in ipairs(workspace:GetChildren()) do
        TryAddNPC(obj)
    end

    -- Also scan descendants for NPCs that live deeper (e.g. inside folders)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            TryAddNPC(obj)
        end
    end

    -- Listen for new Models being added to workspace
    table.insert(Connections, workspace.ChildAdded:Connect(function(obj)
        task.wait() -- let it fully load
        TryAddNPC(obj)
    end))

    -- Also watch DescendantAdded for NPCs inside folders
    table.insert(Connections, workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            task.wait()
            TryAddNPC(obj)
        end
    end))
end

function NPCManager:Stop()
    for _, conn in ipairs(Connections) do
        conn:Disconnect()
    end
    table.clear(Connections)
    table.clear(Cache)
end

NPCManager:Init()

return NPCManager
