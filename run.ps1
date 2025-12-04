
param (
    [Alias("v")]
    [string]$version,

    [Alias("u")]
    [switch]$uninstall,

    [Alias("n")]
    [switch]$not_block,

    [Alias("b")]
    [string]$buildtype = "Release"
)

function Test-Paths {
    param (
        [switch]$Sp_exe,
        [switch]$Sp_exeTemp
    )

    if ($Sp_exe) {
        return Test-Path -LiteralPath (Join-Path $spRoaming -ChildPath 'Spotify.exe')
    }

    if ($Sp_exeTemp) {
        return Test-Path -LiteralPath (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'SpotifySetup.exe')
    }
}

function Write-Text {

    param(
        [Alias("txt")]
        [string]$text,

        [Alias("w")]
        [switch]$warning,

        [Alias("f")]
        [switch]$first_padding,

        [Alias("e")]
        [switch]$end_padding,

        [Alias("t")]
        [switch]$two_padding,

        [Alias("c")]
        [string]$color = "White",

        [Alias("n")]
        [switch]$noNewline
    )
    if ($two_padding) {
        write-host 
    }
    if ($first_padding) {
        write-host 
    }
    if ($warning) {
        Write-Warning $text
    }
    else {
        if ($noNewline) {
            write-host $text -ForegroundColor $color -NoNewline
        }
        else {
            write-host $text -ForegroundColor $color
        }
    }
    if ($end_padding) {
        write-host 
    }
    if ($two_padding) {
        write-host 
    }
}

function Check-Os {
    param(
        [string]$check
    )

    $osVersions = @{}
    $osVersions["win7"] = "6.1"
    $osVersions["win8"] = "6.2, 6.3"
    $osVersions["win10"] = "10.0"

    $currentVersion = "$(([System.Environment]::OSVersion.Version).Major).$(([System.Environment]::OSVersion.Version).Minor)"

    foreach ($version in $check -split ", ") {
        if ($osVersions.ContainsKey($version) -and $osVersions[$version] -contains $currentVersion) {
            return $true
        }
    }

    return $false
}

function Compare-Arch {
    param(
        [Alias("t")]
        [string]$TargetArchitecture = $null
    )

    $CurrentArchitecture = $env:processor_architecture
    $ArchitectureGroups = @{
        'x64'   = @('AMD64', 'IA64', 'EM64T')
        'x86'   = @('x86')
        'arm64' = @('ARM64')
    }

    if (!($TargetArchitecture)) {
        return $ArchitectureGroups.Keys | Where-Object { $ArchitectureGroups[$_] -contains $CurrentArchitecture }
    }

    $ValidArchitectures = $ArchitectureGroups.Keys
    if (-not $ValidArchitectures.Contains($TargetArchitecture)) {
        Write-Text -text "Error: Invalid architecture: $($TargetArchitecture)" -warning
        return $false
    }

    # exception for x86 if the current architecture is x64
    if ($CurrentArchitecture -eq 'AMD64' -and $TargetArchitecture -eq 'x86') {
        return $true
    }

    # comparing the current architecture with the target
    if ($ArchitectureGroups[$TargetArchitecture] -contains $CurrentArchitecture) {
        return $true
    }
    else {
        return $false
    }
}

function Get-UserChoice {
    param(
        [Alias("o")]
        [hashtable]$Options,
		
        [int]$DefaultChoice = 0
    )

    # Check if Options hashtable is provided
    if (-not $Options) {
        Write-Host "Options hashtable is required." -ForegroundColor Red
        return
    }

    # Check if "answer" key exists
    if (-not $Options.ContainsKey("answer")) {
        Write-Host "Incorrect format of the Options hashtable. 'answer' key is missing." -ForegroundColor Red
        return
    }

    $question = $Options["question"]
    $answers = $Options["answer"]
    $choiceDescriptions = @()

    if ($Options.ContainsKey("description")) {
        $descriptions = $Options["description"]

        if ($answers.Count -ne $descriptions.Count) {
            Write-Host "The number of answers does not match the number of descriptions." -ForegroundColor Red
            return
        }

        for ($i = 0; $i -lt $answers.Count; $i++) {
            $choiceDescriptions += [System.Management.Automation.Host.ChoiceDescription]::new("&$($answers[$i])", $descriptions[$i])
        }
    }
    else {
        $choiceDescriptions = $answers | ForEach-Object { [System.Management.Automation.Host.ChoiceDescription]::new("&$_") }
    }

    $choice = $host.UI.PromptForChoice($null, $question, $choiceDescriptions, $DefaultChoice)
    Write-Host

    return $choice
}

