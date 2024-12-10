#This PowerShell script creates a new SharePoint folder via Azure runbooks.  This can be used along side Jira automation or other automation tools. 
# More information and a how-to guide can be found here: https://www.daveherrell.com/jira-cloud-automating-sharepoint-folder-creation/
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteId,

    [Parameter(Mandatory = $true)]
    [string]$DriveId,

    [Parameter(Mandatory = $true)]
    [string]$FolderName,

    [Parameter(Mandatory = $false)]
    [string]$ParentFolderPath = "/"
)

# Function to get authentication token using managed identity
function Get-ManagedIdentityToken {
    try {
        $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=https://graph.microsoft.com&api-version=2019-08-01"
        $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER" = "$env:IDENTITY_HEADER" } -Uri $tokenAuthURI
        return $tokenResponse.access_token
    }
    catch {
        Write-Error "Failed to acquire managed identity token: $_"
        throw
    }
}

# Function to create folder using Microsoft Graph API
function New-SharePointFolder {
    param(
        [string]$Token,
        [string]$SiteId,
        [string]$DriveId,
        [string]$FolderName,
        [string]$ParentFolderPath
    )

    try {
        # Format parent path
        $cleanPath = $ParentFolderPath.Trim('/')

        # Construct the API URL
        $baseUrl = "https://graph.microsoft.com/v1.0/sites/$SiteId/drives/$DriveId"

        if ([string]::IsNullOrEmpty($cleanPath)) {
            $apiUrl = "$baseUrl/items/root/children"
        } else {
            $parentPath = $cleanPath -replace "/", "%2F"
            $apiUrl = "$baseUrl/items/root:/${parentPath}:/children"
        }

        Write-Output "Using API URL: $apiUrl"

        # Prepare the request body
        $body = @{
            name = $FolderName
            folder = @{}
            "@microsoft.graph.conflictBehavior" = "rename"
        } | ConvertTo-Json

        # Prepare the headers
        $headers = @{
            'Authorization' = "Bearer $Token"
            'Content-Type' = 'application/json'
        }

        # Make the API call
        Write-Output "Sending request to create folder..."
        $response = Invoke-RestMethod -Method Post -Uri $apiUrl -Headers $headers -Body $body -Verbose
        Write-Output "Folder '$FolderName' created successfully"
        return $response
    }
    catch {
        $errorDetails = $_.ErrorDetails
        $errorMessage = if ($errorDetails) {
            $errorDetails.Message
        } elseif ($_.Exception.Response) {
            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $errorContent = $reader.ReadToEnd()
            $reader.Dispose()
            $errorContent
        } else {
            $_.Exception.Message
        }

        Write-Error "Failed to create folder: $errorMessage"
        throw
    }
}

try {
    # Add assembly for URL encoding
    Add-Type -AssemblyName System.Web

    Write-Output "Starting folder creation process..."

    # Get authentication token
    Write-Output "Getting managed identity token..."
    $token = Get-ManagedIdentityToken

    # Create the folder
    $result = New-SharePointFolder -Token $token -SiteId $SiteId -DriveId $DriveId -FolderName $FolderName -ParentFolderPath $ParentFolderPath

    # Output the result
    Write-Output "Folder creation completed"
    $result
}
catch {
    Write-Error $_.Exception.Message
    throw
}
