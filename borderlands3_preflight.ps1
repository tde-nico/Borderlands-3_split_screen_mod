$NC_SCRIPT_PATH = ".\Borderlands3.js"
$NC_SCRIPT_REPLACE_STRING = "PREFLIGHT_SCRIPT_WILL_REPLACE"
$EPIC_LOG_PATH = "$env:USERPROFILE\AppData\Local\EpicGamesLauncher\Saved\Logs\EpicGamesLauncher.log"

try {
    Write-Host Checking if NC Script file needs launch args
    $containsString = Select-String -Path $NC_SCRIPT_PATH -Pattern $NC_SCRIPT_REPLACE_STRING
    If ($null -eq $containsString) {
        Write-Host "Launch args already added! Skipping..."
        exit
    }
}
catch {
    Write-Error "Unable to open nucleus script file. Quitting..." -ErrorAction Stop
    
}

try {    
    Write-Host Checking if epic logs already contain launch args
    $Launch_Info = Get-Content $env:USERPROFILE\AppData\Local\EpicGamesLauncher\Saved\Logs\EpicGamesLauncher.log | `
        Where-Object { $_ -like '*FCommunityPortalLaunchAppTask: Launching app*Borderlands3.exe*' } | `
        Select-Object -First 1
}
catch {
    # Cant find args yet
}

if ($null -eq $Launch_Info) {

    # Start an instance of Borderlands 3 using the Epic Launcher
    try {
        Write-Host Args not found yet. Starting Borderlands 3 using Epic Launcher
        Start-Process -FilePath "com.epicgames.launcher://apps/Catnip?action=launch&silent=true"
    }
    catch {
        Write-Error "Unable to launch Borderlands 3 using Epic Launcher. Quitting..." -ErrorAction Stop
    }

    # Get args needed to launch BL3 offline
    try {
        # Search through Epic Launcher logs to find the launch parameters for Borderlands 3.
        Write-Host Finding offline launch arguments
        while (($null -eq $Launch_Info ) -or ($null -eq $bl3_process)) {
            Start-Sleep -s 1
            $bl3_process = Get-Process -name Borderlands3 -ErrorAction SilentlyContinue
            $Launch_Info = Get-Content $EPIC_LOG_PATH | `
                Where-Object { $_ -like '*FCommunityPortalLaunchAppTask: Launching app*Borderlands3.exe*' } | `
                Select-Object -First 1
        }

        Start-Sleep -s 15
        Write-Host Killing Borderlands3
        Stop-Process $bl3_process.Id
    }
    catch {
        Write-Error "Unable to get offline args for Borderlands 3. Quitting..." -ErrorAction Stop
    }
    
}




try {
    Write-Host Parsing launch args
    
    # Reformat it, split out the binary/args
    $null, $bl3_bin = $Launch_Info -split "Launching app "
    $bl3_bin = $bl3_bin -replace "'", ""
    $bl3_bin, $bl3_arg = $bl3_bin -split "with commandline "
    $bl3_bin = $bl3_bin -replace "Borderlands3.exe", "OakGame/Binaries/Win64/Borderlands3.exe"

    # Sanity check- make sure binary exists
    $null = Test-Path -Path $bl3_bin -ErrorAction stop
    Write-Host Found Borderlands 3 args

    Write-Host Writing launch args to script
    (Get-Content -Path $NC_SCRIPT_PATH) -replace $NC_SCRIPT_REPLACE_STRING, $bl3_arg | Set-Content -Path $NC_SCRIPT_PATH
}
catch {
    Write-Error "Unable to write launch args to NC script. Quitting..." -ErrorAction Stop    
}


Write-Host All done!