Function Version-Select {

    param (
        [Alias("c")]
        $jsonContent,

        [string]$lastWin7_8 = "1.2.5.1006"
    )



    if ($version) {

        switch -Regex ($version) {

            '^\d+\.\d+\.\d+\.\d+(-(x|arm)(86|64))?$' {

                if ($version -match '^\d+\.\d+\.\d+\.\d+-(x|arm)(86|64)$') {
        
                    $parts = $version -split '-'
                    $ver = $parts[0]
                    $arch = $parts[1]
                }
                else {
                    $ver = $version 
                    $arch = Compare-Arch
                }
        
                if (Check-Os "win7, win8") {
        
                    if ([version]$ver -gt [version]$lastWin7_8) {
                        Write-Text -txt "version $($ver) is not supported in Windows 7 - 8.1" -w -e
                        break
                    }
                }
        
                $link = $jsonContent.$ver.links.win.$arch
        
                if ($link -and $link -ne "" -and (Compare-Arch -t $arch)) {

                    $data = [PSCustomObject]@{
                        link = $link 
                        name = $jsonContent.$ver
                        arch = $arch
                    }
                    return $data
                }
            
            }

            "^last(-(x|arm)(86|64))?$" {

                if (Check-Os "win10") {
                    $filteredVersions = $jsonContent.PSObject.Properties
                    if ($buildtype -ne "all") {
                        $filteredVersions = $filteredVersions | Where-Object { $_.Value.buildType -ieq $buildtype }
                    }
                    $name = $filteredVersions | Select-Object -First 1
                }
                else {
                    $filteredVersions = $jsonContent.PSObject.Properties
                    if ($buildtype -ne "all") {
                        $filteredVersions = $filteredVersions | Where-Object { $_.Value.buildType -ieq $buildtype }
                    }
                    $name = $filteredVersions | Where-Object { $_.Name -eq $lastWin7_8 }
                }
        
                if ($version -match '^last-(x|arm)(86|64)$' ) {
                    $parts = $version -split '-'
                    $arch = $parts[1]
                }
                else { $arch = Compare-Arch }
        
                $link = $name.Value.links.win.$arch
        
                if ($link -and $link -ne "" -and (Compare-Arch -t $arch)) {
                    $data = [PSCustomObject]@{
                        link = $link 
                        name = $name.Value
                        arch = $arch
                    }
                    return $data
                }
            }

            default {
                Write-Text -txt 'Invalid value for the "version" parameter' -w -e
                break
            }
        }
    }

    $allVersions = $jsonContent.PSObject.Properties
    if ($buildtype -ne "all") {
        $allVersions = $allVersions | Where-Object { $_.Value.buildType -ieq $buildtype }
    }

    if (Check-Os "win7, win8") {

        $firstVersions = ($allVersions | Select-Object -Last 88) | Select-Object -First 10
    }

    else {
        # Output the first 10 versions
        $firstVersions = $allVersions | Select-Object -First 10
    }
    # Iterate through the first 10 versions and display information
    $asd = 1 
    foreach ($version in $firstVersions) {
        Write-Host "[$($asd)] - $($version.Name)"
        $asd++
    }
    
    $first10 = $true

    while ($true) {

        Write-Text -txt "[1-$($asd-1)] - Choose version number" -f
        if ($first10) { Write-Host "[S] - Show the entire list of versions" }
        Write-Host "[E] - Exit"
        $choice = Read-Host "`nChoose an action"
        Write-Host

        switch ($choice) {
            { $_ -as [int] -and [int]$_ -ge 1 -and [int]$_ -le $asd - 1 } {
                # User selects the version number
                $selectedVersion = $firstVersions[$choice - 1].Name

                $archtest = $jsonContent.$selectedVersion.links.win
                $availableArchitectures = @()
                $index = 1
                $archMapping = @{} 
            
                if ($archtest.x86) {
                    $availableArchitectures += "[$index] - x86"
                    $archMapping[$index.ToString()] = 'x86'
                    $index++
                }
                if ($archtest.x64) {
                    $availableArchitectures += "[$index] - x64"
                    $archMapping[$index.ToString()] = 'x64'
                    $index++
                }
                if ($archtest.arm64) {
                    $availableArchitectures += "[$index] - arm64"
                    $archMapping[$index.ToString()] = 'arm64'
                }
                do {
                    if ($availableArchitectures.Count -match '(2|3)') {

                        Write-Text -txt "`nChoose version architecture:`n`n$($availableArchitectures -join "`n")"
                        $choice = Read-Host "`nEnter your choice"
                        Write-Host
                        $selectedArchitecture = $archMapping[$choice]
                
                        if (!($selectedArchitecture)) {
                            Write-Warning "Incorrect input. Please choose a valid option."
                        } 
                    }
                    else { $selectedArchitecture = $archMapping['1'] }

                    if (Compare-Arch -t $selectedArchitecture ) {
                        $ready_link = $jsonContent.$selectedVersion.links.win.[string]$selectedArchitecture 
                        if ($ready_link -ne $null -and $ready_link -ne "") {

                            $data = [PSCustomObject]@{
                                link = $ready_link
                                name = $jsonContent.$selectedVersion
                                arch = $selectedArchitecture 
                            }
                            return $data
                        }                              
                    }
                    else {
                        Write-Text -txt "Selected $($selectedArchitecture) architecture does not match the $(Compare-Arch) architecture of your OS" -w
                        $selectedArchitecture = $false
                    }
                            
                } while (-not $selectedArchitecture)
            }
            { $first10 -eq $true -and $_ -eq "s" } {
                # Show the entire list of versions
                cls
                $asd = 1

                if (Check-Os "win7, win8") {
                    $firstVersions = $allVersions | Select-Object -Last 88
                }
                else {

                    $firstVersions = $allVersions
                }
                foreach ($version in $firstVersions) {
                    Write-Host "$($asd)) $($version.Name)"
                    $asd++
                }
                $Count = $firstVersions | Measure-Object | Select-Object -ExpandProperty Count
                $firstVersions = $firstVersions | Select-Object -First $Count
                $first10 = $false
                break
            }
            "e" {
                Write-Text -txt "script stopped" -w -f
                Pause
                exit
                
            }
            default {
                Write-Text -txt "Incorrect input" -w -f
            }
        }
    }
}

function Kill-Spotify {
    param (
        [int]$maxAttempts = 5
    )

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $allProcesses = Get-Process -ErrorAction SilentlyContinue

        $spotifyProcesses = $allProcesses | Where-Object { $_.ProcessName -like "*spotify*" }

        if ($spotifyProcesses) {
            foreach ($process in $spotifyProcesses) {
                try {
                    Stop-Process -Id $process.Id -Force
                }
                catch {
                    # Ignore NoSuchProcess exception
                }
            }
            Start-Sleep -Seconds 1
        }
        else {
            break
        }
    }

    if ($attempt -gt $maxAttempts) {
        Write-Host "The maximum number of attempts to terminate a process has been reached."
    }
}

function Invoke-Method {

    param(

        [string]$method,

        [string]$url,

        [string]$namefile,

        [int]$retries = 3,

        [int]$wait = 4
    )

    $attempt = 0

    while ($attempt -le $retries) {
        try {
            switch ($method) {

                "download" {

                    Invoke-Download -URL $url -FileName $namefile
                    return

                }
                "rest" {

                    return Invoke-RestMethod -Uri $url

                }
                default {
                    Write-Host 'Invalid value for the "method" parameter' 
                    exit
                }
            }
        }
        catch {
            $attempt++
            if ($attempt -le $retries) {

                Write-Warning "Attempt $attempt failed: $($_.Exception.Message)"
                Write-Text -txt "Retrying in $($wait) seconds..." -e
                Start-Sleep -Seconds $wait
                $wait += 2
            }
            else {
                Write-Text -txt "Maximum repetitions for the '$($method)' method reached `n`nConnection issues, script halte." -color "red"
                exit
            }
        }
    }
}

