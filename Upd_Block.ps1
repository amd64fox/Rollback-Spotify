# Ignore errors from `Stop-Process`
$PSDefaultParameterValues['Stop-Process:ErrorAction'] = [System.Management.Automation.ActionPreference]::SilentlyContinue

# Add Tls12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "*****************" -ForegroundColor DarkYellow
Write-Host "Block updates Spotify" -ForegroundColor DarkYellow
Write-Host "Author: " -NoNewline
Write-Host "@Amd64fox" -ForegroundColor DarkYellow
Write-Host "*****************"`n -ForegroundColor DarkYellow

$SpotifyexePatch = "$env:APPDATA\Spotify\Spotify.exe"

$ErrorActionPreference = 'SilentlyContinue'
Stop-Process -Name Spotify
$update_test_exe = Test-Path -Path $SpotifyexePatch

if ($update_test_exe) {
    $exe = "$env:APPDATA\Spotify\Spotify.exe"
    $exe_bak = "$env:APPDATA\Spotify\Spotify.bak"
    $ANSI = [Text.Encoding]::GetEncoding(1251)
    $old = [IO.File]::ReadAllText($exe, $ANSI)

    if ($old -match "(?<=wg:\/\/desktop-update\/.)7(\/update)") {
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
                Remove-item $SpotifyexePatch -Force
                Rename-Item -path $exe_bak -NewName $SpotifyexePatch
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
    elseif ($old -match "(?<=wg:\/\/desktop-update\/.)2(\/update)") {
        copy-Item $exe $exe_bak
        $new = $old -replace "(?<=wg:\/\/desktop-update\/.)2(\/update)", '7/update'
        [IO.File]::WriteAllText($exe, $new, $ANSI)
        Write-Host "Updates blocked"`n -ForegroundColor Green
    }
    else {
        Write-Host "Failed to block updates"`n -ForegroundColor Red
    }
}
else {
    Write-Host "Could not find Spotify.exe"`n -ForegroundColor Red 
}
