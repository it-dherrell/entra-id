# Employee Group Management Script that runs in Azure Runbooks.  
# This script updates the Employee Microsoft 365 Group based on employeeType = "Employee"
# If the user's employeeType attribute is not "Employee," it will remove the user from the group. 
# Lastly, a Slack notification will be created with the full output of the script.  Slack Webhook needs to be saved as a Runbook variable that is encrypted.
# Yes, this script is a little bloated, but it is meant to be more visual in a console and Slack.  You can easily clean this and consolidate the bloat if needed.

# Configuration
$groupId = "INSERTGROUPIDHERE"

# Slack Webhook URL (set this in Azure Automation Variables for security)
# Go to Azure Automation Account → Variables → Add Variable
# Name: SlackWebhookUrl, Value: your webhook URL
try {
    $slackWebhookUrl = Get-AutomationVariable -Name "SlackWebhookUrl"
} catch {
    Write-Warning "⚠️ SlackWebhookUrl variable not found. Slack notifications will be skipped."
    $slackWebhookUrl = $null
}

# Function to send Slack notification
function Send-SlackNotification {
    param(
        [string]$WebhookUrl,
        [string]$Message,
        [string]$Color = "good"  # good (green), warning (yellow), danger (red)
    )
    
    if ([string]::IsNullOrEmpty($WebhookUrl)) {
        Write-Output "📱 Slack webhook not configured - skipping notification"
        return
    }
    
    try {
        $slackPayload = @{
            attachments = @(
                @{
                    color = $Color
                    title = ":microsoft: Employee Group Sync Complete"
                    text = $Message
                    footer = "Azure Automation - Employee Management"
                    ts = [int][double]::Parse((Get-Date -UFormat %s))
                }
            )
        } | ConvertTo-Json -Depth 4
        
        $slackHeaders = @{
            'Content-Type' = 'application/json'
        }
        
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $slackPayload -Headers $slackHeaders
        Write-Output "📱 Slack notification sent successfully"
        
    } catch {
        Write-Warning "⚠️ Failed to send Slack notification: $($_.Exception.Message)"
    }
}

