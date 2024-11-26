#This PowerShell script is ment to be used within an Azure Rubook along with Jira automation in order to update a users Entra ID information such as city, state, etc. 
#For more information and the how-to guide, check out https://www.daveherrell.com/jira-cloud-automating-entra-id-user-attribute-updates-via-automation-and-azure-runbook/

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory = $false)]
    [string]$BusinessPhone,
    
    [Parameter(Mandatory = $false)]
    [string]$MobilePhone,
    
    [Parameter(Mandatory = $false)]
    [string]$StreetAddress,
    
    [Parameter(Mandatory = $false)]
    [string]$City,
    
    [Parameter(Mandatory = $false)]
    [string]$State,
    
    [Parameter(Mandatory = $false)]
    [string]$PostalCode,
    
    [Parameter(Mandatory = $false)]
    [string]$Country
)

# Error handling function
function Write-ErrorLog {
    param($Message)
    Write-Error "Error: $Message"
    throw $Message
}

# Function to check Graph API permissions
function Test-GraphPermissions {
    try {
        # Try to get current user to test permissions
        $testUser = Get-MgUser -UserId $UserPrincipalName -Property "id" -ErrorAction Stop
        Write-Output "Graph API permissions verified successfully."
        return $true
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -like "*Insufficient privileges*" -or $errorMessage -like "*Authorization_RequestDenied*") {
            Write-ErrorLog "Insufficient permissions to access Microsoft Graph API. Please ensure the Managed Identity has User.ReadWrite.All and Directory.ReadWrite.All permissions."
        }
        else {
            Write-ErrorLog "Error testing Graph API permissions: $errorMessage"
        }
        return $false
    }
}

try {
    # Connect to Microsoft Graph with managed identity
    Write-Output "Connecting to Microsoft Graph..."
    try {
        Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
        Write-Output "Successfully connected to Microsoft Graph using Managed Identity"
    }
    catch {
        Write-ErrorLog "Failed to connect to Microsoft Graph using Managed Identity. Error: $($_.Exception.Message)"
    }

    # Test Graph API permissions
    if (-not (Test-GraphPermissions)) {
        Write-ErrorLog "Permission check failed. Please verify Managed Identity permissions."
    }
    
    # Get user to verify existence
    try {
        $user = Get-MgUser -UserId $UserPrincipalName -Property "id,displayName,businessPhones,mobilePhone,streetAddress,city,state,postalCode,country" -ErrorAction Stop
        Write-Output "User found: $($user.DisplayName)"
    }
    catch {
        Write-ErrorLog "User not found or insufficient permissions: $UserPrincipalName. Error: $($_.Exception.Message)"
    }

    # Prepare update parameters
    $updateParams = @{}

    # Add parameters only if they are provided
    if ($BusinessPhone) { $updateParams["BusinessPhones"] = @($BusinessPhone) }
    if ($MobilePhone) { $updateParams["MobilePhone"] = $MobilePhone }
    
    # Handle address information
    if ($StreetAddress -or $City -or $State -or $PostalCode -or $Country) {
        if ($StreetAddress) { $updateParams["StreetAddress"] = $StreetAddress }
        if ($City) { $updateParams["City"] = $City }
        if ($State) { $updateParams["State"] = $State }
        if ($PostalCode) { $updateParams["PostalCode"] = $PostalCode }
        if ($Country) { $updateParams["Country"] = $Country }
    }

    # Only proceed with update if there are parameters to update
    if ($updateParams.Count -gt 0) {
        Write-Output "Updating user attributes..."
        
        try {
            # Update user
            Update-MgUser -UserId $UserPrincipalName -BodyParameter $updateParams -ErrorAction Stop
            Write-Output "Successfully updated attributes for user: $UserPrincipalName"
            
            # Get updated user details for verification
            $updatedUser = Get-MgUser -UserId $UserPrincipalName -Property "id,displayName,businessPhones,mobilePhone,streetAddress,city,state,postalCode,country"
            Write-Output "Updated user details:"
            Write-Output "Business Phone: $($updatedUser.BusinessPhones -join ',')"
            Write-Output "Mobile Phone: $($updatedUser.MobilePhone)"
            Write-Output "Street Address: $($updatedUser.StreetAddress)"
            Write-Output "City: $($updatedUser.City)"
            Write-Output "State: $($updatedUser.State)"
            Write-Output "Postal Code: $($updatedUser.PostalCode)"
            Write-Output "Country: $($updatedUser.Country)"
        }
        catch {
            Write-ErrorLog "Failed to update user attributes. Error: $($_.Exception.Message)"
        }
    }
    else {
        Write-Output "No attributes provided for update."
    }
}
catch {
    Write-ErrorLog $_.Exception.Message
}
finally {
    # Disconnect from services
    Disconnect-MgGraph | Out-Null
}
