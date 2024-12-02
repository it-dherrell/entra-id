#Powershell script to pull all email address including alias addresses in a MS365 environment. 
#For more information go here: https://www.daveherrell.com/powershell-basic-get-list-of-all-ms365-emails-address-alias/

#Make sure you install the EOM Module to your PowerShell
Install-Module -Name ExchangeOnlineManagement

# Import the Exchange Online Management module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online using your credentials
# Replace 'username@domain.com' with your actual credentials
Connect-ExchangeOnline -UserPrincipalName "username@domain.com"

# Get all mailboxes and aliases
$mailboxes = Get-Recipient -ResultSize Unlimited | Select-Object DisplayName, RecipientType, @{Name="EmailAddresses";Expression={($_.EmailAddresses | Where-Object { $_ -match "^smtp:" } | ForEach-Object {$_ -replace "smtp:",""}) -join "," }}

# Export the results to a CSV file, make sure you update your path.
$mailboxes | Export-Csv -Path C:\Users\dave\Desktop\MS365_EmailAddresses.csv -NoTypeInformation

# Disconnect from Exchange Online
Disconnect-ExchangeOnline

# Informative message
Write-Host "All MS365 email addresses and aliases exported to 'MS365_EmailAddresses.csv'"
