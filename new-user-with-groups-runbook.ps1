#This PowerShell script is used along with Azure Runbooks and Jira Automation to create new users with group membership.
#For more information, check out the how-to guide here: https://www.daveherrell.com/jira-cloud-create-ms365-users-with-group-membership-using-automation-and-azure-runbooks/

param (
    [Parameter(Mandatory=$true)]
    [string]$FirstName,

    [Parameter(Mandatory=$true)]
    [string]$LastName,

    [Parameter(Mandatory=$true)]
    [string]$InitialPassword,

    [Parameter(Mandatory=$false)]
    [string]$Groups,
    #Groups need to be sererated by a comman with no space. Example: slack-users,zoom-users,box-users

    [Parameter(Mandatory=$false)]
    [string]$Department = $null,

    [Parameter(Mandatory=$false)]
    [string]$JobTitle = $null
)

# Import required modules
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

try {
    # Connect using Managed Identity
    Connect-MgGraph -Identity

    # Construct email address
    $FirstNameLower = $FirstName.ToLower()
    $LastNameLower = $LastName.ToLower()
    $UserPrincipalName = "$FirstNameLower.$LastNameLower@daveherrell.com"  #Make sure you change the domain to your domain!
    $MailNickname = "$FirstNameLower$LastNameLower"

    # Construct display name
    $DisplayName = "$FirstName $LastName"

    # Split groups into array
    $GroupArray = $Groups -split ','

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

    # Track group addition results
    $GroupAdditionResults = @()

    # Add user to specified groups
    foreach ($GroupName in $GroupArray) {
        $GroupName = $GroupName.Trim()
        $Group = Get-MgGroup -Filter "displayName eq '$GroupName'"

        if ($Group) {
            New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $NewUser.Id
            $GroupAdditionResults += @{
                GroupName = $GroupName
                Status = "Added Successfully"
            }
            Write-Output "User added to '$GroupName' group"
        }
        else {
            $GroupAdditionResults += @{
                GroupName = $GroupName
                Status = "Group Not Found"
            }
            Write-Warning "Group '$GroupName' not found"
        }
    }

    # Prepare output object
    $OutputObject = @{
        Status = "Success"
        UserDetails = @{
            DisplayName = $DisplayName
            UserPrincipalName = $UserPrincipalName
            ObjectId = $NewUser.Id
            Department = $Department
            JobTitle = $JobTitle
            GroupAdditions = $GroupAdditionResults
        }
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

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
    $OutputObject = @{
        Status = "Failed"
        ErrorMessage = $_.Exception.Message
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    Write-Error "User Creation Failed:"
    Write-Error "-------------------"
    Write-Error "Error Message: $($OutputObject.ErrorMessage)"
    Write-Error "Timestamp: $($OutputObject.Timestamp)"

    throw
}
