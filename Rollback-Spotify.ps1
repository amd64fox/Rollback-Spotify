# Ignore errors from `Stop-Process`
$PSDefaultParameterValues['Stop-Process:ErrorAction'] = [System.Management.Automation.ActionPreference]::SilentlyContinue

# Add Tls12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


Write-Host "*****************" -ForegroundColor DarkYellow
Write-Host "Rollback Spotify" -ForegroundColor DarkYellow
Write-Host "Author: " -NoNewline
Write-Host "@Amd64fox" -ForegroundColor DarkYellow
Write-Host "*****************"`n -ForegroundColor DarkYellow


$SpotifyexePatch = "$env:APPDATA\Spotify\Spotify.exe"

Stop-Process -Name Spotify
Stop-Process -Name SpotifyWebHelper

if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module Appx -UseWindowsPowerShell -WarningAction:SilentlyContinue
}
function incorrectValue {

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

# Check version Windows
$win_os = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
$win11 = $win_os -match "\windows 11\b"
$win10 = $win_os -match "\windows 10\b"
$win8_1 = $win_os -match "\windows 8.1\b"
$win8 = $win_os -match "\windows 8\b"


if ($win11 -or $win10 -or $win8_1 -or $win8) {

    # Remove Spotify Windows Store If Any
    if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic) {
        Write-Host 'The Microsoft Store version of Spotify has been detected which is not supported.'`n
        do {
            $ch = Read-Host -Prompt "Uninstall Spotify Windows Store edition (Y/N) "
            Write-Host ""
            if (!($ch -eq 'n' -or $ch -eq 'y')) {
                incorrectValue
            }
        }
        while ($ch -notmatch '^y$|^n$')
        if ($ch -eq 'y') {      
            $ProgressPreference = 'SilentlyContinue' # Hiding Progress Bars
            Write-Host 'Uninstalling Spotify...'`n
            Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
        }
        if ($ch -eq 'n') {
            Read-Host "Exiting..." 
            exit
        }
    }
}

# Unique directory name based on time
Push-Location -LiteralPath $env:TEMP
New-Item -Type Directory -Name "RollbackTemp-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" | Convert-Path | Set-Location


if (Test-Path $SpotifyexePatch) {
    do {
        $verlast = (Get-Item $SpotifyexePatch).VersionInfo.FileVersion
        Write-Host "Client was found"
        "`n"
        Write-Host "You have version installed " -NoNewline
        Write-Host  $verlast -ForegroundColor Green
        "`n"
        Write-Host "Do you want to uninstall the current version of Spotify first, or install over it?"
        $ch = Read-Host -Prompt "Delete (Y) or install on over (R) ? "
        "`n"
        if (!($ch -eq 'y' -or $ch -eq 'r')) {
            incorrectValue
        }
    }
    while ($ch -notmatch '^y$|^r$')

}

If ($ch -eq 'y') {

    Write-Host "Uninstall Spotify..."
    Write-Host ""
    cmd /c $SpotifyexePatch /UNINSTALL /SILENT
    wait-process -name SpotifyUninstall
    Start-Sleep -Milliseconds 200
}
 
$wget = Invoke-WebRequest -UseBasicParsing -Uri https://docs.google.com/spreadsheets/d/1wztO1L4zvNykBRw7X4jxP8pvo11oQjT0O5DvZ_-S4Ok/edit#gid=0
$result = $wget.RawContent | Select-String "1.\d.\d{1,2}.\d{1,5}.g[0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z]" -AllMatches
$version1 = $result.Matches.Value[3]
$version2 = $result.Matches.Value[5]
$version3 = $result.Matches.Value[7]
$version4 = $result.Matches.Value[9]
$version5 = $result.Matches.Value[11]

do {
    $ch2 = Read-Host -Prompt "1) $version1
2) $version2
3) $version3
4) $version4
5) $version5

Select the version to rollback"
    "`n"

    if (!($ch2 -match '^1$|^2$|^3$|^4$|^5$')) {
        incorrectValue
    }

}
while ($ch2 -notmatch '^1$|^2$|^3$|^4$|^5$')

if ($ch2 -eq 1) {
    $result2 = $wget.RawContent | Select-String "https:[/][/]upgrade.scdn.co[/]upgrade[/]client[/]win32-x86[/]spotify_installer-$version1-\d{1,3}.exe" -AllMatches
    $vernew = $version1
}
if ($ch2 -eq 2) {
    $result2 = $wget.RawContent | Select-String "https:[/][/]upgrade.scdn.co[/]upgrade[/]client[/]win32-x86[/]spotify_installer-$version2-\d{1,3}.exe" -AllMatches
    $vernew = $version2
}
if ($ch2 -eq 3) {
    $result2 = $wget.RawContent | Select-String "https:[/][/]upgrade.scdn.co[/]upgrade[/]client[/]win32-x86[/]spotify_installer-$version3-\d{1,3}.exe" -AllMatches
    $vernew = $version3
}
if ($ch2 -eq 4) {
    $result2 = $wget.RawContent | Select-String "https:[/][/]upgrade.scdn.co[/]upgrade[/]client[/]win32-x86[/]spotify_installer-$version4-\d{1,3}.exe" -AllMatches
    $vernew = $version4
}
if ($ch2 -eq 5) {
    $result2 = $wget.RawContent | Select-String "https:[/][/]upgrade.scdn.co[/]upgrade[/]client[/]win32-x86[/]spotify_installer-$version5-\d{1,3}.exe" -AllMatches
    $vernew = $version5
}