function Invoke-Download {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Alias('URI')]
        [ValidateNotNullOrEmpty()]
        [string]$URL,
    
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination = [System.IO.Path]::GetTempPath(),
    
        [Parameter(Position = 2)]
        [string]$FileName,

        [string[]]$UserAgent = @('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36', 'Googlebot/2.1 (+http://www.google.com/bot.html)'),

        [string]$TempPath = [System.IO.Path]::GetTempPath(),

        [switch]$IgnoreDate,
        [switch]$NoProgress
    )	

    begin {
        # Required on Windows Powershell only
        if ($PSEdition -eq 'Desktop') {
            Add-Type -AssemblyName System.Net.Http
            Add-Type -AssemblyName System.Web
        }

        # Enable TLS 1.2 in addition to whatever is pre-configured
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        # Create one single client object for the pipeline
        $HttpClient = New-Object System.Net.Http.HttpClient
    }

    process {

        Write-Verbose "Requesting headers from URL '$URL'"

        foreach ($UserAgentString in $UserAgent) {
            $HttpClient.DefaultRequestHeaders.Remove('User-Agent') | Out-Null
            if ($UserAgentString) {
                Write-Verbose "Using UserAgent '$UserAgentString'"
                $HttpClient.DefaultRequestHeaders.Add('User-Agent', $UserAgentString)
            }

            # This sends a GET request but only retrieves the headers
            $ResponseHeader = $HttpClient.GetAsync($URL, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result

            # Exit the foreach if success
            if ($ResponseHeader.IsSuccessStatusCode) {
                break
            }
        }

        if ($ResponseHeader.IsSuccessStatusCode) {
            Write-Verbose 'Successfully retrieved headers'

            if ($ResponseHeader.RequestMessage.RequestUri.AbsoluteUri -ne $URL) {
                Write-Verbose "URL '$URL' redirects to '$($ResponseHeader.RequestMessage.RequestUri.AbsoluteUri)'"
            }

            try {
                $FileSize = $null
                $FileSize = [int]$ResponseHeader.Content.Headers.GetValues('Content-Length')[0]
                $FileSizeReadable = switch ($FileSize) {
                    { $_ -gt 1TB } { '{0:n2} TB' -f ($_ / 1TB); Break }
                    { $_ -gt 1GB } { '{0:n2} GB' -f ($_ / 1GB); Break }
                    { $_ -gt 1MB } { '{0:n2} MB' -f ($_ / 1MB); Break }
                    { $_ -gt 1KB } { '{0:n2} KB' -f ($_ / 1KB); Break }
                    default { '{0} B' -f $_ }
                }
                Write-Verbose "File size: $FileSize bytes ($FileSizeReadable)"
            }
            catch {
                Write-Verbose 'Unable to determine file size'
            }

            # Try to get the last modified date from the "Last-Modified" header, use error handling in case string is in an invalid format
            try {
                $LastModified = $null
                $LastModified = [DateTime]::ParseExact($ResponseHeader.Content.Headers.GetValues('Last-Modified')[0], 'r', [System.Globalization.CultureInfo]::InvariantCulture)
                Write-Verbose "Last modified: $($LastModified.ToString())"
            }
            catch {
                Write-Verbose 'Last-Modified header not found'
            }

            if ($FileName) {
                $FileName = $FileName.Trim()
                Write-Verbose "Will use the supplied filename '$FileName'"
            }
            else {
                # Get the file name from the "Content-Disposition" header if available
                try {
                    $ContentDispositionHeader = $null
                    $ContentDispositionHeader = $ResponseHeader.Content.Headers.GetValues('Content-Disposition')[0]
                    Write-Verbose "Content-Disposition header found: $ContentDispositionHeader"
                }
                catch {
                    Write-Verbose 'Content-Disposition header not found'
                }
                if ($ContentDispositionHeader) {
                    $ContentDispositionRegEx = @'
^.*filename\*?\s*=\s*"?(?:UTF-8|iso-8859-1)?(?:'[^']*?')?([^";]+)
'@
                    if ($ContentDispositionHeader -match $ContentDispositionRegEx) {
                        # GetFileName ensures we are not getting a full path with slashes. UrlDecode will convert characters like %20 back to spaces.
                        $FileName = [System.IO.Path]::GetFileName([System.Web.HttpUtility]::UrlDecode($matches[1]))
                        # If any further invalid filename characters are found, convert them to spaces.
                        [IO.Path]::GetinvalidFileNameChars() | ForEach-Object { $FileName = $FileName.Replace($_, ' ') }
                        $FileName = $FileName.Trim()
                        Write-Verbose "Extracted filename '$FileName' from Content-Disposition header"
                    }
                    else {
                        Write-Verbose 'Failed to extract filename from Content-Disposition header'
                    }
                }

                if ([string]::IsNullOrEmpty($FileName)) {
                    # If failed to parse Content-Disposition header or if it's not available, extract the file name from the absolute URL to capture any redirections.
                    # GetFileName ensures we are not getting a full path with slashes. UrlDecode will convert characters like %20 back to spaces. The URL is split with ? to ensure we can strip off any API parameters.
                    $FileName = [System.IO.Path]::GetFileName([System.Web.HttpUtility]::UrlDecode($ResponseHeader.RequestMessage.RequestUri.AbsoluteUri.Split('?')[0]))
                    [IO.Path]::GetinvalidFileNameChars() | ForEach-Object { $FileName = $FileName.Replace($_, ' ') }
                    $FileName = $FileName.Trim()
                    Write-Verbose "Extracted filename '$FileName' from absolute URL '$($ResponseHeader.RequestMessage.RequestUri.AbsoluteUri)'"
                }
            }

        }
        else {
            Write-Verbose 'Failed to retrieve headers'
        }

        if ([string]::IsNullOrEmpty($FileName)) {
            # If still no filename set, extract the file name from the original URL.
            # GetFileName ensures we are not getting a full path with slashes. UrlDecode will convert characters like %20 back to spaces. The URL is split with ? to ensure we can strip off any API parameters.
            $FileName = [System.IO.Path]::GetFileName([System.Web.HttpUtility]::UrlDecode($URL.Split('?')[0]))
            [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object { $FileName = $FileName.Replace($_, ' ') }
            $FileName = $FileName.Trim()
            Write-Verbose "Extracted filename '$FileName' from original URL '$URL'"
        }

        $DestinationFilePath = Join-Path $Destination $FileName

        # Open the HTTP stream
        $ResponseStream = $HttpClient.GetStreamAsync($URL).Result

        if ($ResponseStream.CanRead) {

            # Check TempPath exists and create it if not
            if (-not (Test-Path -LiteralPath $TempPath -PathType Container)) {
                Write-Verbose "Temp folder '$TempPath' does not exist"
                try {
                    New-Item -Path $Destination -ItemType Directory -Force | Out-Null
                    Write-Verbose "Created temp folder '$TempPath'"
                }
                catch {
                    Write-Error "Unable to create temp folder '$TempPath': $_"
                    return
                }
            }

            # Generate temp file name
            $TempFileName = (New-Guid).ToString('N') + ".tmp"
            $TempFilePath = Join-Path $TempPath $TempFileName

            # Check Destination exists and create it if not
            if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
                Write-Verbose "Output folder '$Destination' does not exist"
                try {
                    New-Item -Path $Destination -ItemType Directory -Force | Out-Null
                    Write-Verbose "Created output folder '$Destination'"
                }
                catch {
                    Write-Error "Unable to create output folder '$Destination': $_"
                    return
                }
            }

            # Open file stream
            try {
                $FileStream = [System.IO.File]::Create($TempFilePath)
            }
            catch {
                Write-Error "Unable to create file '$TempFilePath': $_"
                return
            }
    
            if ($FileStream.CanWrite) {
                Write-Verbose "Downloading to temp file '$TempFilePath'..."

                $Buffer = New-Object byte[] 64KB
                $BytesDownloaded = 0
                $ProgressIntervalMs = 250
                $ProgressTimer = (Get-Date).AddMilliseconds(-$ProgressIntervalMs)

                while ($true) {
                    try {
                        # Read stream into buffer
                        $ReadBytes = $ResponseStream.Read($Buffer, 0, $Buffer.Length)

                        # Track bytes downloaded and display progress bar if enabled and file size is known
                        $BytesDownloaded += $ReadBytes
                        if (!$NoProgress -and (Get-Date) -gt $ProgressTimer.AddMilliseconds($ProgressIntervalMs)) {
                            if ($FileSize) {
                                $PercentComplete = [System.Math]::Floor($BytesDownloaded / $FileSize * 100)

                                # Calculate the sizes in megabytes
                                $BytesDownloadedMB = $BytesDownloaded / 1MB
                                $TotalSizeMB = $FileSize / 1MB

                                # Format the progress status with one decimal place for megabytes
                                $ProgressStatus = "{0:n1} Mb of {1:n1} Mb ({2}%)" -f $BytesDownloadedMB, $TotalSizeMB, $PercentComplete
                                Write-Progress -Activity "Downloading $FileName" -Status $ProgressStatus -PercentComplete $PercentComplete
                            }
                            else {
                                Write-Progress -Activity "Downloading $FileName" -Status "$BytesDownloaded of ? bytes" -PercentComplete 0
                            }
                            $ProgressTimer = Get-Date
                        }

                        # If end of stream
                        if ($ReadBytes -eq 0) {
                            Write-Progress -Activity "Downloading $FileName" -Completed
                            $FileStream.Close()
                            $FileStream.Dispose()
                            try {
                                Write-Verbose "Moving temp file to destination '$DestinationFilePath'"
                                Move-Item -LiteralPath $TempFilePath -Destination $DestinationFilePath -Force
                            }
                            catch {
                                Write-Error "Error moving file from '$TempFilePath' to '$DestinationFilePath': $_"
                                return
                            }
                            if ($LastModified -and -not $IgnoreDate) {
                                Write-Verbose 'Setting Last Modified date'
                                (Get-Item -LiteralPath $DestinationFilePath).LastWriteTime = $LastModified
                            }
                            Write-Verbose 'Download complete!'
                            break
                        }
                        $FileStream.Write($Buffer, 0, $ReadBytes)
                    }
                    catch {
                        Write-Error "Error downloading file: $_"
                        Write-Progress -Activity "Downloading $FileName" -Completed
                        $FileStream.Close()
                        $FileStream.Dispose()
                        break
                    }
                }

            }
        }
        else {
            $ErrorCode = [int]$ResponseHeader.StatusCode.value__
            throw "Failed to start download $($FileName). HTTP Status Code: $($ErrorCode)"
        }

        # Reset this to avoid reusing the same name when fed multiple URLs via the pipeline
        $FileName = $null
    }

    end {
        $HttpClient.Dispose()
    }
}

