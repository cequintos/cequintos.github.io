# ================================================
#   Tool: PC Lifecycle 2026 - Software & Users Collector
#   Author: Carlos Quintos Nores (Unisys)
#   Date: Mon Jul 13 2026
# ================================================

$host.ui.RawUI.WindowTitle = 'dx Spain - PC Lifecycle 2026'

# Obtención de variables principales
$hostname = [System.Net.Dns]::GetHostName()
$username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$downloadsPath = Join-Path ([Environment]::GetFolderPath('UserProfile')) "Downloads"

# Estructura de carpetas y archivos
$folderName = "${hostname}-${username}"
$tempFolderPath = Join-Path $downloadsPath $folderName
$zipFileName = "${folderName}.zip"
$zipOutputPath = Join-Path $downloadsPath $zipFileName

# Crear la carpeta contenedora temporal si no existe
if (-not (Test-Path -Path $tempFolderPath)) {
    New-Item -Path $tempFolderPath -ItemType Directory | Out-Null
}

# Rutas completas de los CSV dentro de la carpeta temporal
$outputPathSoftware = Join-Path $tempFolderPath "${hostname}-${username}-Software.csv"
$outputPathUsers = Join-Path $tempFolderPath "${hostname}-${username}-Users.csv"

# Número de Serie
$serial = (Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
if ([string]::IsNullOrWhiteSpace($serial)) { 
    $serial = 'N/A' 
}

# ================================================
# 1. RECOLECCIÓN Y EXPORTACIÓN DE SOFTWARE
# ================================================
$regPaths = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$apps = Get-ItemProperty $regPaths -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -ne $null } |
Select-Object @{n = 'hostname'; e = { $hostname } },
@{n = 'user'; e = { $username } },
@{n = 'serial'; e = { $serial } },
@{n = 'software'; e = { $_.DisplayName.Trim() } },
@{n = 'version'; e = { $_.DisplayVersion } },
Publisher,
InstallDate |
Sort-Object Software -Unique

$apps | Export-Csv -Path $outputPathSoftware -NoTypeInformation -Encoding utf8 -Delimiter ','

# ================================================
# 2. RECOLECCIÓN Y EXPORTACIÓN DE USUARIOS
# ================================================
$userFolders = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | 
Select-Object @{n = 'hostname'; e = { $hostname } },
@{n = 'userHost'; e = { $username } },
@{n = 'serial'; e = { $serial } },
@{n = 'usersList'; e = { $_.Name } }

$userFolders | Export-Csv -Path $outputPathUsers -NoTypeInformation -Encoding utf8 -Delimiter ','

# ================================================
# 3. COMPRESIÓN A .ZIP Y LIMPIEZA
# ================================================
# Si ya existía un ZIP anterior con el mismo nombre, se elimina para no dar error
if (Test-Path -Path $zipOutputPath) {
    Remove-Item -Path $zipOutputPath -Force
}

# Comprimir la carpeta completa
Compress-Archive -Path $tempFolderPath -DestinationPath $zipOutputPath -Force

# Eliminar la carpeta temporal descomprimida
Remove-Item -Path $tempFolderPath -Recurse -Force

# ================================================
# MENSAJES EN CONSOLA
# ================================================
Write-Host '----------------------------------------------------' -ForegroundColor White
Write-Host 'El proceso se ha completado correctamente' -ForegroundColor Green
Write-Host "Archivo ZIP generado: $zipFileName" -ForegroundColor Yellow
Write-Host "Localizado en: $downloadsPath" -ForegroundColor Cyan
Write-Host '----------------------------------------------------' -ForegroundColor White
Write-Host 'Por favor, adjunta el archivo .ZIP generado al correo.' -ForegroundColor Gray
Start-Sleep -Seconds 5