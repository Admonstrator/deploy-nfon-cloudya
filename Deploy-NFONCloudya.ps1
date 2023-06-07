#requires -version 2

<#
.SYNOPSIS
This script tries to install the newest version of Cloudya Desktop by NFON from the official website.
.DESCRIPTION
This script tries to install the newest version of Cloudya Desktop by NFON from the official website.
.PARAMETER Action
The action to perform. Possible values are "Install", "Uninstall", "Update" or "Detect".
.PARAMETER Autostart
Creates a shortcut in the autostart folder.
.PARAMETER DisableUpdateCheck
Disables the update check.
.PARAMETER EnableCRM
Enables the CRM integration.
.PARAMETER Help
Shows this help.
.INPUTS
None
.OUTPUTS
Just output on screen
.NOTES
Version:        1.2.0
Author:         info@singleton-factory.de
Creation Date:  2023-03-03
Purpose/Change: Initial version
  
.EXAMPLE
.\manage-nfon-cloudya.ps1 -Action Install -Autostart -EnableCRM -DisableUpdateCheck
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#----------------------------------------------------------[Declarations]----------------------------------------------------------
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Install", "Uninstall", "Update", "Detect")]
    [string]$Action,
    [switch]$Autostart = $false,
    [switch]$EnableCRM = $false,
    [switch]$Help = $false,
    [switch]$DisableUpdateCheck = $false
)

# Version of this script
$version = "1.2.0"

# Configuration
# Contains the URL with download links - will be scraped automatically for the latest version
$url = "https://www.nfon.com/de/service/downloads"
#-----------------------------------------------------------[Functions]------------------------------------------------------------
function GetDownloadURL {
    Log -Severity "Info" "Getting download URL ..."
    # Send a request to the website and get the response
    $response = Invoke-WebRequest $url -UseBasicParsing

    # Define the regex patterns to extract the download URLs and version numbers
    $regexDefault = 'https:\/\/cdn\.cloudya\.com\/cloudya-(\d\.\d\.\d)-win-msi\.zip'
    $regexCRM = 'https:\/\/cdn\.cloudya\.com\/cloudya-(\d\.\d\.\d)-crm-win-msi\.zip'

    # Search for the pattern in the response (without CRM)
    if ([regex]::IsMatch($response.Content, $regexDefault)) {
        $matchDefault = [regex]::Match($response.Content, $regexDefault)
        $urlDefault = $matchDefault.Value
        $versionDefault = $matchDefault.Groups[1].Value
    }
    else {
        throw "Failed to extract Cloudya Desktop App download URL or version number."
    }

    # Search for the pattern in the response (with CRM)
    if ([regex]::IsMatch($response.Content, $regexCRM)) {
        $matchCRM = [regex]::Match($response.Content, $regexCRM)
        $urlCRM = $matchCRM.Value
        $versionCRM = $matchCRM.Groups[1].Value
    }
    else {
        throw "Failed to extract Cloudya Desktop App CRM download URL or version number."
    }
   
    # Create a PSCustomObject with the extracted information
    return [PSCustomObject]@{
        URLDefault     = $urlDefault
        URLCRM         = $urlCRM
        versionDefault = $versionDefault
        versionCRM     = $versionCRM
    }
}

# Get a temporary file name
function GetTempFileName {
    $tempFile = [System.IO.Path]::GetTempFileName()
    return $tempFile
}

# Download the setup file
function DownloadSetupFile {
    # Get the download URL
    $url = GetDownloadURL
    if ($EnableCRM) {
        $url = $url.URLCRM
    }
    else {
        $url = $url.URLDefault
    }
    # Get the setup file name
    $setupFile = $tempFile

    # Download the setup file
    Log -Severity "Info" "Downloading setup file from $url ..."
    Start-BitsTransfer -Source $url -Destination $setupFile
    Log -Severity "Info" "Download was saved to $setupFile"
}

function Cleanup {
    # Remove the temporary file
    if (Test-Path $tempFile) {
        Remove-Item $tempFile
    }

    if (Test-Path $tempExtractFolder) {
        Remove-Item $tempExtractFolder -Recurse
    }
}

function CheckZipFile ($path) {
    # Check if the file is a zip file
    # Read the first four bytes of the file
    $bytes = [System.IO.File]::ReadAllBytes($path)[0..3]

    # Check if the first four bytes match the zip file header
    $isZip = $bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B -and $bytes[2] -eq 0x03 -and $bytes[3] -eq 0x04

    # Get result
    if ($isZip) {
        return $true
    }
    else {
        return $false
    }
}

