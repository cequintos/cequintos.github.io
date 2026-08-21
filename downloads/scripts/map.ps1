#region === Variables ===

$DriveLetter = "g"
$NetworkPath = '\\henkelgroup.net\data\WEU'
$Domain = "henkelgroup.net"
$StartupDir = Join-Path -Path $env:APPDATA -ChildPath "Microsoft\Windows\Start Menu\Programs\Startup"
$LoginName = "$env:USERNAME"
$CmdFile = Join-Path -Path $StartupDir -ChildPath "map.cmd"
$TempDir = "$env:TEMP\map"

#endregion

#region === Functions ===

function CreateTempDir {
    param (
        [string]$TempDir
    )
    if (-not (Test-Path $TempDir)) {
        New-Item -Path $TempDir -ItemType Directory | Out-Null
    }
}

function GetUserPassword {
    param (
        [string]$PromptMessage
    )
    $securePassword = Read-Host -Prompt $PromptMessage -AsSecureString
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )
}

function StoreCredentials {
    param (
        [string]$Domain,
        [string]$Username,
        [string]$Password
    )
    cmdkey /add:$Domain /user:$Username /pass:$Password
}

function RemoveNetworkDrives {
    net use * /delete /yes | Out-Null
}

function MapNetworkDrive {
    param (
        [string]$DriveLetter,
        [string]$Path
    )
        net use "${DriveLetter}:" "$Path" /persistent:no | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Error mapping drive ${DriveLetter} to ${Path}: $_"
        }
}

function CreateStartupScript {
    param (
        [string]$FilePath,
        [string]$DriveLetter,
        [string]$NetworkPath
    )

    $scriptContent = @"
@echo off
net use * /delete /yes
net use ${DriveLetter}: $NetworkPath /persistent:no
"@

    Set-Content -Path $FilePath -Value $scriptContent -Encoding Ascii
}

#endregion

#region === Main ===

$PlainPassword = GetUserPassword -PromptMessage "Enter your Windows password for $Domain>`n"
StoreCredentials -Domain $Domain -Username $LoginName -Password $PlainPassword
RemoveNetworkDrives
MapNetworkDrive -DriveLetter $DriveLetter -Path $NetworkPath
CreateStartupScript -FilePath $CmdFile -DriveLetter $DriveLetter -NetworkPath $NetworkPath
Clear-Host

#endregion