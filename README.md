# Entra ID Scripts

Welcome to my **Entra ID Scripts** repository! This collection of scripts is designed to help IT professionals automate and manage tasks related to Microsoft Entra ID (formerly Azure AD). From user and group management to reporting and automation, these scripts are built to improve productivity and streamline identity management processes.  I have quite a few step-by-step guides on these scripts here: https://www.daveherrell.com/category/entra-id-azure-ad/

## Features

- **User Management**: Create, update, delete, and manage user accounts in Entra ID.
- **Group Management**: Manage group memberships, create new groups, and automate group operations.
- **Reporting**: Generate detailed reports for users, group memberships, and activity logs.
- **Automation**: Automate routine tasks such as user onboarding, off-boarding, and attribute updates.
- **Integration**: Connect Entra ID with other systems like Atlassian Jira or Jira Service Management for seamless workflows.

## Getting Started

### Prerequisites

1. **Entra ID Environment**:
   - Access to an Entra ID tenant.
   - Required permissions to execute administrative tasks.
2. **PowerShell Environment**:
   - PowerShell 5.1 or higher.
3. **Python Environment** (if applicable):
   - Python 3.7 or higher.
   - Required Python modules (e.g., `azure-identity`, `msgraph-core`).
4. **Azure AD and Microsoft Graph Module**:
   - Install the `AzureAD` or `AzureAD.Standard.Preview` PowerShell module.
   - Install the `Microsoft.Graph` PowerShell module.

### Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/it-dherrell/entra-id.git
   cd entra-id/Scripts
   ```

2. Install dependencies:
   - For Python scripts:
     ```bash
     pip install -r requirements.txt
     ```

3. Configure your environment:
   - For PowerShell scripts, ensure you have connected to your Entra ID tenant:
     ```powershell
     Connect-AzureAD
     ```
   - For Python scripts, set up your authentication and access keys.

### Usage

1. Run the desired script:
   - **PowerShell**:
     ```powershell
     .\ScriptName.ps1

2. Follow any prompts or review output logs for details.

## Scripts

- **all-MS365-email-and-alias-address.ps1**: Pulls a list of all email addresses including alias for your MS365 / Entra ID users. 
- **entraid-group-membership-add.ps1**: Script used along with Azure Runbooks and Jira Automation to update Entra ID Users group membeship.
- **entraid-user-attribute-update.ps1**: Script used along with Azure Runbooks and Jira Automation to update Entra ID Users attributes.
- **export-teams-member-roles.ps1**: Script to list all your MS365 Teams, members and their roles. 
- **ms365-mailbox-report.ps1**: Exports list of all MS365 active mailboxes.
- **new-user-azure-runbook.ps1**: Script to create new user via PowerShell for Azure Runbooks and Jira Automation use.
- **new-user-with-groups-runbook.ps1**: Script userd to create new users with group assignment for Azure Runbooks.
- **user-members-export.ps1**: Script export a list of users and their membershipt with Azure Entra ID.
- **user-password-policy.ps1**: Script to update Password policy for Azure Entra ID Users.
- **create-microsoft-teams-group.ps1**: Script to create MS Teams Group and use along with Jira Automation and Azure runbook.
- **create-sharepoint-folders-azure-runbooks.ps1**: Script to create Microsoft SharePoint folders in a given Site and Drive ID along side Azure rubooks and automation.
- **disable-entra-id-user-runbook.ps1**: Powershell script to disable Entra ID users using the Graph API, Azure runbooks and Jira automation.
- **Add-an-Alias-to-Every-Users-Mailbox-and-Group.ps1**: Azure CloudShell script to add alias address to all MS365 members and distribution groups. 

## Contributing

Your contributions are welcome! If you have scripts or improvements to share, please fork this repository and submit a pull request.


## Support

If you have any issues or questions, please create an issue in this repository or contact me direct.