function CheckIfInstalled {
    # Check if the program is installed
    $installed = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*Cloudya*" }
    
    $displayName = $installed.DisplayName
    $installLocation = $installed.InstallLocation
    $displayVersion = $installed.DisplayVersion
    $guid = $installed.PSChildName
    $installedCRM = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*CRM Connect*" }
    $installedCRMdisplayVersion = ($installedCRM.DisplayVersion -split "\s+")[0]
    $installedCRMAddins = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*CRM Connect Addins*" }
    $installedCRMAddinsDisplayVersion = $installedCRMAddins.displayVersion
    $installedCRMPlusAddins = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*CRM Connect Plus Addins*" }
    $installedCRMPlusAddinsDisplayVersion = $installedCRMPlusAddins.displayVersion
    $installedCRMQuietUninstallString = $installedCRM.QuietUninstallString
    $installedCRMAddinsGUID = $installedCRMAddins.PSChildName
    $installedCRMPlusAddinsGUID = $installedCRMPlusAddins.PSChildName
    # If CRM is installed, set the variable to true
    if ($installedCRM) {
        $installedCRMFound = $true
    }
    else {
        $installedCRMFound = $false
    }
    # Return the result
    return [PSCustomObject]@{
        DisplayName                 = $displayName
        InstallLocation             = $installLocation
        displayVersion              = $displayVersion
        GUID                        = $guid
        CRMdisplayVersion           = $installedCRMDisplayVersion
        CRMAddinsdisplayVersion     = $installedCRMAddinsDisplayVersion
        CRMPlusAddinsdisplayVersion = $installedCRMPlusAddinsDisplayVersion
        CRM                         = $installedCRMFound
        CRMQuietUninstallString     = $installedCRMQuietUninstallString
        CRMAddinsGUID               = $installedCRMAddinsGUID
        CRMConnctPlusAddinsGUID     = $installedCRMPlusAddinsGUID
    }
}
function Install($EnableCRM) {
    # Check if the program is already installed
    $installed = CheckIfInstalled
    if ($installed.DisplayName) {
        Log -Severity "Info" "Cloudya Desktop is already installed."
        return
    }
    else {
        # Download the setup file
        DownloadSetupFile($EnableCRM)

        # Check if the downloaded file is a zip file and extract it
        if ((CheckZipFile $tempFile) -eq $true) {
            Expand-Archive -Path $tempFile -DestinationPath $tempExtractFolder
            Log -Severity "Info" "Extracted to: $tempExtractFolder."
        }
        else {
            Log -Severity "Error" "Downloaded file is not a zip file. Program will exit."
            Log -Severity "Error" "Please check if the detected URL is correct."
            cleanup
            exit 1
        }

        # Get the setup file name
        $setupFile = Get-ChildItem -Path $tempExtractFolder -Filter "*.msi" -Recurse | Select-Object -First 1 -ExpandProperty FullName
        Log -Severity "Info" "Found setup file: $setupFile"
        if ($setupFile) {
            # Install the setup file
            Log -Severity "Info" "Starting installation process ..."
            Start-Process -FilePath msiexec.exe -ArgumentList "/i $setupFile /qn /norestart REBOOT=ReallySuppress" -Wait
            # Wait until crm.exe is not running
            Log -Severity "Info" "Waiting for crm.exe to finish ..."
            while ($null -ne (Get-Process -Name crm -ErrorAction SilentlyContinue)) {
                Start-Sleep 2
            }
            Log -Severity "Info" "Installation done."
        }
        else {
            Log -Severity "Error" "Setup file not found. Program will exit."
            cleanup
            exit 1
        }
        Log -Severity "Info" "Checking if installation was successful ..."
        $CloudyaInstalledApp = CheckIfInstalled
        if ($CloudyaInstalledApp.DisplayName) {
            Log -Severity "Info" "Installation was successful."
        }
        else {
            Log -Severity "Error" "Installation failed."
            return $false
        }
    }   
}

