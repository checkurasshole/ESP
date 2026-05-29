local cloneref = cloneref or function(...) return ... end
local LocalPlayer = cloneref(game:GetService("Players").LocalPlayer)

return function(Player)
    if not Player then return false end
    if Player == LocalPlayer then return true end
    
    if Player.Team == LocalPlayer.Team and Player.Team ~= nil then
        return true
    end
    
    if Player:GetAttribute("Team") == LocalPlayer:GetAttribute("Team") and Player:GetAttribute("Team") ~= nil then
        return true
    end

    local Char = Player.Character
    if Char then
        local HRP = Char:FindFirstChild("HumanoidRootPart")
        if HRP and (HRP:FindFirstChild("teamatelabel") or HRP:FindFirstChild("TeammateLabel") or HRP:FindFirstChild("Marker")) then
            return true
        end
        
        local Head = Char:FindFirstChild("Head")
        if Head and (Head:FindFirstChild("TeammateLabel") or Head:FindFirstChild("FriendMarker")) then
            return true
        end

        for _, child in pairs(Char:GetDescendants()) do
            if child:IsA("BillboardGui") and (child.Name:lower():find("team") or child.Name:lower():find("friend")) then
                return true
            end
        end
    end
    
    return false
end