Function UninstallSpMs {

    if ($psv -ge 7) {
        Import-Module Appx -UseWindowsPowerShell -WarningAction:SilentlyContinue
    }

    if ((Check-Os "win8, win10") -and (Get-AppxPackage -Name SpotifyAB.SpotifyMusic)) {

        Write-Text -txt "The Microsoft Store version of Spotify has been detected which is not supported" -e

        if (!($uninstall)) {

            $options = @{
                "question"    = "Uninstall Spotify Microsoft Store edition?"
                "answer"      = @("Yes", "No")
                "description" = @("Complete removal of Spotify from the Microsoft Store", "Do not uninstall Spotify from the Microsoft Store, the script will be stopped")
            }
             
            $ch = Get-UserChoice -o $options

        }

        if ($ch -eq 1 ) { 
            Write-Text -txt "script stopped" -w
            Pause
            exit
        }

        if ($ch -eq 0 -or $uninstall) { 

            $ProgressPreference = 'SilentlyContinue' # Hiding Progress Bars
            if ($uninstall) { Write-Host "Automatically uninstalling Spotify MS..."`n }
            if (!($uninstall)) { Write-Host "Uninstalling Spotify MS..."`n }
            Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
        }
    }
}

function UninstallSp {

    function unlockFolder {

        $blockFileUpdate = "$spLocal\Update"

        if (Test-Path $blockFileUpdate -PathType Container) {
            $folderUpdateAccess = Get-Acl $blockFileUpdate
            $hasDenyAccessRule = $false

            foreach ($accessRule in $folderUpdateAccess.Access) {
                if ($accessRule.AccessControlType -eq 'Deny') {
                    $hasDenyAccessRule = $true
                    $folderUpdateAccess.RemoveAccessRule($accessRule)
                }
            }

            if ($hasDenyAccessRule) {
                Set-Acl $blockFileUpdate $folderUpdateAccess
            }
        }
    }

    function Remove-RegistryItems {
        param (
            [string[]]$Paths
        )

        foreach ($Path in $Paths) {
            if (Test-Path $Path) {
                Remove-Item -Path $Path -Recurse -Force
            }
        }
    }

    function Remove-FilesAndFolders {
        param(
            [string[]]$paths
        )

        foreach ($path in $paths) {
            if (-not (Test-Path $path)) {
                continue
            }

            $attempts = 0
            $maxAttempts = 3

            do {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue

                $exists = Test-Path $path

                if ($exists -and $attempts -lt $maxAttempts) {
                    Start-Sleep -Seconds 1
                }

                $attempts++
            } while ($exists -and $attempts -lt $maxAttempts)
        }
    }

    $null = unlockFolder

    if (Test-Paths -Sp_exe) {
        Start-Process -FilePath "$spRoaming\Spotify.exe" -ArgumentList "/UNINSTALL", "/SILENT" -Wait
    }

    $pathsToRemove = @($spLocal, $spRoaming, "$env:TEMP\SpotifyUninstall.exe")

    Remove-FilesAndFolders -paths $pathsToRemove


    $list = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Spotify",
        "HKCU:\Software\Spotify",
        "HKCU:\Software\Microsoft\Internet Explorer\Low Rights\ElevationPolicy\{5C0D11B8-C5F6-4be3-AD2C-2B1A3EB94AB6}",
        "HKCU:\Software\Microsoft\Internet Explorer\Low Rights\DragDrop\{5C0D11B8-C5F6-4be3-AD2C-2B1A3EB94AB6}"
    )

    $keys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\Spotify Web Helper",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\Spotify"
    )

    Remove-RegistryItems -Paths $keys
    Remove-RegistryItems -Paths $list

}


