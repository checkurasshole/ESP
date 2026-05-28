if shared.UniversalLobbyDetector then return shared.UniversalLobbyDetector end

local Detector = {}
shared.UniversalLobbyDetector = Detector

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer
local Camera = workspace.CurrentCamera

Detector.LocalPlayerInLobby = false

local LOBBY_FOLDER_NAMES = {
    "Lobby", "lobby", "Hub", "hub", "Spawn", "spawn", "SpawnArea",
    "LobbyArea", "SafeZone", "WaitingArea", "PreGame", "Intermission",
    "MainLobby", "LobbyMap", "LobbyZone", "LobbyRegion", "LobbySpawn",
    "SpawnRoom", "Base", "HomeBase", "Starting", "StartingArea"
}
local LOBBY_THRESHOLD = 450

local function getObjectBounds(obj)
    if not obj then return nil, nil end
    local parts = {}
    if obj:IsA("BasePart") then table.insert(parts, obj) end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("BasePart") then table.insert(parts, v) end
    end
    if #parts == 0 then return nil, nil end
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for _, p in ipairs(parts) do
        local pos = p.Position
        local sz = p.Size / 2
        minX = math.min(minX, pos.X - sz.X)
        minY = math.min(minY, pos.Y - sz.Y)
        minZ = math.min(minZ, pos.Z - sz.Z)
        maxX = math.max(maxX, pos.X + sz.X)
        maxY = math.max(maxY, pos.Y + sz.Y)
        maxZ = math.max(maxZ, pos.Z + sz.Z)
    end
    local center = Vector3.new((minX+maxX)/2, (minY+maxY)/2, (minZ+maxZ)/2)
    local size = Vector3.new(maxX-minX, maxY-minY, maxZ-minZ)
    return center, size
end

local function isInsideBounds(pos, center, size, padding)
    padding = padding or 20
    local half = size / 2
    return math.abs(pos.X - center.X) <= half.X + padding
        and math.abs(pos.Y - center.Y) <= half.Y + padding + 30
        and math.abs(pos.Z - center.Z) <= half.Z + padding
end

local function strContains(str, list)
    str = str:lower():gsub("%s+", "")
    for _, v in ipairs(list) do
        local clean = v:lower():gsub("%s+", "")
        if str == clean or str:find(clean, 1, true) then return true, v end
    end
    return false
end

local LOBBY_TEAM_NAMES = {"lobby","spectator","spectators","waiting","idle","hub","spawn","queue","pre","inactive"}
local MATCH_TEAM_NAMES = {"playing","alive","ingame","fighter","runner","murderer","sheriff","survivor","infected","attacking","defending"}
local STATUS_LOBBY_VALS = {"intermission","waiting","lobby","idle","waiting for players","not enough players","pre-game","pregame","standby","pre game"}
local STATUS_MATCH_VALS = {"playing","ingame","in game","round","started","active","in-game","match","sudden death","overtime","starting"}
local LOBBY_GUI_WORDS = {"lobby","hub","mainmenu","main_menu","waiting","intermission","pregame"}
local MATCH_GUI_WORDS = {"hud","gamehud","matchhud","roundhud","ingamegui","combathud","playgui","ingame","battlehud","fightgui"}
local STATUS_PATHS = {
    {ReplicatedStorage,"Status"},{ReplicatedStorage,"GameStatus"},
    {ReplicatedStorage,"RoundStatus"},{ReplicatedStorage,"GameState"},
    {ReplicatedStorage,"State"},{ReplicatedStorage,"StatusTag"},
    {workspace,"Status"},{workspace,"GameStatus"},{workspace,"State"},
}