function Uninstall($App) {
    $displayName = $App.DisplayName
    $displayVersion = $App.DisplayVersion
    $GUID = $App.GUID
    $CRMQuietUninstallString = $App.CRMQuietUninstallString
    $CRMAddinsGUID = $App.CRMAddinsGUID
    $CRMPlusAddinsGUID = $App.CRMPlusAddinsGUID
    $installLocation = $App.InstallLocation

    # Check if any apps were found
    if (-not $displayName -and -not $displayVersion -and -not $GUID -and -not $CRMQuietUninstallString -and -not $CRMAddinsGUID -and -not $CRMPlusAddinsGUID) {
        Log -Severity "Info" "No apps found to uninstall."
        return
    }

    # Remove cloudya update control script
    if (Test-Path -Path "$installLocation\control-cloudya-update.ps1") {
        Remove-Item -Path "$installLocation\control-cloudya-update.ps1" -Force -ErrorAction SilentlyContinue
        Log -Severity "Info" "Update control disabled."
    }

    # Remove cloudya update control script autostart
    if (Test-Path -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cloudya Update Control.lnk") {
        Remove-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cloudya Update Control.lnk" -Force -ErrorAction SilentlyContinue
    }

    # Uninstall the setup msi file
    if ($GUID) {
        # Disable autostart
        Autostart $false
        Log -Severity "Info" "Uninstalling $displayName $displayVersion ..."
        # Stop Process cloudya.exe 
        Stop-Process -Name "cloudya" -Force -ErrorAction SilentlyContinue
        Start-Process -FilePath msiexec.exe -ArgumentList "/x $GUID /qn /norestart REBOOT=ReallySuppress" -Wait
    }

    # Uninstall CRM Connect
    if ($CRMQuietUninstallString) {
        Log -Severity "Info" "Uninstalling CRM Connect ..."
        # Stop Process crm.exe
        Stop-Process -Name "crm" -Force -ErrorAction SilentlyContinue
        Start-Process -FilePath cmd.exe -ArgumentList "/c $CRMQuietUninstallString" -Wait
    }

    # Uninstall CRM Connect Addins
    if ($CRMAddinsGUID) {
        Log -Severity "Info" "Uninstalling CRM Connect Addins ..."
        Start-Process -FilePath msiexec.exe -ArgumentList "/x $CRMAddinsGUID /qn /norestart REBOOT=ReallySuppress" -Wait
    }

    # Uninstall CRM Connect Plus Addins
    if ($CRMPlusAddinsGUID) {
        Log -Severity "Info" "Uninstalling CRM Connect Plus Addins ..."
        Start-Process -FilePath msiexec.exe -ArgumentList "/x $CRMPlusAddinsGUID /qn /norestart REBOOT=ReallySuppress" -Wait
    }

    # Waiting until crm.exe is not running
    Log -Severity "Info" "Waiting for crm.exe to finish ..."
    while ($null -ne (Get-Process -Name crm -ErrorAction SilentlyContinue)) {
        Start-Sleep 2
    }
}

function Detect {
    # Check if the program is already installed
    $installed = CheckIfInstalled
    if ($installed.DisplayName) {
        Log -Severity "Info" "Cloudya Desktop: $($installed.DisplayVersion)"
    }
    else {
        Log -Severity "Warn" "Cloudya Desktop: Not installed."
    }

    if ($installed.CRMdisplayVersion) {
        Log -Severity "Info" "CRM Connect: $($installed.CRMdisplayVersion)"
    }
    else {
        Log -Severity "Warn" "CRM Connect: Not installed."
    }

    if ($installed.CRMAddinsdisplayVersion) {
        Log -Severity "Info" "CRM Connect Addins: $($installed.CRMAddinsdisplayVersion)"
    }
    else {
        Log -Severity "Warn" "CRM Connect Addins: Not installed."
    }

    if ($installed.CRMPlusAddinsdisplayVersion) {
        Log -Severity "Info" "CRM Connect Plus Addins: $($installed.CRMPlusAddinsdisplayVersion)"
    }
    else {
        Log -Severity "Warn" "CRM Connect Plus Addins: Not installed."
    }
}