function BlockUpdate {

    Kill-Spotify

    # Get Spotify version
    $spotifyexe = "$spRoaming\Spotify.exe"
    $currentVersion = (Get-Item $spotifyexe).VersionInfo.FileVersion
    $thresholdVersion = [version]"1.2.70.404"
    $installedVersion = [version]$currentVersion

    # Determine which file to patch based on version
    if ($installedVersion -ge $thresholdVersion) {
        # Patch Spotify.dll for version >= 1.2.70.404
        $targetFile = "$spRoaming\Spotify.dll"
        
        # Define backup files for new version
        $backupDll = Join-Path $env:APPDATA 'Spotify\Spotify_dll.bak'
        $backupExe = Join-Path $env:APPDATA 'Spotify\Spotify_exe.bak'
        $backupElf = Join-Path $env:APPDATA 'Spotify\chrome_elf.bak'
        
        # Check if backups exist (meaning patch is already applied)
        if ((Test-Path $backupDll) -and (Test-Path $backupExe) -and (Test-Path $backupElf)) {
            Write-Text -txt "Spotify updates are already blocked" -e
            
            $options = @{
                "question"    = "Do you want to unlock updates?"
                "answer"      = @("Yes", "No")
                "description" = @("Unlock native Spotify client updates", "Continue to block native Spotify updates")
            }
            $ch = Get-UserChoice -o $options
            
            if ($ch -eq 0) {
                # Restore from backups
                Remove-Item "$spRoaming\Spotify.dll" -Force -ErrorAction SilentlyContinue
                Remove-Item "$spRoaming\Spotify.exe" -Force -ErrorAction SilentlyContinue
                Remove-Item "$spRoaming\chrome_elf.dll" -Force -ErrorAction SilentlyContinue
                
                Rename-Item -Path $backupDll -NewName "$spRoaming\Spotify.dll"
                Rename-Item -Path $backupExe -NewName "$spRoaming\Spotify.exe"
                Rename-Item -Path $backupElf -NewName "$spRoaming\chrome_elf.dll"
                
                Write-Text -txt "Updates unlocked" -e
                return
            }
            if ($ch -eq 1) {
                Write-Text -txt "Updates remained blocked" -e
                return
            }
        }
        
        # Check if target files exist
        if (-not (Test-Path $targetFile)) {
            Write-Text -txt "Failed to find Spotify.dll file for patching" -w -t
            return
        }
        if (-not (Test-Path "$spRoaming\Spotify.exe")) {
            Write-Text -txt "Failed to find Spotify.exe file for patching" -w -t
            return
        }
        if (-not (Test-Path "$spRoaming\chrome_elf.dll")) {
            Write-Text -txt "Failed to find chrome_elf.dll file for patching" -w -t
            return
        }
        
        # Create backups before patching
        Copy-Item "$spRoaming\Spotify.dll" $backupDll -Force
        Copy-Item "$spRoaming\Spotify.exe" $backupExe -Force
        Copy-Item "$spRoaming\chrome_elf.dll" $backupElf -Force
        
        # Apply patches for signature reset
        Reset-Dll-Sign -FilePath $targetFile
        $files = @("Spotify.dll", "Spotify.exe", "chrome_elf.dll")
        Remove-Signature-FromFiles $files
        
        # Apply URL patch to block updates in Spotify.dll
        $ANSI = [Text.Encoding]::GetEncoding(1251)
        $natPtrn = "(?<=desktop-update\/.)7(\/update)"
        $modPtrn = "(?<=desktop-update\/.)2(\/update)"
        
        $dllContent = [IO.File]::ReadAllText("$spRoaming\Spotify.dll", $ANSI)
        if ($dllContent -match $modPtrn) {
            $newDllContent = $dllContent -replace $modPtrn, '7/update'
            [IO.File]::WriteAllText("$spRoaming\Spotify.dll", $newDllContent, $ANSI)
            Write-Text -txt "Updates blocked" -f
        }
        else {
            Write-Text -txt "Failed to find update URL pattern in Spotify.dll" -w -t
        }
        return
    }
    else {
        # Patch Spotify.exe for version < 1.2.70.404
        $targetFile = "$spRoaming\Spotify.exe"
        $backupFile = Join-Path $env:APPDATA 'Spotify\Spotify.bak'
    }

    # Check if target file exists
    if (-not (Test-Path $targetFile)) {
        $fileName = Split-Path $targetFile -Leaf
        Write-Text -txt "Failed to find $fileName file for patching" -w -t
        return
    }

    $ANSI = [Text.Encoding]::GetEncoding(1251)
    $old = [IO.File]::ReadAllText($targetFile, $ANSI)
    $natPtrn = "(?<=desktop-update\/.)7(\/update)"
    $modPtrn = "(?<=desktop-update\/.)2(\/update)"

    if ($old -match $natPtrn) {
        Write-Text -txt "Spotify updates are already blocked" -e
        if (Test-Path -Path $backupFile) {
            $options = @{
                "question"    = "Do you want to unlock updates?"
                "answer"      = @("Yes", "No")
                "description" = @("Unlock native Spotify client updates", "Continue to block native Spotify updates")
            }
            $ch = Get-UserChoice -o $options
            if ($ch -eq 0) {   
                Remove-item $targetFile -Force
                Rename-Item -path $backupFile -NewName $targetFile
                Write-Text -txt "Updates unlocked" -e
                return
            }
            if ($ch -eq 1) { 
                Write-Text -txt "Updates remained blocked" -e
                return
            }
        }

        Write-Warning "Failed to find backup file, to unlock updates, reinstall Spotify manually"
        return
    }
    elseif ($old -match $modPtrn) {
        copy-Item $targetFile $backupFile
        $new = $old -replace $modPtrn, '7/update'
        [IO.File]::WriteAllText($targetFile, $new, $ANSI)
        $fileName = Split-Path $targetFile -Leaf
        Write-Text -txt "Updates blocked" -f
    }
    else {
        Write-Text -txt "Failed to block updates" -w -t
    }

}

