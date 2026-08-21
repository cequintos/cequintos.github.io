# --------------------------------------------------------------
# Script made by Carlos Quintos - Unisys
# Last update date: 2026-08-21
# Description: Software installer for Ivanti equipment at Henkel
# --------------------------------------------------------------

#region ========= VARIABLES =========

$temp_folder = "$env:TEMP\installers"

$programs = @(
    @{
        name         = "OktaVerifySetup.exe"
        winget_id    = "Okta.OktaVerify"
        options      = "/silent"
        installed_in = @("C:\Program Files\Okta\Okta Verify\OktaVerify.exe")
        url          = "https://okta.okta.com/artifacts/WINDOWS_OKTA_VERIFY/6.10.2.0/OktaVerifySetup-6.10.2.0-de20e9b.exe"
    },
    @{
        name         = "system_update_5.08.04.85.exe"
        winget_id    = "Lenovo.SystemUpdate"
        options      = "/silent"
        installed_in = @("C:\Program Files (x86)\Lenovo\System Update\Tvsukernel.exe")
        url          = "https://download.lenovo.com/pccbbs/thinkvantage_en/system_update_5.08.04.85.exe"
    },
    @{
        name         = "Adobe.exe"
        winget_id    = "XPDP273C0XHQH2"
        options      = "/sAll"
        installed_in = @(
            "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
            "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
            "C:\Program Files\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
        )
        url          = "https://github.com/stool3252/resources/releases/download/Latest/Adobe.exe"
    }
)

$ivanti_tools = @(
    @{
        name    = "Inventory Scanner"
        path    = "C:\Program Files (x86)\Ivanti\EPM Agent\Inventory\ldiscn32.exe"
        param   = "/V"
        process = "ldiscn32"
    },
    @{
        name    = "Security Scanner"
        path    = "C:\Program Files (x86)\Ivanti\EPM Agent\Patch Management\vulscan.exe"
        param   = "/showui=true"
        process = "vulscan"
    }
)

$landesk = @{
    zip_name  = "landesk.zip"
    url       = "https://github.com/stool3252/resources/releases/download/Latest/landesk.zip"
    zip_path  = Join-Path $temp_folder "landesk.zip"
    extract   = Join-Path $temp_folder "landesk"
    installer = "landesk\EPMAgentInstaller.exe"
    options   = "/c DEDUSSV-IVAN3"
}

#endregion

#region ========= FUNCTIONS =========

function its_installed ($paths) {
    foreach ($path in $paths) {
        if (Test-Path $path) { return $true }
    }
    return $false
}

function its_running($processName) {
    try {
        $proc = Get-Process -Name $processName -ErrorAction SilentlyContinue
        return $null -ne $proc
    }
    catch {
        return $false
    }
}

function run_program($path, $options) {
    try {
        Start-Process -FilePath $path -ArgumentList $options -Wait
    }
    catch {}
}

function run_tool($tool) {
    if (-not (Test-Path $tool.path)) { return }
    if (its_running $tool.process) { return }
    try {
        Start-Process -FilePath $tool.path -ArgumentList $tool.param
    }
    catch {}
}

function fix_lang {
    $lang_file = "C:\ProgramData\Lang\Lang_AS.ps1"
    Write-Host -NoNewline "Fixing persistent language problem... "
    if (Test-Path $lang_file) {
        try {
            Remove-Item $lang_file -Force
            Write-Output "Done"
        }
        catch {
            Write-Output "Failed"
        }
    }
    else {
        Write-Output "Skipped"
    }
}

function download_installer($url, $output_path) {
    try {
        & curl.exe -L -s -o $output_path $url
        return (Test-Path $output_path)
    }
    catch {
        return $false
    }
}