Write-Host 'Downloading Spotify'
Write-Host 'Please wait...'`n

$ErrorActionPreference = 'SilentlyContinue'
Import-Module BitsTransfer
$webClient = New-Object -TypeName System.Net.WebClient
try { if (curl.exe -V) { $curl_check = $true } }
catch { $curl_check = $false }
    
try { 

    if ($curl_check) {
        curl.exe $result2.Matches.Value[0] -o "$PWD\SpotifySetup.exe" --progress-bar
    }
    
    if ($null -ne (Get-Module -Name BitsTransfer -ListAvailable) -and !($curl_check )) {
        Start-BitsTransfer -Source  $result2.Matches.Value[0] -Destination "$PWD\SpotifySetup.exe"  -DisplayName "Downloading Spotify" -Description "$vernew "
    }

    if ($null -eq (Get-Module -Name BitsTransfer -ListAvailable) -and !($curl_check )) {
        $webClient.DownloadFile($result2.Matches.Value[0], "$PWD\SpotifySetup.exe")
    }
}

catch [System.Management.Automation.MethodInvocationException] {
    Write-Host ""
    Write-Host "Error downloading SpotifySetup.exe" -ForegroundColor RED
    $Error[0].Exception
    Write-Host ""
    Write-Host "Will re-request in 5 seconds..."`n
    Start-Sleep -Milliseconds 5000 

    try { 

        if ($curl_check) {
            curl.exe $result2.Matches.Value[0] -o "$PWD\SpotifySetup.exe" --progress-bar
        }
        
        if ($null -ne (Get-Module -Name BitsTransfer -ListAvailable) -and !($curl_check )) {
            Start-BitsTransfer -Source  $result2.Matches.Value[0] -Destination "$PWD\SpotifySetup.exe"  -DisplayName "Downloading Spotify" -Description "$vernew "
        }
        if ($null -eq (Get-Module -Name BitsTransfer -ListAvailable) -and !($curl_check )) {
            $webClient.DownloadFile($result2.Matches.Value[0], "$PWD\SpotifySetup.exe")
        }
    }
        
    catch [System.Management.Automation.MethodInvocationException] {
        Write-Host "Error again, script stopped" -ForegroundColor RED
        $Error[0].Exception
        Write-Host ""
        Write-Host "Try to check your internet connection and run the installation again."`n
        $tempDirectory = $PWD
        Pop-Location
        Start-Sleep -Milliseconds 200
        Remove-Item -Recurse -LiteralPath $tempDirectory 
        exit
    }
}

Write-Host ""


$test_Spotifyexe = Test-Path $SpotifyexePatch

If ($ch -eq 'r' -and $test_Spotifyexe) {

    if ($vernew -lt $verlast) {


        Write-Host 'Please confirm reinstallation'`n
        
    }
}

# Client installation
Write-Host "Installing Spotify..." 
Write-Host ""
cmd /c $PWD\SpotifySetup.exe /SILENT

Stop-Process -Name Spotify

Start-Sleep -Milliseconds 200

$tempDirectory = $PWD
Pop-Location

Start-Sleep -Milliseconds 200
Remove-Item -Recurse -LiteralPath $tempDirectory 


# Block updates

$ErrorActionPreference = 'SilentlyContinue'
$update_test_exe = Test-Path -Path $SpotifyexePatch

Write-Host "Block updates"`n

if ($update_test_exe) {
    $exe = "$env:APPDATA\Spotify\spotify.exe"
    $ANSI = [Text.Encoding]::GetEncoding(1251)
    $old = [IO.File]::ReadAllText($exe, $ANSI)
    if ($old -match "(?<=wg:\/\/desktop-update\/.)2(\/update)") {
        $new = $old -replace "(?<=wg:\/\/desktop-update\/.)2(\/update)", '7/update'
        [IO.File]::WriteAllText($exe, $new, $ANSI)
    }
    else {
        Write-Host "Failed to block updates"`n -ForegroundColor Red
    }
}
else {
    Write-Host "Could not find Spotify.exe"`n -ForegroundColor Red 
}

Write-Host "Completed successfully"`n -ForegroundColor Green
exit