function Reset-Dll-Sign {
    param (
        [string]$FilePath
    )

    $TargetStringText = "Check failed: sep_pos != std::wstring::npos."

    $Patch_x64 = "B8 01 00 00 00 C3"

    $Patch_ARM64 = "20 00 80 52 C0 03 5F D6"

    $Patch_x64 = [byte[]]($Patch_x64 -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) })
    $Patch_ARM64 = [byte[]]($Patch_ARM64 -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) })

    $csharpCode = @"
using System;
using System.Collections.Generic;

public class ScannerCore {
    public static int FindBytes(byte[] data, byte[] pattern) {
        for (int i = 0; i < data.Length - pattern.Length; i++) {
            bool match = true;
            for (int j = 0; j < pattern.Length; j++) {
                if (data[i + j] != pattern[j]) { match = false; break; }
            }
            if (match) return i;
        }
        return -1;
    }

    public static List<int> FindXref_ARM64(byte[] data, ulong stringRVA, ulong sectionRVA, uint sectionRawPtr, uint sectionSize) {
        List<int> results = new List<int>();
        for (uint i = 0; i < sectionSize; i += 4) {
            uint fileOffset = sectionRawPtr + i;
            if (fileOffset + 8 > data.Length) break;
            uint inst1 = BitConverter.ToUInt32(data, (int)fileOffset);
            
            // ADRP
            if ((inst1 & 0x9F000000) == 0x90000000) {
                int rd = (int)(inst1 & 0x1F);
                long immLo = (inst1 >> 29) & 3;
                long immHi = (inst1 >> 5) & 0x7FFFF;
                long imm = (immHi << 2) | immLo;
                if ((imm & 0x100000) != 0) { imm |= unchecked((long)0xFFFFFFFFFFE00000); }
                imm = imm << 12; 
                ulong pc = sectionRVA + i;
                ulong pcPage = pc & 0xFFFFFFFFFFFFF000; 
                ulong page = (ulong)((long)pcPage + imm);

                uint inst2 = BitConverter.ToUInt32(data, (int)fileOffset + 4);
                // ADD
                if ((inst2 & 0xFF800000) == 0x91000000) {
                    int rn = (int)((inst2 >> 5) & 0x1F);
                    if (rn == rd) {
                        long imm12 = (inst2 >> 10) & 0xFFF;
                        ulong target = page + (ulong)imm12;
                        if (target == stringRVA) { results.Add((int)fileOffset); }
                    }
                }
            }
        }
        return results;
    }

