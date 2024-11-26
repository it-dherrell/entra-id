#This PowerShell script is used along with Azure Runbooks and Jira Automation to create new users.
#For more information, check out the how-to guide here: https://www.daveherrell.com/create-ms365-user-with-jira-and-azure-runbooks/


param (
    [Parameter(Mandatory=$true)]
    [string]$FirstName,

    [Parameter(Mandatory=$true)]
    [string]$LastName,

    [Parameter(Mandatory=$true)]
    [string]$InitialPassword,

    [Parameter(Mandatory=$false)]  #Note we're not making this field mandatory.
    [string]$Department = $null,

    [Parameter(Mandatory=$false)]
    [string]$JobTitle = $null
)

# Import required modules. You should have already installed these on the runbook.
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users

# Initialize output object
$OutputObject = @{
    Status = $null
    UserDetails = $null
    ErrorMessage = $null
    Timestamp = $null
}

try {
    # Connect using Managed Identity
    Connect-MgGraph -Identity

    # Construct email address
    $FirstNameLower = $FirstName.ToLower()
    $LastNameLower = $LastName.ToLower()
    $UserPrincipalName = "$FirstNameLower.$LastNameLower@daveherrell.com" #Make sure you change the domain to your domain.
    $MailNickname = "$FirstNameLower$LastNameLower"

    # Construct display name
    $DisplayName = "$FirstName $LastName"

    # Prepare password profile
    $PasswordProfile = @{
        Password = $InitialPassword
        ForceChangePasswordNextSignIn = $true
    }

    # Prepare user parameters
    $UserParams = @{
        DisplayName = $DisplayName
        GivenName = $FirstName
        Surname = $LastName
        UserPrincipalName = $UserPrincipalName
        MailNickname = $MailNickname
        AccountEnabled = $true
        PasswordProfile = $PasswordProfile
    }

    # Add optional parameters if provided
    if ($Department) { $UserParams.Department = $Department }
    if ($JobTitle) { $UserParams.JobTitle = $JobTitle }

    # Create user
    $NewUser = New-MgUser @UserParams

    # Prepare output object
    $OutputObject.Status = "Success"
    $OutputObject.UserDetails = @{
        DisplayName = $DisplayName
        UserPrincipalName = $UserPrincipalName
        ObjectId = $NewUser.Id
        Department = $Department
        JobTitle = $JobTitle
    }
    $OutputObject.Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    # Output detailed results
    Write-Output "User Creation Status Report:"
    Write-Output "----------------------------"
    Write-Output "Status: $($OutputObject.Status)"
    Write-Output "Full Name: $DisplayName"
    Write-Output "Email Address: $UserPrincipalName"
    Write-Output "User Object ID: $($NewUser.Id)"
    Write-Output "Timestamp: $($OutputObject.Timestamp)"

    return $OutputObject
}
catch {
    # Capture error details
    $OutputObject.Status = "Failed"
    $OutputObject.ErrorMessage = $_.Exception.Message
    $OutputObject.Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    # Output error information
    Write-Error "User Creation Failed:"
    Write-Error "-------------------"
    Write-Error "Error Message: $($OutputObject.ErrorMessage)"
    Write-Error "Timestamp: $($OutputObject.Timestamp)"

    throw
}
