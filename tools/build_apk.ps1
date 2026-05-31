# Build APK debug de HunterRiddle con la orientación correcta.
#
# Workaround del bug de Godot 4.6.1: --export-debug regenera
# android/build/src/debug/AndroidManifest.xml con screenOrientation="landscape"
# aunque project.godot tenga "sensor". Para arreglarlo:
#   1) Lanzamos el export de Godot (produce una APK con landscape).
#   2) Parcheamos el debug manifest a fullUser.
#   3) Volvemos a invocar gradle, que reconstruye la APK con el manifest corregido.
#   4) zipalign + apksigner con la debug.keystore de Godot.
#
# Requisitos (ya configurados en este equipo):
#   - Godot 4.6.1 en C:\Users\david\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe
#   - Android SDK build-tools en %LOCALAPPDATA%\Android\Sdk\build-tools
#   - JDK de Android Studio en C:\Program Files\Android\Android Studio\jbr
#   - debug.keystore en %APPDATA%\Godot\keystores\debug.keystore (pass: android)

# No usamos ErrorActionPreference=Stop globalmente porque Godot escribe avisos
# a stderr (UID duplicates de las fuentes) y PowerShell los trataría como
# excepciones terminales. Revisamos $LASTEXITCODE manualmente tras cada paso.
$ErrorActionPreference = 'Continue'

$project       = Split-Path -Parent $PSScriptRoot
$godot         = "C:\Users\david\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe"
$apk           = Join-Path $project "HunterRiddle.apk"
$debugManifest = Join-Path $project "android\build\src\debug\AndroidManifest.xml"
$gradlew       = Join-Path $project "android\build\gradlew.bat"
$gradleApkDir  = Join-Path $project "android\build\build\outputs\apk\standard\debug"
$keystore      = Join-Path $env:APPDATA "Godot\keystores\debug.keystore"
$buildTools    = Join-Path $env:LOCALAPPDATA "Android\Sdk\build-tools"

$env:JAVA_HOME       = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME    = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

$apksigner = (Get-ChildItem $buildTools -Filter "apksigner.bat" -Recurse | Sort-Object FullName -Descending | Select-Object -First 1).FullName
$zipalign  = (Get-ChildItem $buildTools -Filter "zipalign.exe"  -Recurse | Sort-Object FullName -Descending | Select-Object -First 1).FullName
$aapt      = (Get-ChildItem $buildTools -Filter "aapt.exe"      -Recurse | Sort-Object FullName -Descending | Select-Object -First 1).FullName

Write-Host "[1/5] Limpiando build dir..."
$buildDir = Join-Path $project "android\build\build"
if (Test-Path $buildDir) {
    Remove-Item -LiteralPath $buildDir -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path $apk) { Remove-Item $apk -Force }

Write-Host "[2/5] Godot --export-debug..."
& $godot --headless --path $project --export-debug "Android" $apk 2>&1 |
    Select-String -Pattern "ERROR|FAILED|DONE|export" | Select-Object -Last 6
if ($LASTEXITCODE -ne 0) { throw "Godot export failed" }

Write-Host "[3/5] Parcheo screenOrientation a fullUser en debug manifest..."
$content = Get-Content $debugManifest -Raw
$patched = $content -replace 'android:screenOrientation="landscape"', 'android:screenOrientation="fullUser"'
[System.IO.File]::WriteAllText($debugManifest, $patched)

Write-Host "[4/5] Re-ejecuto gradle :assembleStandardDebug..."
& $gradlew --project-dir (Join-Path $project "android\build") :assembleStandardDebug --console=plain 2>&1 |
    Select-String -Pattern "BUILD|FAILED|ERROR" | Select-Object -Last 3
if ($LASTEXITCODE -ne 0) { throw "Gradle build failed" }

$gradleApk = (Get-ChildItem $gradleApkDir -Filter "*.apk" | Select-Object -First 1).FullName

Write-Host "[5/5] Zipalign + sign con debug.keystore..."
$aligned = Join-Path $project "HunterRiddle_aligned.apk"
& $zipalign -f -p 4 $gradleApk $aligned | Out-Null
& $apksigner sign --ks $keystore --ks-pass pass:android --key-pass pass:android `
    --ks-key-alias androiddebugkey --out $apk $aligned 2>&1 | Out-Null
Remove-Item $aligned -Force

# Verificación final
$f = Get-Item $apk
$ori = (& $aapt dump xmltree $apk AndroidManifest.xml | Select-String "screenOrientation").Line.Trim()
$sig = (& $apksigner verify --verbose $apk 2>&1 | Select-Object -First 1)
Write-Host ""
Write-Host "===================================================="
Write-Host "APK:        $apk"
Write-Host "Size:       $([math]::Round($f.Length/1MB,1)) MB"
Write-Host "Firma:      $sig"
Write-Host "Orientation: $ori"
Write-Host "  (0xd = fullUser → rota si autorotate ON, vertical si OFF)"
Write-Host "===================================================="