    public static int FindStart(byte[] data, int startOffset, bool isArm) {
        int step = isArm ? 4 : 1;
        if (isArm && (startOffset % 4 != 0)) { startOffset -= (startOffset % 4); }

        for (int i = startOffset; i > 0; i -= step) {
            if (isArm) {
                if (i < 4) break;
                uint currInst = BitConverter.ToUInt32(data, i);
                // ARM64 Prologue: STP X29, X30, [SP, -imm]! -> FD 7B .. A9
                if ((currInst & 0xFF00FFFF) == 0xA9007BFD) { return i; }
            } else {
                // x64 Prologue: Padding 0xCC
                if (data[i] != 0xCC && data[i-1] == 0xCC) return i;
            }
            if (startOffset - i > 20000) break; 
        }
        return 0;
    }
}
"@

    if (-not ([System.Management.Automation.PSTypeName]'ScannerCore').Type) {
        Add-Type -TypeDefinition $csharpCode
    }
    
    Write-Verbose "Loading file: $FilePath"
    if (-not (Test-Path $FilePath)) { 
        Write-Warning "File Spotify.dll not found"
        Stop-Script
    }
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)

    try {
        $e_lfanew = [BitConverter]::ToInt32($bytes, 0x3C)
        $Machine = [BitConverter]::ToUInt16($bytes, $e_lfanew + 4)
        $IsArm64 = $false
        $ArchName = "Unknown"
        
        if ($Machine -eq 0x8664) { $ArchName = "x64"; $IsArm64 = $false }
        elseif ($Machine -eq 0xAA64) { $ArchName = "ARM64"; $IsArm64 = $true }
        else { 
            Write-Warning "Architecture not supported for patching Spotify.dll"
            Stop-Script
        }

        Write-Verbose "Architecture: $ArchName"

        $NumberOfSections = [BitConverter]::ToUInt16($bytes, $e_lfanew + 0x06)
        $SizeOfOptionalHeader = [BitConverter]::ToUInt16($bytes, $e_lfanew + 0x14)
        $SectionTableStart = $e_lfanew + 0x18 + $SizeOfOptionalHeader
        
        $Sections = @(); $CodeSection = $null
        for ($i = 0; $i -lt $NumberOfSections; $i++) {
            $secEntry = $SectionTableStart + ($i * 40)
            $VA = [BitConverter]::ToUInt32($bytes, $secEntry + 12)
            $RawSize = [BitConverter]::ToUInt32($bytes, $secEntry + 16)
            $RawPtr = [BitConverter]::ToUInt32($bytes, $secEntry + 20)
            $Chars = [BitConverter]::ToUInt32($bytes, $secEntry + 36)
            $SecObj = [PSCustomObject]@{ VA = $VA; RawPtr = $RawPtr; RawSize = $RawSize }
            $Sections += $SecObj
            if (($Chars -band 0x20) -ne 0 -and $CodeSection -eq $null) { $CodeSection = $SecObj }
        }
    }
    catch { 
        Write-Warning "PE Error in Spotify.dll"
        Stop-Script
    }

    function Get-RVA($FileOffset) {
        foreach ($sec in $Sections) {
            if ($FileOffset -ge $sec.RawPtr -and $FileOffset -lt ($sec.RawPtr + $sec.RawSize)) {
                return ($FileOffset - $sec.RawPtr) + $sec.VA
            }
        }
        return 0
    }

    Write-Verbose "Searching for function..."
    $StringBytes = [System.Text.Encoding]::ASCII.GetBytes($TargetStringText)
    $StringOffset = [ScannerCore]::FindBytes($bytes, $StringBytes)
    if ($StringOffset -eq -1) { 
        Write-Warning "String not found in Spotify.dll"
        Stop-Script
    }
    $StringRVA = Get-RVA $StringOffset

    $PatchOffset = 0
    if (-not $IsArm64) {
        $RawStart = $CodeSection.RawPtr; $RawEnd = $RawStart + $CodeSection.RawSize
        for ($i = $RawStart; $i -lt $RawEnd; $i++) {
            if ($bytes[$i] -eq 0x48 -and $bytes[$i + 1] -eq 0x8D -and $bytes[$i + 2] -eq 0x15) {
                $Rel = [BitConverter]::ToInt32($bytes, $i + 3)
                $Target = (Get-RVA $i) + 7 + $Rel
                if ($Target -eq $StringRVA) {
                    $PatchOffset = [ScannerCore]::FindStart($bytes, $i, $false); break
                }
            }
        }
    }
    else {
        $Results = [ScannerCore]::FindXref_ARM64($bytes, [uint64]$StringRVA, [uint64]$CodeSection.VA, [uint32]$CodeSection.RawPtr, [uint32]$CodeSection.RawSize)
        if ($Results.Count -gt 0) {
            $PatchOffset = [ScannerCore]::FindStart($bytes, $Results[0], $true)
        }
    }

    if ($PatchOffset -eq 0) { 
        Write-Warning "Function not found in Spotify.dll"
        Stop-Script
    }

    $BytesToWrite = if ($IsArm64) { $Patch_ARM64 } else { $Patch_x64 }

    $CurrentBytes = @(); for ($i = 0; $i -lt $BytesToWrite.Length; $i++) { $CurrentBytes += $bytes[$PatchOffset + $i] }
    $FoundHex = ($CurrentBytes | ForEach-Object { $_.ToString("X2") }) -join " "
    Write-Verbose "Found (Offset: 0x$($PatchOffset.ToString("X"))): $FoundHex"

    if ($CurrentBytes[0] -eq $BytesToWrite[0] -and $CurrentBytes[$BytesToWrite.Length - 1] -eq $BytesToWrite[$BytesToWrite.Length - 1]) {
        Write-Warning "File Spotify.dll already patched"
        return
    }

    Write-Verbose "Applying patch..."
    for ($i = 0; $i -lt $BytesToWrite.Length; $i++) { $bytes[$PatchOffset + $i] = $BytesToWrite[$i] }

    try {
        [System.IO.File]::WriteAllBytes($FilePath, $bytes)
        Write-Verbose "Success"
    }
    catch { 
        Write-Warning "Write error in Spotify.dll $($_.Exception.Message)" 
        Stop-Script
    }
}

function Get-PEArchitectureOffsets {
    param(
        [byte[]]$bytes,
        [int]$fileHeaderOffset
    )
    $machineType = [System.BitConverter]::ToUInt16($bytes, $fileHeaderOffset)
    $result = @{ Architecture = $null; DataDirectoryOffset = 0 }
    switch ($machineType) {
        0x8664 { $result.Architecture = 'x64'; $result.DataDirectoryOffset = 112 }
        0xAA64 { $result.Architecture = 'ARM64'; $result.DataDirectoryOffset = 112 }
        0x014c { $result.Architecture = 'x86'; $result.DataDirectoryOffset = 96 }
        default { $result.Architecture = 'Unknown'; $result.DataDirectoryOffset = $null }
    }
    $result.MachineType = $machineType
    return $result
}

