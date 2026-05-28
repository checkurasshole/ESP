import os

def patch_file(filepath, module_group):
    if not os.path.exists(filepath): return
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace old TargetManager/LobbyDetector imports with getgenv()
    old_tm = 'local TargetManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/checkurasshole/ESP/main/TargetManager.lua"))()'
    new_tm = 'local TargetManager = getgenv().ESP_TargetManager or loadstring(game:HttpGet("https://raw.githubusercontent.com/checkurasshole/ESP/main/TargetManager.lua"))()'
    
    old_ld = 'local LobbyDetector = loadstring(game:HttpGet("https://raw.githubusercontent.com/checkurasshole/ESP/main/LobbyDetector.lua"))()'
    new_ld = 'local LobbyDetector = getgenv().ESP_LobbyDetector or loadstring(game:HttpGet("https://raw.githubusercontent.com/checkurasshole/ESP/main/LobbyDetector.lua"))()'

    content = content.replace(old_tm, new_tm)
    content = content.replace(old_ld, new_ld)

    # Replace GetTargets() with GetTargets("ESP") etc
    old_get = 'TargetManager.GetTargets()'
    new_get = f'TargetManager.GetTargets("{module_group}")'
    content = content.replace(old_get, new_get)

    with open(filepath, 'w') as f:
        f.write(content)


esp_modules = ["Chams", "Name", "Skeleton", "Tracers", "ViewTracer", "Health"]
for m in esp_modules:
    patch_file(f"c:/Users/jesse/Downloads/ESP/UILibs-main/ESP/{m}/Example", "ESP")

patch_file("c:/Users/jesse/Downloads/ESP/UILibs-main/ESP/Aimbot/Example", "Aimbot")
patch_file("c:/Users/jesse/Downloads/ESP/UILibs-main/ESP/Hitbox/Example", "Hitbox")

print("Done patching.")
