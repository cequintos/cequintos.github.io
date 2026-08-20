# --------------------------------------------------------------
# Script made by Carlos Quintos - Unisys
# Last update date: 2025-08-26
# Description: Software installer for Ivanti equipment at Henkel
# --------------------------------------------------------------

#region === Variables ===
$temp_folder = "$env:TEMP\installers"
if (-not (Test-Path $temp_folder)) {
    New-Item -Path $temp_folder -ItemType Directory | Out-Null
}

$programs = @(
    @{
        name         = "OktaVerifySetup.exe"
        options      = "/silent"
        installed_in = @("C:\Program Files\Okta\Okta Verify\OktaVerify.exe")
        url          = "https://github.com/stool3252/resources/releases/download/Latest/OktaVerifySetup.exe"
    },
    @{
        name         = "system_update_5.08.03.59.exe"
        options      = "/silent"
        installed_in = @("C:\Program Files (x86)\Lenovo\System Update\Tvsukernel.exe")
        url          = "https://download.lenovo.com/pccbbs/thinkvantage_en/system_update_5.08.03.59.exe"
    },
    @{
        name         = "Adobe.exe"
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
#endregion

#region === Functions ===
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
    catch {
        return $false
    }
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

    Write-Host "The following NEW packages will be installed:"
    foreach ($prog in $to_install) {
        Write-Host " $($prog.name)"
    }

    $counter = 1
    $total_size_kb = 0
    foreach ($prog in $to_install) {
        $local_path = Join-Path $temp_folder $prog.name
        $size_kb = "unknown"

        try {
            $response = Invoke-WebRequest -Uri $prog.url -Method Head -ErrorAction Stop
            if ($response.Headers["Content-Length"]) {
                $size_kb = [math]::Round($response.Headers["Content-Length"] / 1KB, 1)
                $total_size_kb += $size_kb
            }
        }
        catch {}

        Write-Host "Get:$counter $($prog.url) [$size_kb kB]..."

        if (-not (Test-Path $local_path)) {
            if (-not (download_installer -url $prog.url -output_path $local_path)) {
                Write-Host "Failed to download $($prog.name)"
                continue
            }
        }
        $counter++
    }
    
    if ($total_size_kb -gt 0) {
        $size_mb = [math]::Round($total_size_kb / 1024, 1)
        Write-Host "After this operartion, approximately $size_mb MB of additional disk space will be used."
    }

    foreach ($prog in $to_install) {
        $local_path = Join-Path $temp_folder $prog.name
        Write-Host -NoNewline "Installing $($prog.name)... "
        run_program -path $local_path -options $prog.options
        if (its_installed $prog.installed_in) {
            Write-Host "Done"
        }
        else {
            Write-Host "Failed"
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
        try { Remove-Item -Path $temp_folder -Recurse -Force; Write-Output "Done" }
        catch { Write-Output "Failed" }
    }
    else {
        Write-Output "Skipped"
    }
}
#endregion

#region === Main ===
Clear-Host
fix_lang
henkel_dependecies
ivanti_launch
clean_temp
#endregion