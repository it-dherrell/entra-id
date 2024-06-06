#PowerShell script to Export list of all MS365 mailboxes, size and more to CSV file. 
#For more info see: https://www.daveherrell.com/powershell-basics-report-all-mailboxes-current-size-more

Function Get_MailboxSize
{
 $Stats=Get-MailboxStatistics -Identity $UPN
 $ItemCount=$Stats.ItemCount
 $TotalItemSize=$Stats.TotalItemSize
 $TotalItemSizeinBytes= $TotalItemSize –replace “(.*\()|,| [a-z]*\)”, “”
 $TotalSize=$stats.TotalItemSize.value -replace "\(.*",""
 $DeletedItemCount=$Stats.DeletedItemCount
 $TotalDeletedItemSize=$Stats.TotalDeletedItemSize

 #Export result to csv
 $Result=@{'Display Name'=$DisplayName;'User Principal Name'=$upn;'Mailbox Type'=$MailboxType;'Primary SMTP Address'=$PrimarySMTPAddress;'Archive Status'=$Archivestatus;'Item Count'=$ItemCount;'Total Size'=$TotalSize;'Total Size (Bytes)'=$TotalItemSizeinBytes;'Deleted Item Count'=$DeletedItemCount;'Deleted Item Size'=$TotalDeletedItemSize;'Issue Warning Quota'=$IssueWarningQuota;'Prohibit Send Quota'=$ProhibitSendQuota}
 $Results= New-Object PSObject -Property $Result  
 $Results | Select-Object 'Display Name','User Principal Name','Mailbox Type','Primary SMTP Address','Item Count','Total Size','Total Size (Bytes)','Archive Status','Deleted Item Count','Deleted Item Size','Issue Warning Quota','Prohibit Send Quota' | Export-Csv -Path $ExportCSV -Notype -Append 
}

Function main()
{
 #Check for EXO v2 module inatallation
 $Module = Get-Module ExchangeOnlineManagement -ListAvailable
 if($Module.count -eq 0) 
 { 
  Write-Host Exchange Online PowerShell V2 module is not available  -ForegroundColor yellow  
  $Confirm= Read-Host Are you sure you want to install module? [Y] Yes [N] No 
  if($Confirm -match "[yY]") 
  { 
   Write-host "Installing Exchange Online PowerShell module"
   Install-Module ExchangeOnlineManagement -Repository PSGallery -AllowClobber -Force
  } 
  else 
  { 
   Write-Host EXO V2 module is required to connect Exchange Online.Please install module using Install-Module ExchangeOnlineManagement cmdlet. 
   Exit
  }
 } 

 #Connect Exchange Online, this supports MFA
 Connect-ExchangeOnline


 #Output file declaration 
 $ExportCSV="C:\Users\dave.herrell\Desktop\MailboxSizeReport.csv" 

 $Result=""   
 $Results=@()  
 $MBCount=0
 $PrintedMBCount=0
 Write-Host Generating mailbox size report...
 
 #Check for input file
 if([string]$MBNamesFile -ne "") 
 { 
  #We have an input file, read it into memory 
  $Mailboxes=@()
  $Mailboxes=Import-Csv -Header "MBIdentity" $MBNamesFile
  foreach($item in $Mailboxes)
  {
   $MBDetails=Get-Mailbox -Identity $item.MBIdentity
   $UPN=$MBDetails.UserPrincipalName  
   $MailboxType=$MBDetails.RecipientTypeDetails
   $DisplayName=$MBDetails.DisplayName
   $PrimarySMTPAddress=$MBDetails.PrimarySMTPAddress
   $IssueWarningQuota=$MBDetails.IssueWarningQuota -replace "\(.*",""
   $ProhibitSendQuota=$MBDetails.ProhibitSendQuota -replace "\(.*",""
   $ProhibitSendReceiveQuota=$MBDetails.ProhibitSendReceiveQuota -replace "\(.*",""
   #Check for archive enabled mailbox
   if(($MBDetails.ArchiveDatabase -eq $null) -and ($MBDetails.ArchiveDatabaseGuid -eq $MBDetails.ArchiveGuid))
   {
    $ArchiveStatus = "Disabled"
   }
   else
   {
    $ArchiveStatus= "Active"
   }
   $MBCount++
   Write-Progress -Activity "`n     Completed mailbox count: $MBCount "`n"  Currently Scanning: $DisplayName"
   Get_MailboxSize
   $PrintedMBCount++
  }
 }

 #Lets get all the mailboxes from our account.
 else
 {
  Get-Mailbox -ResultSize Unlimited | foreach {
   $UPN=$_.UserPrincipalName
   $Mailboxtype=$_.RecipientTypeDetails
   $DisplayName=$_.DisplayName
   $PrimarySMTPAddress=$_.PrimarySMTPAddress
   $IssueWarningQuota=$_.IssueWarningQuota -replace "\(.*",""
   $ProhibitSendQuota=$_.ProhibitSendQuota -replace "\(.*",""
   $ProhibitSendReceiveQuota=$_.ProhibitSendReceiveQuota -replace "\(.*",""
   $MBCount++
   Write-Progress -Activity "`n     Processed mailbox count: $MBCount "`n"  Scanning: $DisplayName"
   if($SharedMBOnly.IsPresent -and ($Mailboxtype -ne "SharedMailbox"))
   {
    return
   }
   if($UserMBOnly.IsPresent -and ($MailboxType -ne "UserMailbox"))
   {
    return
   }  
   #Check for archive enabled mailbox
   if(($_.ArchiveDatabase -eq $null) -and ($_.ArchiveDatabaseGuid -eq $_.ArchiveGuid))
   {
    $ArchiveStatus = "Disabled"
   }
   else
   {
    $ArchiveStatus= "Active"
   }
   Get_MailboxSize
   $PrintedMBCount++
  }
 }

 #Output file creation and completion of script
 If($PrintedMBCount -eq 0)
 {
  Write-Host No mailbox found
 }
 else
 {
  Write-Host `nThe output file contains $PrintedMBCount mailboxes.
  if((Test-Path -Path $ExportCSV) -eq "True") 
  {
   Write-Host `n The Output file available in: -NoNewline -ForegroundColor Yellow
   Write-Host $ExportCSV 
  }
 }
 #Disconnect Exchange Online session
 Disconnect-ExchangeOnline -Confirm:$false | Out-Null
 
}
 . main 
