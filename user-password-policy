#
#  Script will disable the password expiration policie allowing Hybrid AD to Entra ID enviroments to keep the same password expiration date. 
#  For more information on this script: https://www.daveherrell.com/entra-id-disable-user-password-expiration/
#
# If not already installed, make sure you install the AzureAD module into Powershell
Install-Module -Name AzureAD

#Connect via Powershell:
Connect-AzureAD -Confirm

#Check Users Policy
#Check users policy:
Get-AzureADUser -ObjectId 'user@domain.com' | Select-Object @{N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}}

#Setting all users to expire in Azure AD
Get-AzureADUser -All $true | Set-AzureADUser -PasswordPolicies None

#Setting single user to expire in Azure AD
Set-AzureADUser -ObjectId 'user@domain.com' -PasswordPolicies DisablePasswordExpiration

#To re-enable for all
Get-AzureADUser -All $true | Set-AzureADUser -PasswordPolicies DisablePasswordExpiration