function Remove-Sign([string]$filePath) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $peHeaderOffset = [System.BitConverter]::ToUInt32($bytes, 0x3C)
        if ($bytes[$peHeaderOffset] -ne 0x50 -or $bytes[$peHeaderOffset + 1] -ne 0x45) {
            Write-Warning "File '$(Split-Path $filePath -Leaf)' is not a valid PE file."
            return $false
        }
        $fileHeaderOffset = $peHeaderOffset + 4
        $optionalHeaderOffset = $fileHeaderOffset + 20
        $archInfo = Get-PEArchitectureOffsets -bytes $bytes -fileHeaderOffset $fileHeaderOffset
        if ($archInfo.DataDirectoryOffset -eq $null) {
            Write-Warning "Unsupported architecture type ($($archInfo.MachineType.ToString('X'))) in file '$(Split-Path $filePath -Leaf)'."
            return $false
        }
        $dataDirectoryOffsetWithinOptionalHeader = $archInfo.DataDirectoryOffset
        $securityDirectoryIndex = 4
        $certificateTableEntryOffset = $optionalHeaderOffset + $dataDirectoryOffsetWithinOptionalHeader + ($securityDirectoryIndex * 8)
        if ($certificateTableEntryOffset + 8 -gt $bytes.Length) {
            Write-Warning "Could not find Data Directory in file '$(Split-Path $filePath -Leaf)'. Header is corrupted or has non-standard format."
            return $false
        }
        $rva = [System.BitConverter]::ToUInt32($bytes, $certificateTableEntryOffset)
        $size = [System.BitConverter]::ToUInt32($bytes, $certificateTableEntryOffset + 4)
        if ($rva -eq 0 -and $size -eq 0) {
            Write-Host "Signature in file '$(Split-Path $filePath -Leaf)' is already absent." -ForegroundColor Yellow
            return $true
        }
        for ($i = 0; $i -lt 8; $i++) {
            $bytes[$certificateTableEntryOffset + $i] = 0
        }
        [System.IO.File]::WriteAllBytes($filePath, $bytes)
        return $true
    }
    catch {
        Write-Error "Error processing file '$filePath': $_"
        return $false
    }
}

function Remove-Signature-FromFiles([string[]]$fileNames) {
    foreach ($fileName in $fileNames) {
        $fullPath = Join-Path -Path $spRoaming -ChildPath $fileName
        if (-not (Test-Path $fullPath)) {
            Write-Error "File not found: $fullPath"
            Write-Host ($lang).StopScript
            Pause
            Exit
        }
        try {
            Write-Verbose "Processing file: $fileName"
            if (Remove-Sign -filePath $fullPath) {
                Write-Verbose "  -> Signature entry successfully zeroed."
            }
        }
        catch {
            Write-Error "Failed to process file '$fileName': $_"
            Write-Host ($lang).StopScript
            Pause
            Exit
        }
    }
}



Write-Text -txt 'Rollback Spotify' -f -c 'DarkGreen'
Write-Text -txt '----------------' -e -c 'DarkGreen' 

$spLocal = Join-Path $env:LOCALAPPDATA 'Spotify'
$spRoaming = Join-Path $env:APPDATA 'Spotify'
$psv = $PSVersionTable.PSVersion.major

Kill-Spotify

UninstallSpMs

if (Test-Paths -Sp_exe ) {

    if (!($uninstall)) {
        $offline = (Get-Item "$spRoaming\Spotify.exe").VersionInfo.FileVersion

        $options = @{
            "question"    = "Found version $($offline) installed on your system. Remove it?"
            "answer"      = @("Yes", "No")
            "description" = @("Complete removal of Spotify desktop", "Continue using the current version")
        }
        $ch = Get-UserChoice -o $options
    }

    if ($ch -eq 0 -or $uninstall) {
        UninstallSp
    }
}

if (!(Test-Paths -Sp_exe)) {

    # add Tls12
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12;

    $jsonUrl = "https://raw.githubusercontent.com/LoaderSpot/LoaderSpot/refs/heads/main/versions.json"

    $jsonContent = Invoke-Method -Method 'rest' -url $jsonUrl

    $resp = Version-Select -c $jsonContent
    $fullversion = $resp.name.fullversion
    $index = $fullversion.IndexOf(".g")
    $part = $fullversion.Substring(0, $index)

    Write-Text "Download version " -n
    Write-Host "$($part)-[$($resp.arch)]" -ForegroundColor Green -NoNewline
    Write-host " ..."

    Invoke-Method -Method 'download' -url $resp.link -namefile "SpotifySetup.exe"
  
    $temp = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'SpotifySetup.exe'

    # Silent installation of the client
    Write-Text "Install Spotify ..." -f
    Start-Process -Wait -FilePath $temp  -ArgumentList "/extract $spRoaming"


    $shell = New-Object -ComObject WScript.Shell
    $targetPath = "$spRoaming\Spotify.exe"

    # Creating a desktop shortcut
    $shortcut = $shell.CreateShortcut([Environment]::GetFolderPath("Desktop") + "\Spotify.lnk")
    $shortcut.TargetPath = $targetPath
    $shortcut.Save()

    # Creating a shortcut in the Start menu
    $shortcut = $shell.CreateShortcut([Environment]::GetFolderPath("StartMenu") + "\Programs\Spotify.lnk")
    $shortcut.TargetPath = $targetPath
    $shortcut.Save()

    # Creating necessary paths in the registry
    New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -Name 'Spotify' -Force | Out-Null
    $registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Spotify'
    Set-ItemProperty -Path $registryPath -Name 'DisplayIcon' -Value "$spRoaming\Spotify.exe,0" -Type String
    Set-ItemProperty -Path $registryPath -Name 'DisplayName' -Value 'Spotify' -Type String
    Set-ItemProperty -Path $registryPath -Name 'DisplayVersion' -Value $fullversion -Type String
    Set-ItemProperty -Path $registryPath -Name 'Publisher' -Value 'Spotify AB' -Type String
    Set-ItemProperty -Path $registryPath -Name 'UninstallString' -Value "$spRoaming\Spotify.exe /uninstall" -Type ExpandString
    Set-ItemProperty -Path $registryPath -Name 'URLInfoAbout' -Value 'https://www.spotify.com' -Type String
    
    if (Test-Paths -Sp_exeTemp) {
        Remove-Item $temp -Force 
    } 
}
if (!($not_block)) {
    BlockUpdate
}
