# This script runs nicely along with Jira automation and Microsoft Azure runbooks to help automate Entra ID user disabling. 
# For more information and a step-by-step guide to set this up with Jira and Azure please see: https://www.daveherrell.com/jira-cloud-disabling-entra-id-user-accounts-via-automation-and-microsoft-runbook/

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$DisableDate,
    
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^([01]?[0-9]|2[0-3]):[0-5][0-9]$')]
    [string]$DisableTime,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
)

# Import required modules
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users

# Function to write formatted log messages
function Write-Log {
    param($Message)
    $logMessage = "{0} - {1}" -f (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"), $Message
    Write-Output $logMessage
}

try {
    Write-Log "Script started - Target user: $UserPrincipalName"
    Write-Log "Force mode: $Force"
    
    # Get current time in UTC
    $currentDateTime = (Get-Date).ToUniversalTime()
    Write-Log "Current UTC time: $($currentDateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    
    # Convert input date and time to UTC DateTime object
    try {
        # Create DateTime object and specify it's in UTC
        $disableDateTime = [datetime]::ParseExact(
            "$DisableDate $DisableTime", 
            "yyyy-MM-dd HH:mm", 
            [System.Globalization.CultureInfo]::InvariantCulture
        ).ToUniversalTime()
        
        Write-Log "Scheduled disable time (UTC): $($disableDateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        
        # Show time difference
        $timeDifference = $disableDateTime - $currentDateTime
        Write-Log "Time until disable: $($timeDifference.TotalMinutes) minutes"
    }
    catch {
        throw "Invalid date/time format. Use YYYY-MM-DD for date and HH:mm (24-hour) for time in UTC."
    }
    
    # Validate disable date is in the future with detailed message
    if ($disableDateTime -lt $currentDateTime) {
        $errorDetail = "Current time (UTC): $($currentDateTime.ToString('yyyy-MM-dd HH:mm'))" +
                      "`nRequested disable time (UTC): $($disableDateTime.ToString('yyyy-MM-dd HH:mm'))" +
                      "`nThe disable time must be set to a future date/time."
        throw $errorDetail
    }
    
    # Calculate wait time
    $waitTime = $disableDateTime - $currentDateTime
    Write-Log "Wait time calculated: $($waitTime.TotalMinutes) minutes"
    
    # Connect to Microsoft Graph using managed identity
    Write-Log "Connecting to Microsoft Graph..."
    Connect-MgGraph -Identity
    
    Write-Log "Successfully connected to Microsoft Graph"
    
    # Get current user state before waiting
    $user = Get-MgUser -UserId $UserPrincipalName -Property Id, DisplayName, UserPrincipalName, AccountEnabled
    Write-Log "Current user state - Display Name: $($user.DisplayName), Account Enabled: $($user.AccountEnabled)"
    
    # Wait until the specified time
    if ($waitTime.TotalSeconds -gt 0) {
        Write-Log "Waiting until scheduled disable time..."
        Start-Sleep -Seconds $waitTime.TotalSeconds
    }
    
    # Get fresh user state after waiting
    $user = Get-MgUser -UserId $UserPrincipalName -Property Id, DisplayName, UserPrincipalName, AccountEnabled
    
    if ($user.AccountEnabled -or $Force) {
        # Disable user account
        Update-MgUser -UserId $UserPrincipalName -AccountEnabled:$false
        Write-Log "Successfully disabled user account: $UserPrincipalName ($($user.DisplayName)) at $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))"
        
        # Verify the change
        $updatedUser = Get-MgUser -UserId $UserPrincipalName -Property Id, DisplayName, UserPrincipalName, AccountEnabled
        Write-Log "Verified user state - Account Enabled: $($updatedUser.AccountEnabled)"
    }
    else {
        Write-Log "User account $UserPrincipalName ($($user.DisplayName)) is already disabled. Use -Force parameter to disable anyway."
    }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log "Error occurred: $errorMessage"
    throw $errorMessage
}
finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph
    Write-Log "Script execution completed"
}
