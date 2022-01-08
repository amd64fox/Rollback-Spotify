# Ignore errors from `Stop-Process`
$PSDefaultParameterValues['Stop-Process:ErrorAction'] = [System.Management.Automation.ActionPreference]::SilentlyContinue

# Check Tls12
$tsl_check = [Net.ServicePointManager]::SecurityProtocol 
if (!($tsl_check -match '^tls12$' )) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Write-Host "*****************" -ForegroundColor DarkYellow
Write-Host "Rollback Spotify" -ForegroundColor DarkYellow
Write-Host "Author: " -NoNewline
Write-Host "@Amd64fox" -ForegroundColor DarkYellow
Write-Host "*****************"`n -ForegroundColor DarkYellow


$SpotifyexePatch = "$env:APPDATA\Spotify\Spotify.exe"


Stop-Process -Name Spotify
Stop-Process -Name SpotifyWebHelper

if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module Appx -UseWindowsPowerShell
}


[System.Security.Principal.WindowsPrincipal] $principal = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$isUserAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isUserAdmin) {
    Write-Host 'Startup detected with administrator rights'`n
}
# Check version Windows
$win_os = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
$win11 = $win_os -match "\windows 11\b"
$win10 = $win_os -match "\windows 10\b"
$win8_1 = $win_os -match "\windows 8.1\b"
$win8 = $win_os -match "\windows 8\b"


if ($win11 -or $win10 -or $win8_1 -or $win8) {


    # Check and del Windows Store
    if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic) {
        Write-Host @'
The Microsoft Store version of Spotify has been detected which is not supported.
'@`n
        $ch = Read-Host -Prompt "Uninstall Spotify Windows Store edition (Y/N) "
        if ($ch -eq 'y') {
            Write-Host @'
Uninstalling Spotify.
'@`n
            Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
        }
        else {
            Write-Host @'
Exiting...
'@`n
            Pause 
            exit
        }
    }
}


Push-Location -LiteralPath $env:TEMP
try {
    # Unique directory name based on time
    New-Item -Type Directory -Name "Rollback-Spotify-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" `
  | Convert-Path `
  | Set-Location
}
catch {
    Write-Output $_
    Read-Host 'Press any key to exit...'
    exit
}



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
    
            Write-Host "Oops, an incorrect value, " -ForegroundColor Red -NoNewline
            Write-Host "enter again through..." -NoNewline
            Start-Sleep -Milliseconds 1000
            Write-Host "3" -NoNewline
            Start-Sleep -Milliseconds 1000
            Write-Host ".2" -NoNewline
            Start-Sleep -Milliseconds 1000
            Write-Host ".1"
            Start-Sleep -Milliseconds 1000     
            Clear-Host
        }
    }
    while ($ch -notmatch '^y$|^r$')

}

If ($ch -eq 'y') {
    "`n"
    Write-Host "Click Ok to delete Spotify"
    "`n"
    Start-Process -FilePath $SpotifyexePatch /UNINSTALL
    Start-Sleep -Milliseconds 1500
    wait-process -Name SpotifyUninstall
    Start-Sleep -Milliseconds 1100

 
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
    
        Write-Host "Oops, an incorrect value, " -ForegroundColor Red -NoNewline
        Write-Host "enter again through..." -NoNewline
        Start-Sleep -Milliseconds 1000
        Write-Host "3" -NoNewline
        Start-Sleep -Milliseconds 1000
        Write-Host ".2" -NoNewline
        Start-Sleep -Milliseconds 1000
        Write-Host ".1"
        Start-Sleep -Milliseconds 1000     
        Clear-Host
    
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



    
Write-Host 'Downloading and install Spotify'

Write-Host 'Please wait...'`n


try {

    Start-BitsTransfer -Source  $result2.Matches.Value[0] -Destination "$PWD\SpotifySetup.exe"  -DisplayName "Downloading Spotify" -Description "$vernew "
    
}


catch {
    Write-Output $_
    Read-Host "An error occurred while downloading the SpotifySetup.exe file`nPress any key to exit..."
    exit
}



$test_Spotifyexe = Test-Path $SpotifyexePatch

