local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local isInLobby = nil

local LOBBY_FOLDER_NAMES = {
    "Lobby", "lobby", "Hub", "hub", "Spawn", "spawn", "SpawnArea",
    "LobbyArea", "SafeZone", "WaitingArea", "PreGame", "Intermission",
    "MainLobby", "LobbyMap", "LobbyZone", "LobbyRegion", "LobbySpawn",
    "SpawnRoom", "Base", "HomeBase", "Starting", "StartingArea"
}
local LOBBY_THRESHOLD = 450

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalLobbyDetector"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = game.CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 310, 0, 250)
main.Position = UDim2.new(0, 12, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(50, 50, 70)
stroke.Thickness = 1

local topbar = Instance.new("Frame", main)
topbar.Size = UDim2.new(1, 0, 0, 38)
topbar.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
topbar.BorderSizePixel = 0
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 10)
local topfix = Instance.new("Frame", topbar)
topfix.Size = UDim2.new(1, 0, 0.5, 0)
topfix.Position = UDim2.new(0, 0, 0.5, 0)
topfix.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
topfix.BorderSizePixel = 0

local icon = Instance.new("TextLabel", topbar)
icon.Size = UDim2.new(0, 20, 1, 0)
icon.Position = UDim2.new(0, 10, 0, 0)
icon.BackgroundTransparency = 1
icon.Text = "◈"
icon.TextColor3 = Color3.fromRGB(120, 100, 255)
icon.TextSize = 14
icon.Font = Enum.Font.GothamBold

local title = Instance.new("TextLabel", topbar)
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 34, 0, 0)
title.BackgroundTransparency = 1
title.Text = "UNIVERSAL LOBBY DETECTOR"
title.TextColor3 = Color3.fromRGB(210, 210, 255)
title.TextSize = 11
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", topbar)
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Position = UDim2.new(1, -58, 0.5, -12)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
minimizeBtn.TextSize = 10
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 10
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, 0, 1, -38)
content.Position = UDim2.new(0, 0, 0, 38)
content.BackgroundTransparency = 1

local statusBox = Instance.new("Frame", content)
statusBox.Size = UDim2.new(1, -20, 0, 50)
statusBox.Position = UDim2.new(0, 10, 0, 8)
statusBox.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
statusBox.BorderSizePixel = 0
Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 8)

local statusDot = Instance.new("Frame", statusBox)
statusDot.Size = UDim2.new(0, 12, 0, 12)
statusDot.Position = UDim2.new(0, 14, 0.5, -6)
statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
statusDot.BorderSizePixel = 0
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusText = Instance.new("TextLabel", statusBox)
statusText.Size = UDim2.new(1, -40, 0.5, 0)
statusText.Position = UDim2.new(0, 34, 0, 4)
statusText.BackgroundTransparency = 1
statusText.Text = "SCANNING..."
statusText.TextColor3 = Color3.fromRGB(200, 200, 255)
statusText.TextSize = 14
statusText.Font = Enum.Font.GothamBold
statusText.TextXAlignment = Enum.TextXAlignment.Left

local confidenceLabel = Instance.new("TextLabel", statusBox)
confidenceLabel.Size = UDim2.new(1, -40, 0.5, 0)
confidenceLabel.Position = UDim2.new(0, 34, 0.5, -2)
confidenceLabel.BackgroundTransparency = 1
confidenceLabel.Text = "Confidence: --"
confidenceLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
confidenceLabel.TextSize = 10
confidenceLabel.Font = Enum.Font.Gotham
confidenceLabel.TextXAlignment = Enum.TextXAlignment.Left

local folderLabel = Instance.new("TextLabel", content)
folderLabel.Size = UDim2.new(1, -20, 0, 14)
folderLabel.Position = UDim2.new(0, 10, 0, 66)
folderLabel.BackgroundTransparency = 1
folderLabel.Text = "LOBBY FOLDER: not found"
folderLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
folderLabel.TextSize = 9
folderLabel.Font = Enum.Font.Code
folderLabel.TextXAlignment = Enum.TextXAlignment.Left