function henkel_dependecies {

    $winget_available = has_winget

    if ($winget_available) {
        Write-Host "Winget detected. Updating sources..."
        update_winget_sources
        Write-Host "Using Winget installation method."
    }
    else {
        Write-Host "Winget not found. Using local installers."
    }

    $to_install = @()

    foreach ($prog in $programs) {
        if (-not (its_installed $prog.installed_in)) {
            $to_install += $prog
        }
    }

    if ($to_install.Count -eq 0) {
        Write-Host "All packages are already installed"
        return
    }

    foreach ($prog in $to_install) {

        Write-Host -NoNewline "Installing $($prog.name)... "
        $installed = $false

        if ($winget_available) {

            $success = install_winget_package $prog.winget_id
            
            if ($success) {
                Start-Sleep -Seconds 5
                if (its_installed $prog.installed_in) {
                    Write-Host "Done (Winget)"
                    $installed = $true
                }
            }

            if (-not $installed) {
                Write-Host "Winget failed, using local installer..."
                $installed = install_local_package $prog

                if ($installed) {
                    Write-Host "Done (Local)"
                }
                else {
                    Write-Host "Failed"
                }
            }
        }
        else {
            $installed = install_local_package $prog

            if ($installed) {
                Write-Host "Done"
            }
            else {
                Write-Host "Failed"
            }
        }
    }
}

    function ivanti_launch {
        foreach ($tool in $ivanti_tools) {
            Write-Host -NoNewline "Launching $($tool.name)... "
            if (its_running $tool.process) {
                Write-Output "Skipped"
            }
            elseif (Test-Path $tool.path) {
                run_tool $tool
                Write-Output "Done"
            }
            else {
                Write-Output "Not found"
            }
        }
    }

    function clean_temp {
        Write-Host -NoNewline "Cleaning temporary folder... "
        if (Test-Path $temp_folder) {
            try {
                Remove-Item -Path $temp_folder -Recurse -Force
                Write-Output "Done"
            }
            catch {
                Write-Output "Failed"
            }
        }
        else {
            Write-Output "Skipped"
        }
    }

    function install_landesk {
        create_temp_folder
        Write-Host "`nInstalling Ivanti (Landesk)..."
        Write-Host -NoNewline "Downloading package..."
        if (-not (download_installer -url $landesk.url -output_path $landesk.zip_path)) {
            Write-Output "Failed"
            return
        }
        Write-Output "Done"

        # Extraer
        Write-Host -NoNewline "Extracting package..."
        try {
            Expand-Archive `
            -Path $landesk.zip_path `
            -DestinationPath $landesk.extract `
            -Force

            Write-Output "Done"
        }
        catch {
            Write-Output "Failed"
            return
        }
        $installer = Join-Path $landesk.extract "EPMAgentInstaller.exe"
        if (Test-Path $installer) {
            Write-Host -NoNewline "Installing Ivanti Agent..."
            try {
                Start-Process `
                -FilePath $installer `
                -ArgumentList $landesk.options `
                -Wait

                Write-Host "Done"
            }
            catch {
                Write-Host "Failed"
            }
        }
    }

    function has_winget {
        return $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
    }

    function install_winget_package($packageId) {
        try {
            $process = Start-Process `
                -FilePath "winget.exe" `
                -ArgumentList @(
                "install",
                "`"$packageId`"",
                "--silent",
                "--accept-package-agreements",
                "--accept-source-agreements",
                "--disable-interactivity",
                "--nowarn",
                "--exact"
            ) `
                -Wait `
                -PassThru `
                -NoNewWindow

            return ($process.ExitCode -eq 0)
        }
        catch {
            return $false
        }
    }

    function update_winget_sources {
        try {
            winget source update | Out-Null
        }
        catch {}
    }

    function install_local_package($prog) {
        create_temp_folder
        $local_path = Join-Path $temp_folder $prog.name
        if (-not (Test-Path $local_path)) {
            if (-not (download_installer -url $prog.url -output_path $local_path)) {
                return $false
            }
        }
    
        run_program -path $local_path -options $prog.options
        return (its_installed $prog.installed_in)
    }

    #endregion

    #region ========= MAIN =========

    Clear-Host
    fix_lang
    henkel_dependecies
    ivanti_launch
    if (Test-Path $temp_folder) {
        clean_temp
    }

    #endregion