If ($ch -eq 'r' -and $test_Spotifyexe) {

    if ($vernew -lt $verlast) {


        Write-Host 'Please confirm reinstallation'`n
        
    }
}



# Correcting the error if the spotify installer was launched from the administrator

if ($isUserAdmin) {
    $apppath = 'powershell.exe'
    $taskname = 'Spotify install'
    $action = New-ScheduledTaskAction -Execute $apppath -Argument "-NoLogo -NoProfile -Command & `'$PWD\SpotifySetup.exe`'" 
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -WakeToRun
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Settings $settings -Force | Write-Verbose
    Start-ScheduledTask -TaskName $taskname
    Start-Sleep -Seconds 2
    Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
    Start-Sleep -Seconds 2
    wait-process -name SpotifySetup
}
else {

    Start-Process -FilePath $PWD\SpotifySetup.exe; wait-process -name SpotifySetup
}



Stop-Process -Name Spotify
Stop-Process -Name SpotifyWebHelper
Stop-Process -Name SpotifySetup

Start-Sleep -Milliseconds 200


$tempDirectory = $PWD
Pop-Location


Start-Sleep -Milliseconds 200
Remove-Item -Recurse -LiteralPath $tempDirectory 



# Block updates

$ErrorActionPreference = 'SilentlyContinue'  # Команда гасит легкие ошибки

$update_directory = Test-Path -Path $env:LOCALAPPDATA\Spotify 
$migrator_bak = Test-Path -Path $env:APPDATA\Spotify\SpotifyMigrator.bak  
$migrator_exe = Test-Path -Path $env:APPDATA\Spotify\SpotifyMigrator.exe
$Check_folder_file = Get-ItemProperty -Path $env:LOCALAPPDATA\Spotify\Update | Select-Object Attributes 
$folder_update_access = Get-Acl $env:LOCALAPPDATA\Spotify\Update


# Если была установка клиента 
if (!($update_directory)) {

    # Создать папку Spotify в Local
    New-Item -Path $env:LOCALAPPDATA -Name "Spotify" -ItemType "directory" | Out-Null

    #Создать файл Update
    New-Item -Path $env:LOCALAPPDATA\Spotify\ -Name "Update" -ItemType "file" -Value "STOPIT" | Out-Null
    $file = Get-ItemProperty -Path $env:LOCALAPPDATA\Spotify\Update
    $file.Attributes = "ReadOnly", "System"
      
    # Если оба файлав мигратора существуют то .bak удалить, а .exe переименовать в .bak
    If ($migrator_exe -and $migrator_bak) {
        Remove-item $env:APPDATA\Spotify\SpotifyMigrator.bak -Recurse -Force
        Rename-Item -path $env:APPDATA\Spotify\SpotifyMigrator.exe -NewName $env:APPDATA\Spotify\SpotifyMigrator.bak
    }

    # Если есть только мигратор .exe то переименовать его в .bak
    if ($migrator_exe) {
        Rename-Item -path $env:APPDATA\Spotify\SpotifyMigrator.exe -NewName $env:APPDATA\Spotify\SpotifyMigrator.bak
    }

}


# Если клиент уже был 
If ($update_directory) {


    #Удалить папку Update если она есть
    if ($Check_folder_file -match '\bDirectory\b') {  

        #Если у папки Update заблокированы права то разблокировать 
        if ($folder_update_access.AccessToString -match 'Deny') {

        ($ACL = Get-Acl $env:LOCALAPPDATA\Spotify\Update).access | ForEach-Object {
                $Users = $_.IdentityReference 
                $ACL.PurgeAccessRules($Users) }
            $ACL | Set-Acl $env:LOCALAPPDATA\Spotify\Update
        }
        Remove-item $env:LOCALAPPDATA\Spotify\Update -Recurse -Force
    } 

    #Создать файл Update если его нет
    if (!($Check_folder_file -match '\bSystem\b|' -and $Check_folder_file -match '\bReadOnly\b')) {  
        New-Item -Path $env:LOCALAPPDATA\Spotify\ -Name "Update" -ItemType "file" -Value "STOPIT" | Out-Null
        $file = Get-ItemProperty -Path $env:LOCALAPPDATA\Spotify\Update
        $file.Attributes = "ReadOnly", "System"
    }
    # Если оба файлав мигратора существуют то .bak удалить, а .exe переименовать в .bak
    If ($migrator_exe -and $migrator_bak) {
        Remove-item $env:APPDATA\Spotify\SpotifyMigrator.bak -Recurse -Force
        Rename-Item -path $env:APPDATA\Spotify\SpotifyMigrator.exe -NewName $env:APPDATA\Spotify\SpotifyMigrator.bak
    }

    # Если есть только мигратор .exe то переименовать его в .bak
    if ($migrator_exe) {
        Rename-Item -path $env:APPDATA\Spotify\SpotifyMigrator.exe -NewName $env:APPDATA\Spotify\SpotifyMigrator.bak
    }

}
Write-Host 'Updates blocked'`n
Write-Host "Installation completed"
exit