local divider = Instance.new("Frame", content)
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 84)
divider.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
divider.BorderSizePixel = 0

local logLabel = Instance.new("TextLabel", content)
logLabel.Size = UDim2.new(1, -20, 0, 14)
logLabel.Position = UDim2.new(0, 10, 0, 89)
logLabel.BackgroundTransparency = 1
logLabel.Text = "DETECTION CHECKS"
logLabel.TextColor3 = Color3.fromRGB(80, 80, 120)
logLabel.TextSize = 9
logLabel.Font = Enum.Font.GothamBold
logLabel.TextXAlignment = Enum.TextXAlignment.Left

local scroll = Instance.new("ScrollingFrame", content)
scroll.Size = UDim2.new(1, -20, 0, 118)
scroll.Position = UDim2.new(0, 10, 0, 106)
scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)
local listLayout = Instance.new("UIListLayout", scroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 1)
local lpad = Instance.new("UIPadding", scroll)
lpad.PaddingTop = UDim.new(0, 4)
lpad.PaddingLeft = UDim.new(0, 6)
lpad.PaddingRight = UDim.new(0, 4)

local minimized = false
local dragging, dragInput, dragStart, startPos

topbar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
topbar.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        dragInput = i
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(i)
    if i == dragInput and dragging then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(main, TweenInfo.new(0.2), {Size = UDim2.new(0, 310, 0, 38)}):Play()
        minimizeBtn.Text = "+"
    else
        TweenService:Create(main, TweenInfo.new(0.2), {Size = UDim2.new(0, 310, 0, 250)}):Play()
        minimizeBtn.Text = "—"
    end
end)

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local function clearLogs()
    for _, v in ipairs(scroll:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
end

local function logCheck(name, result, detail)
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.LayoutOrder = #scroll:GetChildren()
    local dot = Instance.new("Frame", row)
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 0, 0.5, -3)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -14, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    if result == true then
        dot.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
        lbl.TextColor3 = Color3.fromRGB(80, 220, 120)
        lbl.Text = "[+] " .. name .. (detail and (": " .. tostring(detail)) or "")
    elseif result == false then
        dot.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
        lbl.TextColor3 = Color3.fromRGB(220, 80, 80)
        lbl.Text = "[-] " .. name .. (detail and (": " .. tostring(detail)) or "")
    else
        dot.BackgroundColor3 = Color3.fromRGB(160, 160, 60)
        lbl.TextColor3 = Color3.fromRGB(180, 180, 80)
        lbl.Text = "[?] " .. name .. (detail and (": " .. tostring(detail)) or "")
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
    scroll.CanvasPosition = Vector2.new(0, scroll.CanvasSize.Y.Offset)
end

local function setStatus(lobby, conf)
    if lobby == true then
        statusText.Text = "IN LOBBY"
        statusText.TextColor3 = Color3.fromRGB(80, 220, 120)
        statusDot.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
        TweenService:Create(main, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(15, 20, 15)}):Play()
        stroke.Color = Color3.fromRGB(40, 100, 60)
    elseif lobby == false then
        statusText.Text = "NOT IN LOBBY"
        statusText.TextColor3 = Color3.fromRGB(220, 80, 80)
        statusDot.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
        TweenService:Create(main, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(20, 12, 12)}):Play()
        stroke.Color = Color3.fromRGB(100, 40, 40)
    else
        statusText.Text = "UNKNOWN"
        statusText.TextColor3 = Color3.fromRGB(180, 180, 80)
        statusDot.BackgroundColor3 = Color3.fromRGB(180, 180, 80)
        TweenService:Create(main, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(15, 15, 20)}):Play()
        stroke.Color = Color3.fromRGB(80, 80, 100)
    end
    confidenceLabel.Text = "Confidence: " .. (conf or "--")
end

