# This is a Runbook to add user to multiple groups.  To be used with Jira Automation for easy group membership management. 
# For more information and how-to-guide please check out: https://www.daveherrell.com/jira-cloud-update-ms365-user-groups-using-automation-and-azure-runbooks/

param (
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,   #This is typically the email address of the user.

    [Parameter(Mandatory=$true)]
    [string]$GroupDisplayNames # Comma-separated string of group names
)

# Ensure TLS 1.2 is used
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Import Microsoft Graph modules
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

# Authenticate using managed identity
Connect-MgGraph -Identity

try {
    # Find the user by UserPrincipalName
    $User = Get-MgUser -UserId $UserPrincipalName
    if (-not $User) {
        throw "User $UserPrincipalName not found"
    }

    # Split the comma-separated group names and trim whitespace
    $GroupArray = $GroupDisplayNames.Split(',') | ForEach-Object { $_.Trim() }

    # Track results
    $Results = @{
        Successful = @()
        Failed = @()
    }

    # Process each group
    foreach ($GroupName in $GroupArray) {
        try {
            # Find the group by display name
            $Group = Get-MgGroup -Filter "displayName eq '$GroupName'"

            if ($Group) {
                # Check if user is already a member
                $ExistingMember = Get-MgGroupMember -GroupId $Group.Id | Where-Object { $_.Id -eq $User.Id }

                if ($ExistingMember) {
                    Write-Output "User $UserPrincipalName is already a member of group $GroupName"
                    $Results.Successful += "$GroupName (Already Member)"
                }
                else {
                    # Add user to the group
                    New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $User.Id
                    Write-Output "Successfully added $UserPrincipalName to group $GroupName"
                    $Results.Successful += $GroupName
                }
            }
            else {
                Write-Error "Group '$GroupName' not found"
                $Results.Failed += "$GroupName (Group Not Found)"
            }
        }
        catch {
            Write-Error "Error adding user to group '$GroupName': $_"
            $Results.Failed += "$GroupName (Error: $($_.Exception.Message))"
        }
    }

    # Output summary
    Write-Output "`nOperation Summary:"
    Write-Output "Successful operations: $($Results.Successful.Count)"
    if ($Results.Successful) {
        Write-Output "Successfully processed groups:"
        $Results.Successful | ForEach-Object { Write-Output "- $_" }
    }

    if ($Results.Failed) {
        Write-Output "`nFailed operations: $($Results.Failed.Count)"
        Write-Output "Failed groups:"
        $Results.Failed | ForEach-Object { Write-Output "- $_" }
    }
}
catch {
    Write-Error "Error in main script execution: $_"
}
finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph
}