function ShowHelp {
    Log -Severity "Info" "Parameters:"
    Log -Severity "Info" "This script will download and install Cloudya Desktop."
    Log -Severity "Info" "It will also add Cloudya Desktop to the autostart."
    Log -Severity "Info" "If you want to uninstall Cloudya Desktop, run this script with the -Uninstall parameter."
    Log -Severity "Info" "If you want to install Cloudya Desktop, run this script with the -Install parameter."
    Log -Severity "Info" "If you want to enable CRM Connect, run this script with the -EnableCRM parameter."
    Log -Severity "Info" "If you want to add Cloudya Desktop to the autostart, run this script with the -Autostart parameter."
}
function Update {
    # Check if the program is already installed
    $installed = CheckIfInstalled

    # When Cloudya Desktop is not installed, exit
    if ($null -eq $installed.DisplayName) {
        Log -Severity "Error" "Cloudya Desktop is not installed."
        Log -Severity "Error" "Please install Cloudya Desktop first."
        Log -Severity "Error" "You can do this by running this script with the '-Action Install' parameter."
        return $false
    }
    
    # Get current version from website
    $currentVersion = GetDownloadURL
   
    # Print detected version
    Log -Severity "Info" "Installed version: $($installed.DisplayVersion)"
    Log -Severity "Info" "Current version: $($currentVersion.versionDefault)"
        
    # Compare versions
    if ([Version]$installed.DisplayVersion -lt [Version]$currentVersion.versionDefault) {
        Log -Severity "Info" "Cloudya Desktop is not up to date."
        Log -Severity "Info" "Updating Cloudya Desktop ..."

        # Detect if CRM Connect is installed
        if ($installed.CRMdisplayVersion) {
            Log -Severity "Info" "CRM Connect is installed."
        }
        else {
            Log -Severity "Info" "CRM Connect is not installed."
        }
    
        # Uninstall the setup msi file
        $uninstalled = Uninstall $installed
        if ($uninstalled) {
            Log -Severity "Info" "Uninstallation was successful."
        
            # Install the setup file
            if (Install($env:EnableCRM)) {
                Log -Severity "Info" "Update was successful."
                return $true
            }
            else {
                Log -Severity "Error" "Update failed."
                return $false
            }
        }
        else {
            Log -Severity "Error" "Uninstallation failed."
            return $false
        }
    }
    elseif ([Version]$installed.DisplayVersion -eq [Version]$currentVersion.versionDefault) {
        Log -Severity "Info" "Cloudya Desktop is already up to date."
        return
    }
    else {
        Log -Severity "Info" "Local version is higher than the current version."
        return
    }
}

function Autostart([bool]$trueOrFalse) {
    if ($trueOrFalse -eq $false) {
        # Find shortcut in startup folder
        if ($trueOrFalse -eq $false) {
            Log -Severity "Info" "Disabling autostart ..."
            # Find shortcut in startup folder
            $shortcut = Get-ChildItem -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\" -Filter "Cloudya.lnk"
            if ($shortcut) {
                try {
                    Remove-Item -Path $shortcut.FullName
                    Log -Severity "Info" "Autostart disabled."
                }
                catch {
                    Log -Severity "Error" "Could not disable autostart. $($_.Exception.Message)"
                }
            
            }
            else {
                Log -Severity "Warn" "Autostart was already disabled."
            }
        }
    }
    elseif ($trueOrFalse -eq $true) {
        Log -Severity "Info" "Enabling autostart ..."
        # Get Install location
        $installed = CheckIfInstalled
        if ($installed) {
            $installLocation = $installed.InstallLocation

            # Search for Cloudya.exe in all subfolders
            $CloudyaDesktopExe = Get-ChildItem -Path $installLocation -Recurse -Filter "Cloudya.exe" | Select-Object -First 1
            if ($CloudyaDesktopExe) {
                $CloudyaDesktopExe = $CloudyaDesktopExe.FullName
            
                # Create shortcut
                try {
                    $WshShell = New-Object -ComObject "WScript.Shell"
                    $Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cloudya.lnk")
                    $Shortcut.TargetPath = "$CloudyaDesktopExe"
                    $Shortcut.Save()
                    Log -Severity "Info" "Autostart enabled."
                }
                # If access is denied, log error
                catch {
                    if ($_.Exception.GetType().FullName -eq "System.UnauthorizedAccessException") {
                        Log -Severity "Error" "Failed to create startup shortcut: Access to the global startup folder was denied."
                    }
                    else {
                        Log -Severity "Error" "Failed to create startup shortcut: $($_.Exception.Message)"
                    }
                }
            }
            # If Cloudya.exe was not found, log error
            else {
                Log -Severity "Error" "Cloudya.exe was not found in the installation folder."
            }
        }
        else {
            Log -Severity "Error" "Cloudya Desktop is not installed."
            Log -Severity "Error" "Please install Cloudya Desktop first."
            Log -Severity "Error" "You can do this by running this script with the '-Action Install' parameter."
          
        }

    }
}