local function runDetection()
    local lobbyScore = 0
    local matchScore = 0
    local foundLobbyFolder = nil
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local playerPos = hrp and hrp.Position

    -- CHECK 1: WORKSPACE LOBBY FOLDER
    pcall(function()
        for _, folderName in ipairs(LOBBY_FOLDER_NAMES) do
            local obj = workspace:FindFirstChild(folderName)
            if obj then
                foundLobbyFolder = folderName
                if playerPos then
                    local center, size = getObjectBounds(obj)
                    if center and size then
                        if isInsideBounds(playerPos, center, size) then lobbyScore = lobbyScore + 6
                        else
                            local dist = (playerPos - center).Magnitude
                            if dist < LOBBY_THRESHOLD then lobbyScore = lobbyScore + 4
                            else matchScore = matchScore + 2 end
                        end
                    end
                else lobbyScore = lobbyScore + 2 end
                break
            end
        end
    end)

    -- CHECK 2: TEAMS SERVICE
    pcall(function()
        local team = lp.Team
        if team then
            if strContains(team.Name, LOBBY_TEAM_NAMES) then lobbyScore = lobbyScore + 3
            elseif strContains(team.Name, MATCH_TEAM_NAMES) then matchScore = matchScore + 3 end
        end
    end)

    -- CHECK 3: STATUS VALUES
    for _, path in ipairs(STATUS_PATHS) do
        pcall(function()
            local val = path[1]:FindFirstChild(path[2])
            if val then
                local strVal = tostring(val.Value):lower()
                if strContains(strVal, STATUS_LOBBY_VALS) then lobbyScore = lobbyScore + 4
                elseif strContains(strVal, STATUS_MATCH_VALS) then matchScore = matchScore + 4 end
            end
        end)
    end

    -- CHECK 4: PLAYER ATTRIBUTES
    pcall(function()
        local attrChecks = {"IsInGame","InGame","InRound","Playing","IsPlaying","InMatch","InBattle","InLobby","IsInLobby","GameState"}
        for _, a in ipairs(attrChecks) do
            local val = lp:GetAttribute(a)
            if val ~= nil then
                if a:lower():find("lobby") then
                    if val == true then lobbyScore = lobbyScore + 3 else matchScore = matchScore + 3 end
                else
                    if val == true then matchScore = matchScore + 3 else lobbyScore = lobbyScore + 1 end
                end
                break
            end
        end
    end)

    -- CHECK 5: BOOLVALUE/INTVALUE IN REPLICATEDSTORAGE
    pcall(function()
        local boolChecks = {"InGame","IsInGame","GameActive","RoundActive","GameStarted","IsPlaying","Playing","InRound","GameInProgress"}
        for _, name in ipairs(boolChecks) do
            local val = ReplicatedStorage:FindFirstChild(name) or workspace:FindFirstChild(name)
            if val then
                if typeof(val.Value) == "boolean" then
                    if val.Value then matchScore = matchScore + 3 else lobbyScore = lobbyScore + 3 end
                elseif typeof(val.Value) == "number" then
                    if val.Value == 1 then matchScore = matchScore + 2 elseif val.Value == 0 then lobbyScore = lobbyScore + 2 end
                end
                break
            end
        end
    end)

    -- CHECK 6: PLAYERGUI VISIBLE SCREENS
    pcall(function()
        local playerGui = lp:FindFirstChild("PlayerGui")
        if playerGui then
            for _, child in ipairs(playerGui:GetChildren()) do
                if child:IsA("ScreenGui") and child.Enabled then
                    local nl = child.Name:lower()
                    if strContains(nl, MATCH_GUI_WORDS) then matchScore = matchScore + 2
                    elseif strContains(nl, LOBBY_GUI_WORDS) then lobbyScore = lobbyScore + 2 end
                end
            end
        end
    end)

    -- CHECK 7: FIGHTCONTROLLER (Rivals specific)
    pcall(function()
        local scripts = lp:FindFirstChild("PlayerScripts")
        if scripts then
            local controllers = scripts:FindFirstChild("Controllers")
            if controllers then
                local fc = controllers:FindFirstChild("FighterController")
                if fc then
                    local ok, mod = pcall(require, fc)
                    if ok and mod and mod.LocalFighter then
                        local lf = mod.LocalFighter
                        local ok1, inDuel = pcall(function() return lf:Get("IsInDuel") end)
                        local ok2, inRange = pcall(function() return lf:Get("IsInShootingRange") end)
                        if (ok1 and inDuel) or (ok2 and inRange) then matchScore = matchScore + 5
                        else lobbyScore = lobbyScore + 5 end
                    end
                end
            end
        end
    end)

    -- CHECK 8: COLLECTION SERVICE TAGS
    pcall(function()
        for _, tag in ipairs(CollectionService:GetTags()) do
            local tl = tag:lower()
            if tl:find("ingame") or tl:find("in_game") or tl:find("match") or tl:find("roundactive") then
                if #CollectionService:GetTagged(tag) > 0 then matchScore = matchScore + 2 end
            elseif tl:find("lobby") or tl:find("hub") or tl:find("waiting") then
                if #CollectionService:GetTagged(tag) > 0 then lobbyScore = lobbyScore + 2 end
            end
        end
    end)

    if (lobbyScore + matchScore) > 0 then
        if lobbyScore > matchScore then return true end
        if matchScore > lobbyScore then return false end
    end
    return false
end

-- Initialize the detection loop
Detector.LocalPlayerInLobby = runDetection()

local ticker = 0
RunService.Heartbeat:Connect(function(dt)
    ticker = ticker + dt
    if ticker >= 2 then
        ticker = 0
        Detector.LocalPlayerInLobby = runDetection()
    end
end)

function Detector.IsPlayerInLobby(p)
    if not p or not p.Character then return false end
    if p.Character:FindFirstChildOfClass("ForceField") then return true end
    if p.Team and (p.Team.Name:lower():find("lobby") or p.Team.Name:lower():find("spectator") or p.Team.Name:lower():find("waiting")) then return true end
    return false
end

return Detector
