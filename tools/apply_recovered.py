import os
import shutil

BASE = r"C:\Users\david\OneDrive\Documentos\GitHub\HUNTERRIDDLE"
RECOVERED = os.path.join(BASE, "tools", "recovered")

# Map recovered filename -> destination in old structure
# StartMenu.tscn is skipped on purpose (git HEAD version has no missing refs)
DEST_MAP = {
    "AudioManager.gd":      r"SCRIPS\Autoloads\AudioManager.gd",
    "Config.tscn":          r"Escenas\Config.tscn",
    "ConfirmExitDialog.gd": r"SCRIPS\Autoloads\ConfirmExitDialog.gd",
    "FoxLevels.gd":         r"SCRIPS\zorro\FoxLevels.gd",
    "GameState.gd":         r"SCRIPS\Autoloads\GameState.gd",
    "LevelCardLOCKED.tscn": r"Escenas\UI\UtilsScenes\LevelCards\LevelCardLOCKED.tscn",
    "LoginScreen.tscn":     r"Escenas\UI\Bocetos\LoginScreen.tscn",
    "NavItem.tscn":         r"Escenas\UI\UtilsScenes\NavItem.tscn",
    "ProgressManager.gd":   r"SCRIPS\Autoloads\ProgressManager.gd",
    "PuzzleScreen.gd":      r"SCRIPS\reutilizables en 3 puzzles\PuzzleScreen.gd",
    "PuzzleZorro.tscn":     r"Escenas\UI\ZORRO\PuzzleZorro.tscn",
    "RegisterScreen.tscn":  r"Escenas\UI\Bocetos\RegisterScreen.tscn",
    "UserProfile.gd":       r"SCRIPS\Autoloads\UserProfile.gd",
    "ZorroScreen.gd":       r"SCRIPS\zorro\ZorroScreen.gd",
    "ZorroScreen.tscn":     r"Escenas\UI\ZORRO\ZorroScreen.tscn",
    "board.gd":             r"SCRIPS\zorro\board.gd",
    "global_stars.gd":      r"SCRIPS\config\global_stars.gd",
    "login_screen.gd":      r"SCRIPS\login\login_screen.gd",
    "register_screen.gd":   r"SCRIPS\login\register_screen.gd",
    "start_menu.gd":        r"Escenas\start_menu.gd",
}

# Path substitutions to normalise any lingering new-structure paths -> old paths
PATH_SUBS = [
    ("res://scenes/ui/level_cards/", "res://Escenas/UI/UtilsScenes/LevelCards/"),
    ("res://scenes/puzzle/zorro/TenEnCuenta.tscn", "res://Escenas/UI/TenEnCuenta.tscn"),
    ("res://scenes/puzzle/zorro/", "res://Escenas/UI/ZORRO/"),
    ("res://scenes/config/Config.tscn", "res://Escenas/Config.tscn"),
    ("res://scenes/config/GameSettings.tscn", "res://Escenas/UI/GameSettings.tscn"),
    ("res://scenes/config/SoundSettings.tscn", "res://Escenas/UI/SoundSettings.tscn"),
    ("res://scenes/config/", "res://Escenas/"),
    ("res://scenes/ui/NavItem.tscn", "res://Escenas/UI/UtilsScenes/NavItem.tscn"),
    ("res://scenes/ui/StatPill.tscn", "res://Escenas/UI/UtilsScenes/StatPill.tscn"),
    ("res://scenes/ui/", "res://Escenas/UI/"),
    ("res://scenes/auth/", "res://Escenas/UI/Bocetos/"),
    ("res://scenes/menu/", "res://Escenas/"),
    ("res://scripts/puzzle/shared/PuzzleGlobal.gd", "res://Escenas/UI/PUZZLES/PuzzleGlobal.gd"),
    ("res://scripts/puzzle/shared/Puzzlemanager.gd", "res://Escenas/UI/PUZZLES/Puzzlemanager.gd"),
    ("res://scripts/puzzle/shared/OverlayPasado.gd", "res://Escenas/UI/UtilsScenes/OverlayPasado.gd"),
    ("res://scripts/puzzle/shared/", "res://SCRIPS/reutilizables en 3 puzzles/"),
    ("res://scripts/puzzle/zorro/", "res://SCRIPS/zorro/"),
    ("res://scripts/config/config.gd", "res://Escenas/config.gd"),
    ("res://scripts/config/game_settings.gd", "res://Escenas/UI/game_settings.gd"),
    ("res://scripts/config/sound_settings.gd", "res://Escenas/UI/sound_settings.gd"),
    ("res://scripts/config/", "res://SCRIPS/config/"),
    ("res://scripts/menu/start_menu.gd", "res://Escenas/start_menu.gd"),
    ("res://scripts/autoloads/", "res://SCRIPS/Autoloads/"),
    ("res://scripts/auth/login_screen.gd", "res://SCRIPS/login/login_screen.gd"),
    ("res://scripts/auth/register_screen.gd", "res://SCRIPS/login/register_screen.gd"),
    ("res://scripts/auth/", "res://SCRIPS/login/"),
    ("res://assets/images/Background.png", "res://Assets Gabri/Background.png"),
    ("res://assets/fonts/PlayfairDisplay/", "res://Assets Gabri/Fonts/PlayFair/"),
    ("res://assets/fonts/SpaceMono/", "res://Assets Gabri/Fonts/SpaceMono/"),
    ("res://assets/icons/icon.svg", "res://assets David/icon.svg"),
    ("res://assets/icons/HUNTERRIDDLE.jpg", "res://assets David/HUNTERRIDDLE.jpg"),
    ("res://assets/icons/", "res://assets David/"),
    ("res://assets/audio/", "res://assets David/audio/"),
    ("res://assets/shaders/rounded_corners.gdshader", "res://Escenas/UI/shaders/rounded_corners.gdshader"),
    ("res://assets/shaders/", "res://Escenas/UI/shaders/"),
]

def apply_subs(content):
    for old, new in PATH_SUBS:
        content = content.replace(old, new)
    return content

results = []
for fname, dest_rel in DEST_MAP.items():
    src = os.path.join(RECOVERED, fname)
    dst = os.path.join(BASE, dest_rel)
    if not os.path.exists(src):
        results.append("MISS  " + fname)
        continue
    with open(src, "r", encoding="utf-8") as f:
        content = f.read()
    content = apply_subs(content)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, "w", encoding="utf-8") as f:
        f.write(content)
    results.append("OK    " + fname + " -> " + dest_rel)

for r in results:
    print(r)
