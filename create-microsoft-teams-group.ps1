# This PowerShell script was created to be used with Azure Runbooks in order to create a Microsoft Teams Group, add members, set Team email and owner.  
# This script is also part of a process to automate Microsoft Teams creation using Jira Automation. 
# More detailed information can be found here: https://www.daveherrell.com/jira-cloud-create-ms-teams-group-via-jira-automation-and-azure-runbooks/

param(
    [Parameter(Mandatory=$false)]
    [string]$Owner,
    [Parameter(Mandatory=$false)]
    [string]$Members,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Private', 'Public')]
    [string]$Visibility,
    [Parameter(Mandatory=$false)]
    [string]$TeamName,
    [Parameter(Mandatory=$false)]
    [string]$TeamDescription,
    [Parameter(Mandatory=$false)]
    [string]$ChannelEmail
)

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Teams
Import-Module Microsoft.Graph.Users

Connect-MgGraph -Identity

if ($TeamName -and $Owner) {
    try {
        $ownerId = Get-MgUser -Filter "userPrincipalName eq '$Owner'" | Select-Object -ExpandProperty Id
        if (!$ownerId) { throw "Owner not found" }

        # Prepare member IDs first
        $memberIds = @()
        if ($Members) {
            $memberList = $Members -split ','
            foreach ($member in $memberList) {
                $memberUpn = $member.Trim()
                $userId = Get-MgUser -Filter "userPrincipalName eq '$memberUpn'" | Select-Object -ExpandProperty Id
                if ($userId) {
                    $memberIds += "https://graph.microsoft.com/v1.0/users/$userId"
                }
            }
        }

        # Create group with members
        $createGroupBody = @{
            displayName = $TeamName
            description = $TeamDescription
            groupTypes = @("Unified")
            mailEnabled = $true
            mailNickname = ($TeamName -replace '\s+', '') + (Get-Random)
            securityEnabled = $true
            visibility = ($Visibility ?? 'Private')
            "owners@odata.bind" = @("https://graph.microsoft.com/v1.0/users/$ownerId")
        }

        if ($memberIds.Count -gt 0) {
            $createGroupBody["members@odata.bind"] = $memberIds
        }

        $group = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups" -Body ($createGroupBody | ConvertTo-Json)
        $groupId = $group.id.Trim()
        Write-Host "Created M365 Group with ID: $groupId"
        
        Start-Sleep -Seconds 30
        
        $teamParams = @{
            memberSettings = @{
                allowCreateUpdateChannels = $true
            }
            guestSettings = @{
                allowCreateUpdateChannels = $false
            }
            messagingSettings = @{
                allowUserEditMessages = $true
                allowUserDeleteMessages = $true
            }
            funSettings = @{
                allowGiphy = $true
                giphyContentRating = "Strict"
            }
        }

        $uri = "https://graph.microsoft.com/v1.0/groups/$groupId/team"
        $team = Invoke-MgGraphRequest -Method PUT -Uri $uri -Body ($teamParams | ConvertTo-Json -Depth 10)

        if ($ChannelEmail) {
            $generalChannelId = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/teams/$groupId/channels" | ConvertFrom-Json).value | 
                Where-Object { $_.displayName -eq "General" } |
                Select-Object -ExpandProperty id

            $emailParams = @{
                emailAddress = $ChannelEmail
            }
            
            $emailUri = "https://graph.microsoft.com/v1.0/teams/$groupId/channels/$generalChannelId/email"
            Invoke-MgGraphRequest -Method PUT -Uri $emailUri -Body ($emailParams | ConvertTo-Json)
            Write-Host "Set channel email to $ChannelEmail"
        }

        if ($Visibility -and !$TeamName) {
            Update-MgGroup -GroupId $groupId -Visibility $Visibility
            Write-Host "Updated group visibility to $Visibility"
        }
    }
    catch {
        Write-Error "Failed to create/configure team: $_"
    }
}

Disconnect-MgGraph
            
