# Adds an alias address to every users email and distro within your MS365 organization.  To be used with Azure Cloud Shell. 
# For more information and a breakdown for just users or groups, please see: # Connect to Exchange Online
Connect-ExchangeOnline

# Define the custom alias function
function Add-CustomEmailAlias {
    param (
        [string]$Identity,
        [string]$PrimarySmtpAddress,
        [array]$EmailAddresses,
        [string]$Type  # "Mailbox" or "Group"
    )

    if ($PrimarySmtpAddress -like "*@example.com") {
        $localPart = $PrimarySmtpAddress.Split("@")[0]
        $newAlias = "$localPart@example.us"

        if ($EmailAddresses -notcontains "smtp:$newAlias") {
            Write-Host "✅ Adding alias $newAlias to ${Type}: $Identity"

            if ($Type -eq "Mailbox") {
                Set-Mailbox -Identity $Identity -EmailAddresses @{add="smtp:$newAlias"}
            }
            elseif ($Type -eq "Group") {
                Set-DistributionGroup -Identity $Identity -EmailAddresses @{add="smtp:$newAlias"}
            }
        }
        else {
            Write-Host "⚠️ Alias already exists: $newAlias for ${Type}: $Identity"
        }
    }
}

#Process mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited
foreach ($mb in $mailboxes) {
    Add-CustomEmailAlias -Identity $mb.Identity `
                         -PrimarySmtpAddress $mb.PrimarySmtpAddress `
                         -EmailAddresses $mb.EmailAddresses `
                         -Type "Mailbox"
}

#Process distribution groups
$distGroups = Get-DistributionGroup -RecipientTypeDetails MailUniversalDistributionGroup -ResultSize Unlimited
foreach ($dg in $distGroups) {
    Add-CustomEmailAlias -Identity $dg.Identity `
                         -PrimarySmtpAddress $dg.PrimarySmtpAddress `
                         -EmailAddresses $dg.EmailAddresses `
                         -Type "Group"
}

#Process mail-enabled security groups
$mailSecGroups = Get-DistributionGroup -RecipientTypeDetails MailUniversalSecurityGroup -ResultSize Unlimited
foreach ($sg in $mailSecGroups) {
    Add-CustomEmailAlias -Identity $sg.Identity `
                         -PrimarySmtpAddress $sg.PrimarySmtpAddress `
                         -EmailAddresses $sg.EmailAddresses `
                         -Type "Group"
}

# Connect to Exchange Online
Connect-ExchangeOnline

# Define the custom alias function
function Add-CustomEmailAlias {
    param (
        [string]$Identity,
        [string]$PrimarySmtpAddress,
        [array]$EmailAddresses,
        [string]$Type  # "Mailbox" or "Group"
    )

    if ($PrimarySmtpAddress -like "*@example.com") {
        $localPart = $PrimarySmtpAddress.Split("@")[0]
        $newAlias = "$localPart@example.us"

        if ($EmailAddresses -notcontains "smtp:$newAlias") {
            Write-Host "✅ Adding alias $newAlias to ${Type}: $Identity"

            if ($Type -eq "Mailbox") {
                Set-Mailbox -Identity $Identity -EmailAddresses @{add="smtp:$newAlias"}
            }
            elseif ($Type -eq "Group") {
                Set-DistributionGroup -Identity $Identity -EmailAddresses @{add="smtp:$newAlias"}
            }
        }
        else {
            Write-Host "⚠️ Alias already exists: $newAlias for ${Type}: $Identity"
        }
    }
}

#Process mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited
foreach ($mb in $mailboxes) {
    Add-CustomEmailAlias -Identity $mb.Identity `
                         -PrimarySmtpAddress $mb.PrimarySmtpAddress `
                         -EmailAddresses $mb.EmailAddresses `
                         -Type "Mailbox"
}

#Process distribution groups
$distGroups = Get-DistributionGroup -RecipientTypeDetails MailUniversalDistributionGroup -ResultSize Unlimited
foreach ($dg in $distGroups) {
    Add-CustomEmailAlias -Identity $dg.Identity `
                         -PrimarySmtpAddress $dg.PrimarySmtpAddress `
                         -EmailAddresses $dg.EmailAddresses `
                         -Type "Group"
}

#Process mail-enabled security groups
$mailSecGroups = Get-DistributionGroup -RecipientTypeDetails MailUniversalSecurityGroup -ResultSize Unlimited
foreach ($sg in $mailSecGroups) {
    Add-CustomEmailAlias -Identity $sg.Identity `
                         -PrimarySmtpAddress $sg.PrimarySmtpAddress `
                         -EmailAddresses $sg.EmailAddresses `
                         -Type "Group"
}
