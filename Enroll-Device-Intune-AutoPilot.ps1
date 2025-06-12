# Dave Herrell Intune AutoPilot Enrollment Script
# Use this script to enroll a device with Intune's AutPilot.  After device is enrolled, you'll be able to see the device under Windows Autopilot Devices: Windows Autopilot Devices. 

# Enforce TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set execution policy for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

# Install NuGet provider if missing.  You may need to manualy click yes. 
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Host "Installing NuGet package provider..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

# Install PowerShellGet if needed
if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
    Write-Host "Installing PowerShellGet module..." -ForegroundColor Yellow
    Install-Module -Name PowerShellGet -Force
}

# Trust PSGallery if prompted
if (-not (Get-PSRepository | Where-Object { $_.Name -eq "PSGallery" -and $_.InstallationPolicy -eq "Trusted" })) {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
}

# Install the Autopilot info script
Write-Host "Installing Get-WindowsAutopilotInfo script..." -ForegroundColor Cyan
Install-Script -Name Get-WindowsAutopilotInfo -Force

# Run the script and upload to Intune Autopilot.  This will create a pop-up for you to log-in to your MS365 account.  This account must have Intune Admin or Global Admin rights.
Write-Host "Running Get-WindowsAutopilotInfo -Online..." -ForegroundColor Green
Get-WindowsAutopilotInfo -Online
