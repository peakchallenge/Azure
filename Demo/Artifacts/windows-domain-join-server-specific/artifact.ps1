param
(
    [Parameter(Mandatory = $true)]
    [string] $DomainToJoin,
    
    [Parameter(Mandatory = $true)]
    [string] $OUPath,
    
    [Parameter(Mandatory = $true)]
    [string] $DomainAdminUsername,

    [Parameter(Mandatory = $true)]
    [string] $DomainAdminPassword,
    
    [Parameter(Mandatory = $true)]
    [string] $DomainServerJoin
)

$logfilePATH = "C:\Temp"

if(!(Test-Path -Path $logfilePATH )){
    New-Item -ItemType directory -Path $logfilePATH
}

# Create the log file, make sure c:\temp already exists
$file = Join-Path -Path (Resolve-Path "c:\Temp\") -ChildPath "artifactlog.txt"
sleep 10
New-Item $file -type file | Out-Null
sleep 10

# Add content to the log file, can add these debugging statements throughout your powershell to identify which line is hanging
Add-Content -Path $file -Value "Beginning Script Process - starting log after Params"
sleep 10


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

function Join-Domain 
{
    #[CmdletBinding()]
    param
    (
        [string] $DomainName,
        [string] $OUPath,
        [string] $User,
        [securestring] $Password,
        [string] $DomainServer
    )
    	sleep 10
	Add-Content -Path $file -Value "Entering Join-Domain Function, logging after Params: $DomainName,$OUPath,$User,$Password,$DomainServer"
	
    if ((Get-WmiObject Win32_ComputerSystem).Domain -eq $DomainName)
    {
    	sleep 10
        Add-Content -Path $file -Value "Server already Joined to domain!"
	sleep 5
        Write-Host "Computer $($Env:COMPUTERNAME) is already joined to domain $DomainName."
    }
    else
    {
    	sleep 10
    	Add-Content -Path $file -Value "Entering First ELSE clause: $DomainName,$User,$Password,$DomainServer"
	sleep 5
        $credential = New-Object System.Management.Automation.PSCredential($User, $Password)
        
        if ($OUPath)
        {
	    sleep 10
	    Add-Content -Path $file -Value "Entering IF when OU is provided: $DomainName,$OUPath,$User,$Password,$DomainServer"
	    sleep 5
            [Microsoft.PowerShell.Commands.ComputerChangeInfo]$computerChangeInfo = Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential $credential -Server $DomainServerJoin -Force -PassThru
        }
        else
        {
	    sleep 10
	    Add-Content -Path $file -Value "Entering IF when OU is NOT provided: $DomainName,$User,$Password,$DomainServer"
	    sleep 5
            [Microsoft.PowerShell.Commands.ComputerChangeInfo]$computerChangeInfo = Add-Computer -DomainName $DomainName -Credential $credential -Server $DomainServerJoin -Force -PassThru
        }
        
        if (-not $computerChangeInfo.HasSucceeded)
        {
            throw "Failed to join computer $($Env:COMPUTERNAME) to domain $DomainName."
	    sleep 5
	    write-host "Computer $($Env:COMPUTERNAME) failed to joined domain $DomainName."
	    sleep 10
	    Add-Content -Path $file -Value "Logging if AD Join Failed - $DomainName,$OUPath,$User,$Password,$DomainServer"
        }
	sleep 10
        Add-Content -Path $file -Value "Logging if AD Join was Successful - $DomainName,$OUPath,$User,$Password,$DomainServer"
	sleep 5
        write-host "Computer $($Env:COMPUTERNAME) successfully joined domain $DomainName."
    }
}

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

    write-host "Attempting to join computer $($Env:COMPUTERNAME) to domain $DomainToJoin."
    sleep 10
    Add-Content -Path $file -Value "Entering Main Script Block (try) function - $DomainToJoin,$OUPath,$DomainAdminUsername,$DomainAdminPassword,$DomainServerJoin"
    sleep 5
    $securePass = ConvertTo-SecureString "$DomainAdminPassword" -AsPlainText -Force
    sleep 10
    Join-Domain -DomainName $DomainToJoin -OUPath "$OUPath" -User $DomainAdminUsername -Password $securePass -DomainServer $DomainServerJoin 
    sleep 10
    Add-Content -Path $file -Value "Entering Main Script Block (try) - Artifact Applied Successfully"
    sleep 5
    Write-Host 'Artifact applied successfully.'
}
finally
{
    Pop-Location
}
