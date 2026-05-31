import os

BASE = r"C:\Users\david\OneDrive\Documentos\GitHub\HUNTERRIDDLE"

FILE_MAP = {
    "scenes/menu/StartMenu.tscn": "Escenas/StartMenu.tscn",
    "scenes/auth/LoginScreen.tscn": "Escenas/UI/Bocetos/LoginScreen.tscn",
    "scenes/auth/RegisterScreen.tscn": "Escenas/UI/Bocetos/RegisterScreen.tscn",
    "scenes/config/Config.tscn": "Escenas/Config.tscn",
    "scenes/config/GameSettings.tscn": "Escenas/UI/GameSettings.tscn",
    "scenes/config/SoundSettings.tscn": "Escenas/UI/SoundSettings.tscn",
    "scenes/puzzle/zorro/Board.tscn": "Escenas/UI/ZORRO/Board.tscn",
    "scenes/puzzle/zorro/Cell.tscn": "Escenas/UI/ZORRO/Cell.tscn",
    "scenes/puzzle/zorro/PuzzleZorro.tscn": "Escenas/UI/ZORRO/PuzzleZorro.tscn",
    "scenes/puzzle/zorro/TenEnCuenta.tscn": "Escenas/UI/TenEnCuenta.tscn",
    "scenes/puzzle/zorro/ZorroScreen.tscn": "Escenas/UI/ZORRO/ZorroScreen.tscn",
    "scenes/ui/GlobalStars.tscn": "Escenas/UI/GlobalStars.tscn",
    "scenes/ui/NavItem.tscn": "Escenas/UI/UtilsScenes/NavItem.tscn",
    "scenes/ui/StatPill.tscn": "Escenas/UI/UtilsScenes/StatPill.tscn",
    "scenes/ui/UserForm.tscn": "Escenas/UI/UserForm.tscn",
    "scenes/ui/UsersAdmin.tscn": "Escenas/UI/UsersAdmin.tscn",
    "scenes/ui/UsersProgress.tscn": "Escenas/UI/UsersProgress.tscn",
    "scenes/ui/level_cards/LevelCardCOMPLETED.tscn": "Escenas/UI/UtilsScenes/LevelCards/LevelCardCOMPLETED.tscn",
    "scenes/ui/level_cards/LevelCardLOCKED.tscn": "Escenas/UI/UtilsScenes/LevelCards/LevelCardLOCKED.tscn",
    "scenes/ui/level_cards/LevelCardUNLOCKED.tscn": "Escenas/UI/UtilsScenes/LevelCards/LevelCardUNLOCKED.tscn",
    "scripts/auth/login_screen.gd": "SCRIPS/login/login_screen.gd",
    "scripts/auth/register_screen.gd": "SCRIPS/login/register_screen.gd",
    "scripts/autoloads/AudioManager.gd": "SCRIPS/Autoloads/AudioManager.gd",
    "scripts/autoloads/ConfirmExitDialog.gd": "SCRIPS/Autoloads/ConfirmExitDialog.gd",
    "scripts/autoloads/GameState.gd": "SCRIPS/Autoloads/GameState.gd",
    "scripts/autoloads/ProgressManager.gd": "SCRIPS/Autoloads/ProgressManager.gd",
    "scripts/autoloads/SupabaseClient.gd": "SCRIPS/Autoloads/SupabaseClient.gd",
    "scripts/autoloads/UserProfile.gd": "SCRIPS/Autoloads/UserProfile.gd",
    "scripts/config/config.gd": "Escenas/config.gd",
    "scripts/config/game_settings.gd": "Escenas/UI/game_settings.gd",
    "scripts/config/global_stars.gd": "SCRIPS/config/global_stars.gd",
    "scripts/config/sound_settings.gd": "Escenas/UI/sound_settings.gd",
    "scripts/config/user_form.gd": "SCRIPS/config/user_form.gd",
    "scripts/config/users_admin.gd": "SCRIPS/config/users_admin.gd",
    "scripts/config/users_progress.gd": "SCRIPS/config/users_progress.gd",
    "scripts/menu/start_menu.gd": "Escenas/start_menu.gd",
    "scripts/puzzle/shared/LevelCard.gd": "SCRIPS/reutilizables en 3 puzzles/LevelCard.gd",
    "scripts/puzzle/shared/OverlayPasado.gd": "Escenas/UI/UtilsScenes/OverlayPasado.gd",
    "scripts/puzzle/shared/ProgressBand.gd": "SCRIPS/reutilizables en 3 puzzles/ProgressBand.gd",
    "scripts/puzzle/shared/PuzzleGlobal.gd": "Escenas/UI/PUZZLES/PuzzleGlobal.gd",
    "scripts/puzzle/shared/PuzzleScreen.gd": "SCRIPS/reutilizables en 3 puzzles/PuzzleScreen.gd",
    "scripts/puzzle/shared/Puzzlemanager.gd": "Escenas/UI/PUZZLES/Puzzlemanager.gd",
    "scripts/puzzle/shared/StatPill.gd": "SCRIPS/reutilizables en 3 puzzles/StatPill.gd",
    "scripts/puzzle/shared/active_dot.gd": "SCRIPS/reutilizables en 3 puzzles/active_dot.gd",
    "scripts/puzzle/shared/nav_item.gd": "SCRIPS/reutilizables en 3 puzzles/nav_item.gd",
    "scripts/puzzle/zorro/FoxLevels.gd": "SCRIPS/zorro/FoxLevels.gd",
    "scripts/puzzle/zorro/ZorroScreen.gd": "SCRIPS/zorro/ZorroScreen.gd",
    "scripts/puzzle/zorro/board.gd": "SCRIPS/zorro/board.gd",
    "scripts/puzzle/zorro/cell.gd": "SCRIPS/zorro/cell.gd",
    "scripts/puzzle/zorro/ten_en_cuenta.gd": "SCRIPS/zorro/ten_en_cuenta.gd",
}

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

copied = []
skipped = []

for new_rel, old_rel in FILE_MAP.items():
    src = os.path.join(BASE, new_rel.replace("/", os.sep))
    dst = os.path.join(BASE, old_rel.replace("/", os.sep))

    if not os.path.exists(src):
        skipped.append("SKIP (src missing): " + new_rel)
        continue

    try:
        with open(src, "r", encoding="utf-8") as f:
            content = f.read()
        content = apply_subs(content)
    except UnicodeDecodeError:
        skipped.append("SKIP (binary): " + new_rel)
        continue

    os.makedirs(os.path.dirname(dst), exist_ok=True)

    with open(dst, "w", encoding="utf-8") as f:
        f.write(content)

    copied.append("  " + new_rel + " -> " + old_rel)

print("Copied " + str(len(copied)) + " files:")
for c in copied:
    print(c)
if skipped:
    print("\nSkipped " + str(len(skipped)) + ":")
    for s in skipped:
        print(s)