local function getPartCenter(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("BasePart") then return v.Position end
    end
    return nil
end

local function getObjectBounds(obj)
    if not obj then return nil, nil end
    local parts = {}
    if obj:IsA("BasePart") then
        table.insert(parts, obj)
    end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("BasePart") then
            table.insert(parts, v)
        end
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
    clearLogs()
    local lobbyScore = 0
    local matchScore = 0
    local foundLobbyFolder = nil
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local playerPos = hrp and hrp.Position

    -- CHECK 1: WORKSPACE LOBBY FOLDER + POSITION INSIDE IT (primary method)
    local wsLobbyResult = nil
    local wsLobbyDetail = "no lobby folder found"
    pcall(function()
        for _, folderName in ipairs(LOBBY_FOLDER_NAMES) do
            local obj = workspace:FindFirstChild(folderName)
            if obj then
                foundLobbyFolder = folderName
                folderLabel.Text = "LOBBY FOLDER: workspace." .. folderName .. " (" .. #obj:GetDescendants() .. " children)"
                folderLabel.TextColor3 = Color3.fromRGB(80, 200, 130)

                if playerPos then
                    local center, size = getObjectBounds(obj)

                    if center and size then
                        if isInsideBounds(playerPos, center, size) then
                            lobbyScore = lobbyScore + 6
                            wsLobbyResult = true
                            wsLobbyDetail = folderName .. " (inside bounds)"
                        else
                            local dist = (playerPos - center).Magnitude
                            if dist < LOBBY_THRESHOLD then
                                lobbyScore = lobbyScore + 4
                                wsLobbyResult = true
                                wsLobbyDetail = folderName .. " dist=" .. math.floor(dist)
                            else
                                matchScore = matchScore + 2
                                wsLobbyResult = false
                                wsLobbyDetail = folderName .. " found but far (" .. math.floor(dist) .. ")"
                            end
                        end
                    else
                        local center2 = getPartCenter(obj)
                        if center2 then
                            local dist = (playerPos - center2).Magnitude
                            wsLobbyDetail = folderName .. " center dist=" .. math.floor(dist)
                            if dist < LOBBY_THRESHOLD then
                                lobbyScore = lobbyScore + 4
                                wsLobbyResult = true
                            else
                                matchScore = matchScore + 2
                                wsLobbyResult = false
                            end
                        end
                    end

                    -- CHECK SPAWN LOCATIONS inside lobby folder
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child:IsA("SpawnLocation") or child:IsA("BasePart") and child.Name:lower():find("spawn") then
                            local spawnDist = (playerPos - child.Position).Magnitude
                            if spawnDist < 100 then
                                lobbyScore = lobbyScore + 3
                                wsLobbyDetail = wsLobbyDetail .. " +spawn(" .. math.floor(spawnDist) .. ")"
                                wsLobbyResult = true
                                break
                            end
                        end
                    end
                else
                    wsLobbyDetail = folderName .. " exists (no char)"
                    lobbyScore = lobbyScore + 2
                    wsLobbyResult = nil
                end
                break
            end
        end
        if not foundLobbyFolder then
            folderLabel.Text = "LOBBY FOLDER: not found in workspace"
            folderLabel.TextColor3 = Color3.fromRGB(120, 80, 80)
        end
    end)
    logCheck("WorkspaceLobby", wsLobbyResult, wsLobbyDetail)

    -- CHECK 2: ANY OTHER WORKSPACE MAP FOLDER (arena/map = not lobby)
    local wsMapResult = nil
    local wsMapDetail = "none found"
    pcall(function()
        local mapNames = {"Map","Arena","GameMap","CurrentMap","Battleground","RoundMap","ActiveMap","GameArena","FightZone","BattleZone"}
        for _, name in ipairs(mapNames) do
            local obj = workspace:FindFirstChild(name)
            if obj and (obj:IsA("Model") or obj:IsA("Folder")) then
                if not foundLobbyFolder then
                    matchScore = matchScore + 2
                    wsMapResult = false
                    wsMapDetail = name .. " exists"
                end
                break
            end
        end
    end)
    logCheck("WorkspaceMap", wsMapResult, wsMapDetail)

    -- CHECK 3: PLAYER PROXIMITY TO ANY LOBBY-NAMED PART ANYWHERE IN WORKSPACE
    local proxResult = nil
    local proxDetail = "no lobby part found"
    pcall(function()
        if playerPos then
            local lobbyPartNames = {"LobbySpawn","LobbyPad","LobbyFloor","LobbyBase","LobbyCenter","SpawnIsland","HubBase","SpawnPlatform"}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    for _, pname in ipairs(lobbyPartNames) do
                        if v.Name:lower() == pname:lower() then
                            local d = (playerPos - v.Position).Magnitude
                            proxDetail = v.Name .. " dist=" .. math.floor(d)
                            if d < 150 then
                                lobbyScore = lobbyScore + 3
                                proxResult = true
                            elseif d < LOBBY_THRESHOLD then
                                lobbyScore = lobbyScore + 1
                                proxResult = true
                            else
                                matchScore = matchScore + 1
                                proxResult = false
                            end
                            break
                        end
                    end
                    if proxResult ~= nil then break end
                end
            end
        end
    end)
    logCheck("LobbyPartProx", proxResult, proxDetail)

    -- CHECK 4: TEAMS SERVICE
    local teamResult = nil
    local teamDetail = "no team"
    pcall(function()
        local team = lp.Team
        if team then
            teamDetail = team.Name
            local lm = strContains(team.Name, LOBBY_TEAM_NAMES)
            local mm = strContains(team.Name, MATCH_TEAM_NAMES)
            if lm then lobbyScore = lobbyScore + 3; teamResult = true
            elseif mm then matchScore = matchScore + 3; teamResult = false end
        else
            local allTeams = Teams:GetTeams()
            if #allTeams == 0 then
                teamDetail = "no teams in game"
            else
                teamDetail = "on no team (" .. #allTeams .. " teams)"
                lobbyScore = lobbyScore + 1
                teamResult = true
            end
        end
    end)
    logCheck("Teams", teamResult, teamDetail)

    -- CHECK 5: REPLICATEDSTORAGE / WORKSPACE STATUS VALUES
    local statusResult = nil
    local statusDetail = "not found"
    for _, path in ipairs(STATUS_PATHS) do
        pcall(function()
            local val = path[1]:FindFirstChild(path[2])
            if val then
                local strVal = tostring(val.Value):lower()
                statusDetail = path[2] .. "=" .. tostring(val.Value)
                local lm = strContains(strVal, STATUS_LOBBY_VALS)
                local mm = strContains(strVal, STATUS_MATCH_VALS)
                if lm then lobbyScore = lobbyScore + 4; statusResult = true
                elseif mm then matchScore = matchScore + 4; statusResult = false
                else statusDetail = path[2] .. "=" .. tostring(val.Value) .. " (unknown)" end
            end
        end)
        if statusResult ~= nil then break end
    end
    logCheck("StatusValue", statusResult, statusDetail)

    -- CHECK 6: PLAYER ATTRIBUTES
    local attrResult = nil
    local attrDetail = "none found"
    pcall(function()
        local attrChecks = {"IsInGame","InGame","InRound","Playing","IsPlaying","InMatch","InBattle","InLobby","IsInLobby","GameState"}
        for _, a in ipairs(attrChecks) do
            local val = lp:GetAttribute(a)
            if val ~= nil then
                attrDetail = a .. "=" .. tostring(val)
                local nameLower = a:lower()
                if nameLower:find("lobby") then
                    if val == true then lobbyScore = lobbyScore + 3; attrResult = true
                    else matchScore = matchScore + 3; attrResult = false end
                else
                    if val == true then matchScore = matchScore + 3; attrResult = false
                    else lobbyScore = lobbyScore + 1; attrResult = true end
                end
                break
            end
        end
    end)
    logCheck("PlayerAttr", attrResult, attrDetail)

    -- CHECK 7: BOOLVALUE/INTVALUE IN REPLICATEDSTORAGE
    local boolResult = nil
    local boolDetail = "not found"
    pcall(function()
        local boolChecks = {"InGame","IsInGame","GameActive","RoundActive","GameStarted","IsPlaying","Playing","InRound","GameInProgress"}
        for _, name in ipairs(boolChecks) do
            local val = ReplicatedStorage:FindFirstChild(name) or workspace:FindFirstChild(name)
            if val then
                boolDetail = name .. "=" .. tostring(val.Value)
                if typeof(val.Value) == "boolean" then
                    if val.Value then matchScore = matchScore + 3; boolResult = false
                    else lobbyScore = lobbyScore + 3; boolResult = true end
                elseif typeof(val.Value) == "number" then
                    if val.Value == 1 then matchScore = matchScore + 2; boolResult = false
                    elseif val.Value == 0 then lobbyScore = lobbyScore + 2; boolResult = true end
                end
                break
            end
        end
    end)
    logCheck("InGameValue", boolResult, boolDetail)

    -- CHECK 8: PLAYERGUI VISIBLE SCREENS
    local guiResult = nil
    local guiDetail = "none matched"
    pcall(function()
        local playerGui = lp:FindFirstChild("PlayerGui")
        if playerGui then
            for _, child in ipairs(playerGui:GetChildren()) do
                if child:IsA("ScreenGui") and child.Enabled then
                    local nl = child.Name:lower()
                    local lm = strContains(nl, LOBBY_GUI_WORDS)
                    local mm = strContains(nl, MATCH_GUI_WORDS)
                    if mm then matchScore = matchScore + 2; guiResult = false; guiDetail = child.Name
                    elseif lm then lobbyScore = lobbyScore + 2; guiResult = true; guiDetail = child.Name end
                end
            end
        end
    end)
    logCheck("PlayerGui", guiResult, guiDetail)

    -- CHECK 9: FIGHTCONTROLLER (game-specific from decompiled code)
    local ctrlResult = nil
    local ctrlDetail = "not found"
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
                        if (ok1 and inDuel) or (ok2 and inRange) then
                            matchScore = matchScore + 5; ctrlResult = false
                            ctrlDetail = "Duel=" .. tostring(inDuel) .. " Range=" .. tostring(inRange)
                        else
                            lobbyScore = lobbyScore + 5; ctrlResult = true
                            ctrlDetail = "fighter idle"
                        end
                    end
                end
            end
        end
    end)
    logCheck("FighterCtrl", ctrlResult, ctrlDetail)

    -- CHECK 10: COLLECTION SERVICE TAGS
    local tagResult = nil
    local tagDetail = "none matched"
    pcall(function()
        for _, tag in ipairs(CollectionService:GetTags()) do
            local tl = tag:lower()
            if tl:find("ingame") or tl:find("in_game") or tl:find("match") or tl:find("roundactive") then
                if #CollectionService:GetTagged(tag) > 0 then
                    matchScore = matchScore + 2; tagResult = false
                    tagDetail = tag; break
                end
            elseif tl:find("lobby") or tl:find("hub") or tl:find("waiting") then
                if #CollectionService:GetTagged(tag) > 0 then
                    lobbyScore = lobbyScore + 2; tagResult = true
                    tagDetail = tag; break
                end
            end
        end
    end)
    logCheck("CollectionTag", tagResult, tagDetail)

    -- FINAL VERDICT
    local total = lobbyScore + matchScore
    local conf = "0%"
    local verdict = nil
    if total > 0 then
        if lobbyScore > matchScore then
            verdict = true
            conf = math.floor((lobbyScore / total) * 100) .. "%"
        elseif matchScore > lobbyScore then
            verdict = false
            conf = math.floor((matchScore / total) * 100) .. "%"
        else
            verdict = nil
            conf = "50% (tie)"
        end
    end

    setStatus(verdict, conf)
    return verdict
end

isInLobby = runDetection()

local ticker = 0
RunService.Heartbeat:Connect(function(dt)
    ticker = ticker + dt
    if ticker >= 3 then
        ticker = 0
        local new = runDetection()
        if new ~= isInLobby then
            isInLobby = new
        end
    end
end)