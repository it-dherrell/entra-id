#
#  Script will connect to Azure AD and export a CSV list of all users names, email address, their membership to security groups and MS365 Team groups, and the group description.
#  For more information on this script: https://www.daveherrell.com/entra-id-list-all-user-security-groups-and-members/
#
# If not already installed, make sure you install the AzureAD module into Powershell
Install-Module -Name AzureAD

#Run script as admin, make sure you update your CSV Path

# Connect to Azure AD
Connect-AzureAD

# Specify the path where you want to save the CSV file
$csvFilePath = "C:\Export\memereport.csv"

# Initialize an empty array to store user information
$userInfo = @()

# Retrieve all Azure AD users
$users = Get-AzureADUser -All $true

# Loop through each user
foreach ($user in $users) {
    # Get user's manager
    $manager = Get-AzureADUserManager -ObjectId $user.ObjectId
    
    # Get user's email address
    $email = $user.UserPrincipalName
    
    # Get user's group memberships
    $groupMemberships = Get-AzureADUserMembership -ObjectId $user.ObjectId | Select-Object -ExpandProperty DisplayName
    
    # Initialize an array to store group descriptions for each user
    $groupDescriptions = @()
    
    # Get group descriptions for each group membership
    foreach ($groupMembership in $groupMemberships) {
        $group = Get-AzureADGroup -Filter "DisplayName eq '$groupMembership'"
        $groupDescriptions += $group.Description
    }
    
    # Add user information to the array
    foreach ($groupMembership in $groupMemberships) {
        $description = $groupDescriptions[$groupMemberships.IndexOf($groupMembership)]
        $userInfo += [PSCustomObject]@{
            UserName = $user.DisplayName
            UserObjectId = $user.ObjectId
            Manager = if ($manager) { $manager.DisplayName } else { "N/A" }
            EmailAddress = $email
            GroupMembership = $groupMembership
            GroupDescription = $description
        }
    }
}

# Export the user information to a CSV file
$userInfo | Export-Csv -Path $csvFilePath -NoTypeInformation
