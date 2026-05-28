import os
import re
import glob

ESP_DIR = r"c:\Users\jesse\Downloads\ESP\UILibs-main\ESP"

files_to_patch = []
for f in ["Arrows", "Chams", "Health", "Name", "Radar", "Skeleton", "Tracers", "ViewTracer"]:
    files_to_patch.append(os.path.join(ESP_DIR, f, "Example"))

# Aimbot is slightly different but we can patch it too
files_to_patch.append(os.path.join(ESP_DIR, "Aimbot", "Example"))

for filepath in files_to_patch:
    if not os.path.exists(filepath): continue
    with open(filepath, "r") as f:
        content = f.read()
    
    # 1. Add TargetManager import
    if "TargetManager" not in content:
        content = content.replace(
            'local LobbyDetector = loadstring(game:HttpGet("https://raw.githubusercontent.com/checkurasshole/ESP/main/LobbyDetector.lua"))()',
            'local LobbyDetector = loadstring(game:HttpGet("https://raw.githubusercontent.com/checkurasshole/ESP/main/LobbyDetector.lua"))()\nlocal TargetManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/checkurasshole/ESP/main/TargetManager.lua"))()'
        )
        if "TargetManager" not in content: # Fallback if LobbyDetector is missing
            content = content.replace(
                'local RS = game:GetService("RunService")',
                'local RS = game:GetService("RunService")\nlocal TargetManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/checkurasshole/ESP/main/TargetManager.lua"))()'
            )

    # 2. Patch the main loop
    # Old: for _, v in ipairs(Players:GetPlayers()) do \n if v ~= Player then
    # Old: for _, v in pairs(Players:GetPlayers()) do \n if v ~= Player then
    # Old: for _, plr in ipairs(Players:GetPlayers()) do
    
    content = re.sub(
        r'for \_, ([a-zA-Z0-9_]+) in (i?pairs)\(Players:GetPlayers\(\)\) do\s*(?:if \1 ~= (?:Player|LocalPlayer) then)?\s*local char = \1\.Character',
        r'for _, target in ipairs(TargetManager.GetTargets()) do\n                        local \1 = target.Player or target.Character -- Use character as fallback key for NPCs\n                        local char = target.Character',
        content
    )
    
    # For scripts that don't declare local char = v.Character right away
    content = re.sub(
        r'for \_, ([a-zA-Z0-9_]+) in (i?pairs)\(Players:GetPlayers\(\)\) do\s*if \1 ~= (?:Player|LocalPlayer) then\s*(?!(local char|ApplyESP))',
        r'for _, target in ipairs(TargetManager.GetTargets()) do\n                        local \1 = target.Player or target.Character\n                        local char = target.Character\n                        ',
        content
    )

    # Handle ApplyESP loops (Health, ViewTracer)
    content = re.sub(
        r'for \_, ([a-zA-Z0-9_]+) in (i?pairs)\(Players:GetPlayers\(\)\) do\s*if \1 ~= (?:Player|LocalPlayer) then\s*ApplyESP\(\1\)\s*end\s*end',
        r'for _, target in ipairs(TargetManager.GetTargets()) do\n            local \1 = target.Player or target.Character\n            ApplyESP(\1, target.Character)\n        end',
        content
    )

    # We need to write back the file
    with open(filepath, "w") as f:
        f.write(content)

print("Patched loops.")