function DisableUpdateCheck([bool]$trueOrFalse) {
    $CloudyaInstallLocation = (CheckIfInstalled).InstallLocation
    if ($null -eq $CloudyaInstallLocation) {
        Log -Severity "Error" "Cloudya Desktop is not installed."
        Log -Severity "Error" "Please install Cloudya Desktop first."
        Log -Severity "Error" "You can do this by running this script with the '-Action Install' parameter."
        return $false
    } 
    # Update-Check-control script
    $UpdateControlScript = @"
# This script was created by the Cloudya All-in-One Desktop Manager by Aaron Viehl (Singleton Factory GmbH).
# It prevents Cloudya Desktop from updating itself.
# It is referenced in the users auto start folder.

# Change this value to `$true to enable updates.
`$UpdatesEnabled = `$$trueOrFalse

`$filePath = `"`${env:APPDATA}`\cloudya-desktop\Cloudya-local-settings.json`"

if (`$UpdatesEnabled -eq `$true) {
    if (Test-Path `$filePath) {
        Remove-Item `$filePath
    }
} else {
    `$content = '{ `"handle-updates`": `"IGNORE`" }'
    New-Item -ItemType File -Path `$filePath -Force | Out-Null
    Set-Content -Path `$filePath -Value `$content    
}    
"@

    $UpdateControlScriptPath = "$CloudyaInstallLocation\control-cloudya-update.ps1"
    try {
        New-Item -ItemType File -Path $UpdateControlScriptPath -Force | Out-Null
        Set-Content -Path $UpdateControlScriptPath -Value $UpdateControlScript
        if ($trueOrFalse) {
            Log -Severity "Info" "Updates are now enabled."
        }
        else {
            Log -Severity "Info" "Updates are now disabled."
        }
    }
    catch {
        Log -Severity "Error" "Failed to create update control script: $($_.Exception.Message)"
        throw
    }

    # Create auto start shortcut for update control script
    $WshShell = New-Object -ComObject "WScript.Shell"
    $Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cloudya Update Control.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$CloudyaInstallLocation\control-cloudya-update.ps1`""
    $Shortcut.WindowStyle = 0
    $Shortcut.Save()
}

function Log {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Severity,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $date = Get-Date -Format "yyyy-MM-dd"
    $time = Get-Date -Format "HH:mm:ss"

    switch ($Severity) {
        "INFO" {
            $color = "Green"
        }
        "WARN" {
            $color = "Yellow"
        }
        "ERROR" {
            $color = "Red"
        }
    }
    $severityText = "[$Severity]"
    $severityText = "[$Severity]".ToUpper()
    $dateTimeText = "$date $time"
    $messageText = $Message

    $maxSeverityLength = 7
    $maxDateTimeLength = 19

    $formattedSeverity = $severityText.PadRight($maxSeverityLength)
    $formattedDateTime = $dateTimeText.PadRight($maxDateTimeLength)
    $formattedMessage = $messageText

    $logMessage = "$formattedSeverity $formattedDateTime $formattedMessage"
    Write-Host $logMessage -ForegroundColor $color
}

function Header {
    Log -Severity "Info" "Cloudya All-in-One Desktop Manager by Aaron Viehl (Singleton Factory GmbH)"
    Log -Severity "Info" "Your toolkit for a better NFON Cloudya experience."
    Log -Severity "Info" "Version: $Version"
    Log -Severity "Info" "======================="
}
#-----------------------------------------------------------[Main Code]------------------------------------------------------------#
# Show header
Header

# Get a temporary file name
$tempFile = GetTempFileName
$tempFile = $tempFile + ".zip"
$tempExtractFolder = $tempFile + ".extract"

switch ($Action) {
    "Install" { 
        # Install the program
        if ($EnableCRM) {
            Log -Severity "Info" "Installing Cloudya Desktop + CRM Connect..."
        }
        else {
            Log -Severity "Info" "Installing Cloudya Desktop ..."
        }
        Install($EnableCRM)
        Detect
    }
    "Uninstall" {
        $CloudyaInstalledApp = CheckIfInstalled
        # Check if the program is installed
        Uninstall($CloudyaInstalledApp)
        Detect
    }
    "Update" {
        Log -Severity "Info" "Checking for updates ..."
        Update
    }
    "Detect" {
        Detect
    }
    "Help" {
        ShowHelp
    }
    "Default" {
        ShowHelp
    }
}

# Check if autostart parameter is set
if ($PSBoundParameters.ContainsKey('Autostart') -and $Autostart) {
    Autostart $true
}
elseif ($PSBoundParameters.ContainsKey('Autostart') -and !$Autostart) {
    Autostart $false
}

# Check if update check parameter is set
if ($PSBoundParameters.ContainsKey('DisableUpdateCheck') -and $DisableUpdateCheck) {
    DisableUpdateCheck $false
}
elseif ($PSBoundParameters.ContainsKey('DisableUpdateCheck') -and !$DisableUpdateCheck) {
    DisableUpdateCheck $true
}

# Cleanup all temporary files
Cleanup
exit