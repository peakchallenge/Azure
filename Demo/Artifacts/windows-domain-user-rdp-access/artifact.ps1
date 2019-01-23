param
(
    [Parameter(Mandatory = $true)]
    [string] $allowRDP
)

$logfilePATH = "C:\Temp"
$logfile = "artifactlog.txt"

if(!(Test-Path -Path $logfilePATH )){
    New-Item -ItemType directory -Path $logfilePATH
}

# Create the log file, make sure c:\temp already exists
if(!(Test-Path "$logfilePATH\$logfile")){
    $file = Join-Path -Path (Resolve-Path "$logfilePATH") -ChildPath "$logfile"
    New-Item $file -type file | Out-Null
} else {
    $file = Join-Path -Path (Resolve-Path "$logfilePATH") -ChildPath "$logfile"
}

# Add content to the log file, can add these debugging statements throughout your powershell to identify which line is hanging
Add-Content -Path $file -Value "Beginning Script Process - starting log after Params"


###################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Ensure we set the working directory to that of the script.
Push-Location $PSScriptRoot

###################################################################################################
#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "ERROR: $message" -ForegroundColor Red
    }
    
    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    Write-Host 'Artifact failed to apply.'
    Add-Content -Path $file -Value "Artifact failed to apply."
    exit -1
}

###################################################################################################
#
# Functions used in this script.
#


###################################################################################################
#
# Main execution block.
#

try
{
    if ($PSVersionTable.PSVersion.Major -lt 3)
    {
        throw "The current version of PowerShell is $($PSVersionTable.PSVersion.Major). Prior to running this artifact, ensure you have PowerShell 3 or higher installed."
    }

    write-host "Attempting to add Users to RDP Group."
    
    foreach ($allowRDPUser in $allowRDP){
        Add-Content -Path $file -Value "Attempting to add Users to RDP Group - $allowRDPUser"
        #Add-LocalGroupMember -Group "Remote Desktop Users" -Member "$allowRDPUser"
        write-host "$allowRDPUser"
        NET LOCALGROUP "Remote Desktop Users" "$allowRDPUser" /ADD
    }

    Add-Content -Path $file -Value "Entering Main Script Block (try) - Artifact Applied Successfully"
    Write-Host 'Artifact applied successfully.'
}
finally
{
    Pop-Location
}
