# Ignore errors from `Stop-Process`
$PSDefaultParameterValues['Stop-Process:ErrorAction'] = [System.Management.Automation.ActionPreference]::SilentlyContinue

# Add Tls12
[Net.ServicePointManager]::SecurityProtocol = 3072

$ErrorActionPreference = 'SilentlyContinue'
Stop-Process -Name Spotify

$spotifyexe = Join-Path $env:APPDATA 'Spotify\Spotify.exe'
$update_test_exe = Test-Path -Path $Spotifyexe

if ($update_test_exe) {
    $versionInfo = (Get-Item $spotifyexe).VersionInfo
    $currentVersion = $versionInfo.ProductVersion
    $targetVersion = "1.1.59.710"
    
    if ([version]$currentVersion -lt [version]$targetVersion) {
        Write-Warning "Your version $($currentVersion) is officially restricted by the Spotify developers, `nWorking versions start at $($targetVersion) and up.`n"
    }
    
    $exe_bak = Join-Path $env:APPDATA 'Spotify\Spotify.bak'

    $ANSI = [Text.Encoding]::GetEncoding(1251)
    $old = [IO.File]::ReadAllText($spotifyexe, $ANSI)

    if ($old -match "(?<=desktop-update\/.)7(\/update)") {
        Write-Host "Spotify updates are already blocked"`n
        if (Test-Path -Path $exe_bak) {
            do {
                $ch = Read-Host -Prompt "Do you want to unlock updates? (Y/N)"
                Write-Host ""
                if (!($ch -eq 'n' -or $ch -eq 'y')) {
                    Write-Host "Oops, an incorrect value, " -ForegroundColor Red -NoNewline
                    Write-Host "enter again through " -NoNewline
                    Start-Sleep -Milliseconds 1000
                    Write-Host "3" -NoNewline 
                    Start-Sleep -Milliseconds 1000
                    Write-Host " 2" -NoNewline
                    Start-Sleep -Milliseconds 1000
                    Write-Host " 1"
                    Start-Sleep -Milliseconds 1000     
                    Clear-Host
                }
            }
            while ($ch -notmatch '^y$|^n$')
            if ($ch -eq 'y') {   
                Remove-item $spotifyexe -Force
                Rename-Item -path $exe_bak -NewName $spotifyexe
                Write-Host "Updates unlocked"
                exit
            }
            if ($ch -eq 'n') {   
                exit
            }
        }
        Write-Host "Failed to find backup file Spotify.exe, to unlock updates, reinstall Spotify manually"
        exit
    }
    elseif ($old -match "(?<=desktop-update\/.)2(\/update)") {
        copy-Item $spotifyexe $exe_bak
        $new = $old -replace "(?<=desktop-update\/.)2(\/update)", '7/update'
        [IO.File]::WriteAllText($spotifyexe, $new, $ANSI)
        Write-Host "Updates blocked"`n -ForegroundColor Green
    }
    else {
        Write-Host "Failed to block updates"`n -ForegroundColor Red
    }
}
else {
    Write-Host "Could not find Spotify.exe"`n -ForegroundColor Red 
}