try {
    Write-Output "🔐 Authenticating with Managed Identity..."
    
    # Get access token for Graph API
    $resourceURI = "https://graph.microsoft.com"
    $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2017-09-01"
    $headers = @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"}
    $tokenResponse = Invoke-RestMethod -Method Get -Headers $headers -Uri $tokenAuthURI
    $accessToken = $tokenResponse.access_token
    
    if ([string]::IsNullOrEmpty($accessToken)) {
        throw "Failed to obtain access token from managed identity"
    }
    
    Write-Output "✅ Successfully obtained access token"
    
    # Set headers for all Graph API calls
    $graphHeaders = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type' = 'application/json'
    }
    
    # Verify the Employee group exists and get details
    Write-Output "🔍 Verifying Employee group..."
    try {
        $groupUri = "https://graph.microsoft.com/v1.0/groups/$groupId"
        $group = Invoke-RestMethod -Uri $groupUri -Headers $graphHeaders -Method Get
        Write-Output "📧 Group found: $($group.displayName)"
        Write-Output "   📮 Mail Enabled: $($group.mailEnabled)"
        Write-Output "   🔒 Security Enabled: $($group.securityEnabled)"
        Write-Output "   📝 Group Types: $($group.groupTypes -join ', ')"
        Write-Output "   📬 Email: $($group.mail)"
        
        # Verify it's a Microsoft 365 group
        if ($group.groupTypes -contains "Unified") {
            Write-Output "✅ Confirmed: This is a Microsoft 365 Group (Unified)"
        } else {
            Write-Warning "⚠️ This might not be a Microsoft 365 Group. Group types: $($group.groupTypes -join ', ')"
        }
    } catch {
        throw "Failed to retrieve group details: $($_.Exception.Message). Check group ID and permissions."
    }
    
    # Get all users using Graph API
    Write-Output "👥 Retrieving employees with employeeType = 'Employee'..."
    try {
        $usersUri = "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,employeeType"
        $allUsers = @()
        
        do {
            $usersResponse = Invoke-RestMethod -Uri $usersUri -Headers $graphHeaders -Method Get
            $allUsers += $usersResponse.value
            $usersUri = $usersResponse.'@odata.nextLink'
            
            if ($usersUri) {
                Write-Output "   📄 Retrieved $($allUsers.Count) users so far, getting more..."
            }
        } while ($usersUri)
        
        # Filter employees locally
        $employees = $allUsers | Where-Object { 
            $_.employeeType -eq 'Employee' -or 
            $_.employeeType -eq 'employee' -or 
            ($_.employeeType -and $_.employeeType.ToLower() -eq 'employee')
        }
        
        $employeeIds = $employees.id
        Write-Output "✅ Found $($employees.Count) total employees"
        
        # Log employees for verification
        if ($employees.Count -gt 0) {
            Write-Output "   📋 Employees to sync:"
            $employees | ForEach-Object {
                Write-Output "      - $($_.displayName) ($($_.userPrincipalName))"
            }
        } else {
            Write-Output "   ℹ️ No users found with employeeType = 'Employee'"
        }
    } catch {
        throw "Failed to retrieve employees: $($_.Exception.Message)"
    }
    
    # Get current group members
    Write-Output "👨‍👩‍👧‍👦 Retrieving current group members..."
    try {
        $memberUri = "https://graph.microsoft.com/v1.0/groups/$groupId/members?`$select=id,displayName,userPrincipalName"
        $allMembers = @()
        
        do {
            $memberResponse = Invoke-RestMethod -Uri $memberUri -Headers $graphHeaders -Method Get
            $userMembers = $memberResponse.value | Where-Object { $_.userPrincipalName }
            $allMembers += $userMembers
            $memberUri = $memberResponse.'@odata.nextLink'
            
            if ($memberUri) {
                Write-Output "   📄 Retrieved $($allMembers.Count) members so far, getting more..."
            }
        } while ($memberUri)
        
        $currentMemberIds = $allMembers.id
        Write-Output "✅ Found $($allMembers.Count) current user members in group"
        
        # Log current members for verification
        if ($allMembers.Count -gt 0) {
            Write-Output "   📋 Current members:"
            $allMembers | Select-Object -First 5 | ForEach-Object {
                Write-Output "      - $($_.displayName) ($($_.userPrincipalName))"
            }
            if ($allMembers.Count -gt 5) {
                Write-Output "      ... and $($allMembers.Count - 5) more"
            }
        }
    } catch {
        throw "Failed to retrieve group members: $($_.Exception.Message)"
    }
    
    # Determine which users to add and remove
    $membersToAdd = $employeeIds | Where-Object { $_ -notin $currentMemberIds }
    $membersToRemove = $currentMemberIds | Where-Object { $_ -notin $employeeIds }
    
    Write-Output ""
    Write-Output "📊 Synchronization Analysis:"
    Write-Output "   ➕ Employees to add: $($membersToAdd.Count)"
    Write-Output "   ➖ Users to remove: $($membersToRemove.Count)"
    Write-Output "   ✨ Total employees: $($employeeIds.Count)"
    Write-Output "   👥 Current members: $($currentMemberIds.Count)"
    Write-Output ""
    
    # Add new employees to the group
    if ($membersToAdd.Count -gt 0) {
        Write-Output "➕ Adding new employees to Microsoft 365 group..."
        $addSuccessCount = 0
        $addFailCount = 0
        
        foreach ($userId in $membersToAdd) {
            try {
                $addUri = "https://graph.microsoft.com/v1.0/groups/$groupId/members/`$ref"
                $body = @{
                    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
                } | ConvertTo-Json -Depth 2
                
                Invoke-RestMethod -Uri $addUri -Headers $graphHeaders -Method Post -Body $body
                
                # Get user info for logging
                $user = $employees | Where-Object { $_.id -eq $userId } | Select-Object -First 1
                Write-Output "   ✅ Added: $($user.displayName) ($($user.userPrincipalName))"
                $addSuccessCount++
                
                # Small delay to avoid throttling
                Start-Sleep -Milliseconds 200
                
            } catch {
                $addFailCount++
                $user = $employees | Where-Object { $_.id -eq $userId } | Select-Object -First 1
                Write-Warning "   ⚠️ Failed to add $($user.displayName): $($_.Exception.Message)"
                
                # Check if it's a specific error we can handle
                if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*already a member*") {
                    Write-Output "      💡 User was already a member"
                    $addSuccessCount++
                    $addFailCount--
                }
            }
        }
        Write-Output "✅ Add Summary: $addSuccessCount successful, $addFailCount failed"
    } else {
        Write-Output "ℹ️ No new employees to add"
    }
    
    Write-Output ""
    
    # Remove users no longer qualified
    if ($membersToRemove.Count -gt 0) {
        Write-Output "➖ Removing users no longer qualified..."
        $removeSuccessCount = 0
        $removeFailCount = 0
        
        foreach ($userId in $membersToRemove) {
            try {
                $removeUri = "https://graph.microsoft.com/v1.0/groups/$groupId/members/$userId/`$ref"
                Invoke-RestMethod -Uri $removeUri -Headers $graphHeaders -Method Delete
                
                # Get user info for logging
                $user = $allMembers | Where-Object { $_.id -eq $userId } | Select-Object -First 1
                Write-Output "   ❌ Removed: $($user.displayName) ($($user.userPrincipalName))"
                $removeSuccessCount++
                
                # Small delay to avoid throttling
                Start-Sleep -Milliseconds 200
                
            } catch {
                $removeFailCount++
                $user = $allMembers | Where-Object { $_.id -eq $userId } | Select-Object -First 1
                Write-Warning "   ⚠️ Failed to remove $($user.displayName): $($_.Exception.Message)"
            }
        }
        Write-Output "✅ Remove Summary: $removeSuccessCount successful, $removeFailCount failed"
    } else {
        Write-Output "ℹ️ No users to remove"
    }
    
    # Final verification
    Write-Output ""
    Write-Output "🔍 Final verification..."
    try {
        $finalMemberUri = "https://graph.microsoft.com/v1.0/groups/$groupId/members?`$count=true"
        $finalMemberResponse = Invoke-RestMethod -Uri $finalMemberUri -Headers $graphHeaders -Method Get
        $finalMemberCount = $finalMemberResponse.'@odata.count'
        if ($null -eq $finalMemberCount) {
            $finalMemberCount = $finalMemberResponse.value.Count
        }
        Write-Output "✅ Group now has $finalMemberCount total members"
    } catch {
        Write-Warning "⚠️ Could not verify final member count: $($_.Exception.Message)"
    }
    
    Write-Output ""
    Write-Output "🎉 Employee Group synchronization completed!"
    Write-Output "📈 Final Summary:"
    Write-Output "   👥 Total employees: $($employees.Count)"
    Write-Output "   ➕ Successfully added: $(if($membersToAdd) { $addSuccessCount } else { 0 })"
    Write-Output "   ➖ Successfully removed: $(if($membersToRemove) { $removeSuccessCount } else { 0 })"
    Write-Output "   📧 Group: $($group.displayName) ($($group.mail))"
    
    # Prepare Slack notification message
    $addedCount = if($membersToAdd) { $addSuccessCount } else { 0 }
    $removedCount = if($membersToRemove) { $removeSuccessCount } else { 0 }
    
    $slackMessage = ":white_check_mark: *Employee Group Sync Completed*`n"
    $slackMessage += ":email: Group updated: $($group.displayName)`n"
    $slackMessage += ":busts_in_silhouette: Total Employees: $($employees.Count)`n"
    $slackMessage += ":heavy_plus_sign: Added: $addedCount`n"
    $slackMessage += ":heavy_minus_sign: Removed: $removedCount`n"
    
    # Add details about changes if any occurred
    if ($addedCount -gt 0 -or $removedCount -gt 0) {
        $slackMessage += "`n📋 *Changes Made:*`n"
        
        if ($addedCount -gt 0) {
            $slackMessage += ":heavy_plus_sign: *Added Employees:*`n"
            foreach ($userId in $membersToAdd) {
                $user = $employees | Where-Object { $_.id -eq $userId } | Select-Object -First 1
                if ($user) {
                    $slackMessage += "   • $($user.displayName) ($($user.userPrincipalName))`n"
                }
            }
        }
        
        if ($removedCount -gt 0) {
            $slackMessage += "➖ *Removed Users:*`n"
            foreach ($userId in $membersToRemove) {
                $user = $allMembers | Where-Object { $_.id -eq $userId } | Select-Object -First 1
                if ($user) {
                    $slackMessage += "   • $($user.displayName) ($($user.userPrincipalName))`n"
                }
            }
        }
        
        # Use warning color if there were changes, good color if no changes
        $notificationColor = "warning"
    } else {
        $slackMessage += "`n:information_source: No changes required - all employees already in sync"
        $notificationColor = "good"
    }
    
    $slackMessage += "`n:clock1: Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
    
    # Send Slack notification
    Send-SlackNotification -WebhookUrl $slackWebhookUrl -Message $slackMessage -Color $notificationColor
    
} catch {
    Write-Error ":x: Script execution failed: $($_.Exception.Message)"
    if ($_.Exception.InnerException) {
        Write-Error "Inner exception: $($_.Exception.InnerException.Message)"
    }
    Write-Error "Stack trace: $($_.Exception.StackTrace)"
    
    # Send error notification to Slack
    $errorMessage = ":x: *Employee Group Sync Failed*`n"
    $errorMessage += ":rotating_light: Error: $($_.Exception.Message)`n"
    $errorMessage += ":clock12: Failed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')`n"
    $errorMessage += ":bulb: Check Azure Automation logs for details"
    
    Send-SlackNotification -WebhookUrl $slackWebhookUrl -Message $errorMessage -Color "danger"
    
    exit 1
}
