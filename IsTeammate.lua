local cloneref = cloneref or function(...) return ... end
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = cloneref(Players.LocalPlayer)

--[[
    IsTeammate(Player)
    
    Returns true if the given Player is on the same team as the LocalPlayer.
    
    Priority order:
    1. Standard Roblox Teams (.Team property) -- works in 99% of games
    2. Rivals-style attribute ("Team" attribute on player) -- fallback for custom team systems
    3. Character BillboardGui/label scan -- last resort for games like Rivals that 
       don't use the Teams service at all
    
    NOTE: The BillboardGui scan is ONLY run as a last resort when NEITHER 
    standard .Team NOR attribute teams exist. This prevents false positives 
    in games that happen to have GUIs named "team" on characters.
]]
return function(Player)
    if not Player then return false end
    if Player == LocalPlayer then return true end

    -- 1. Standard Roblox Teams service (works for most games)
    local myTeam = LocalPlayer.Team
    local theirTeam = Player.Team
    if myTeam ~= nil or theirTeam ~= nil then
        -- Teams service is in use, trust it fully
        return myTeam == theirTeam
    end

    -- 2. Attribute-based team (some custom games, e.g. Rivals)
    local myAttr = LocalPlayer:GetAttribute("Team")
    local theirAttr = Player:GetAttribute("Team")
    if myAttr ~= nil and theirAttr ~= nil then
        return myAttr == theirAttr
    end

    -- 3. Character label scan (Rivals-specific last resort)
    -- Only runs when the game uses no Teams service and no attributes
    local Char = Player.Character
    if Char then
        local LocalChar = LocalPlayer.Character
        local myHRP = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")
        local theirHRP = Char:FindFirstChild("HumanoidRootPart")
        
        -- Check for Rivals team marker
        if theirHRP then
            local marker = theirHRP:FindFirstChild("teamatelabel") 
                or theirHRP:FindFirstChild("TeammateLabel") 
                or theirHRP:FindFirstChild("Marker")
            if marker and myHRP then
                local myMarker = myHRP:FindFirstChild("teamatelabel")
                    or myHRP:FindFirstChild("TeammateLabel")
                    or myHRP:FindFirstChild("Marker")
                -- Both have markers = we can compare them
                if myMarker then
                    return myMarker.Name == marker.Name
                end
                -- They have a marker, we do too = probably same team type
                return true
            end
        end
    end

    -- If we get here and nothing matched, treat as enemy by default
    return false
end
