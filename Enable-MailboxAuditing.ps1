#########################################################################################################################
#
#		Script for : Enable Mailbox Auditing
#
#		Script author : Alexis / Evangeliste
#		mail 	: alexis@inventiq.fr
#		Create 	: 03 September 2018
#		Version	: 1.0
#       Adapt From script find on Github https://github.com/OfficeDev/O365-InvestigationTooling/blob/master/EnableMailboxAuditing.ps1
#		UPDate 	:
#
#########################################################################################################################

<#     
    .DESCRIPTION 
        Reads the mailbox audit status and enable if not !

    .EXAMPLE 
        Production Mode
        Enable-MailboxAuditing.ps1 -MyCred C:\_Ai3\_Cred\JediMaster.xml -Mode Enable -Duration 365
            Work only mailbox with "AuditEnabled" at False
        Enable-MailboxAuditing.ps1 -MyCred C:\_Ai3\_Cred\JediMaster.xml -Mode UPDate -Duration 730
            Work on All mailbox

    Use : This script is provided as it and I accept no responsibility for any issues arising from its use. 
#> 

#Variables
#########################################################################################################################
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [String]$MyCred,
    [String]$Mode,
    [String]$Duration,
    $Report = "mail"
    )

$MyDate = get-date -Format yyyy-MM-dd
$CurrentDirectory = Get-Location

$LOGFILENAME = $CurrentDirectory.Path+"\EnableMailboxAuditing_"+$MyDate+".log"
Remove-Item $LOGFILENAME
New-Item $LOGFILENAME -type file | Out-Null

#########################################################################################################################
#
#   Emailing
#
#########################################################################################################################
#Prod Client

$From = "alexis@inventiq.fr"
$dest = "alexis.charriere@ai3.fr"
#$destcc = "recipientb@yourdomain.com" #If needed only
$smtp = "mail.inventiq.fr"
$subj = "[INVENTIQ] [$MyDate] Auditing Logs reports Activations"
$SMTPPorToUsed = "25"

#Modules
#########################################################################################################################
Import-Module MSOnline
Import-Module AzureADPreview

$CheckModule = Get-Module
    IF ($CheckModule.name -eq "MSOnline")
        {
        Write-Host "Module MSOnline is OK ! Check next module" -ForegroundColor Green
        }
    else 
        {
        Write-Host "You do not have MSOnline requiered module installed ! Please make the necesarry" -ForegroundColor Red
        Break
        }

    IF ($CheckModule.name -eq "AzureADPreview")
        {
        Write-Host "Module AzureAD is OK ! Check next module" -ForegroundColor Green
        }
    else 
        {
        Write-Host "You do not have AzureADPreview requiered module installed ! Please make the necesarry" -ForegroundColor Red
        Break
        }

Write-Host "All Module are OK !! Well done" $env:UserName "the script continue" -ForegroundColor White -BackgroundColor DarkGreen
Start-Sleep 5

Get-PsSession | Remove-PsSession

#Define variables
#########################################################################################################################

#Save your credential to an XML file : Get-Credential | Export-Clixml -Path C:\_Labs\_MyCred\YourCred.xml
#$TenantCredentials = Import-Clixml "C:\_Labs\_MyCred\Demo.xml"
$TenantCredentials = Import-Clixml $MyCred

#Connect to O365 Tenant
#$TenantCredentials = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $TenantCredentials -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -Credential $TenantCredentials
Connect-AzureAD -Credential $TenantCredentials

$DomainTenant = ""
$DomainTenant = ((Get-MsolDomain | Where-Object {$_.Name -like "*onmicrosoft.com" -and $_.Name -notlike "*mail.onmicrosoft.com"}).Name).replace(".onmicrosoft.com","")
#Clear-Host

Write-Host "##########################################################################################################################" -ForegroundColor Green
Write-Host "#                                                                                                                        #" -ForegroundColor Green
Write-Host "#                                   You are now connected to" $DomainTenant.ToUpper() "Tenant                                              #" -ForegroundColor Green
Write-Host "#                                                                                                                        #" -ForegroundColor Green
Write-Host "##########################################################################################################################" -ForegroundColor Green

$max = 10
for ($i=$max; $i -gt 1; $i--)
{
Write-Progress -Activity "You have 30 seconds for breaking the script if you are not connected to the good tenant" -Status "Please Wait or Break" `
-SecondsRemaining $i 
Start-Sleep 1
}   

#Enable global audit logging
#Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox" -or RecipientTypeDetails -eq "SharedMailbox" -or RecipientTypeDetails -eq "RoomMailbox" -or RecipientTypeDetails -eq "DiscoveryMailbox"} | Set-Mailbox -AuditEnabled $true -AuditLogAgeLimit 365 -AuditAdmin Update, MoveToDeletedItems, SoftDelete, HardDelete, SendAs, SendOnBehalf, Create, UpdateFolderPermission -AuditDelegate Update, SoftDelete, HardDelete, SendAs, Create, UpdateFolderPermissions, MoveToDeletedItems, SendOnBehalf -AuditOwner UpdateFolderPermission, MailboxLogin, Create, SoftDelete, HardDelete, Update, MoveToDeletedItems 

IF ($mode -eq "Enable")
    {
    $UsersToAudit = Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox" -or RecipientTypeDetails -eq "SharedMailbox" -or RecipientTypeDetails -eq "RoomMailbox" -or RecipientTypeDetails -eq "DiscoveryMailbox"} | Where-Object {$_.AuditEnabled -eq $False}

    ForEach ($UserToAudit in $UsersToAudit) 
        {
        Set-Mailbox -Identity $UserToAudit.UserPrincipalName -AuditEnabled $True -AuditLogAgeLimit $Duration -AuditAdmin Update, MoveToDeletedItems, SoftDelete, HardDelete, SendAs, SendOnBehalf, Create, UpdateFolderPermission -AuditDelegate Update, SoftDelete, HardDelete, SendAs, Create, UpdateFolderPermissions, MoveToDeletedItems, SendOnBehalf -AuditOwner UpdateFolderPermission, MailboxLogin, Create, SoftDelete, HardDelete, Update, MoveToDeletedItems 
        $CheckUser = Get-Mailbox $UserToAudit.UserPrincipalName
        "$($MyDate) " + $CheckUser.Name, $CheckUser.UserPrincipalName, $CheckUser.AuditEnabled, $CheckUser.AuditLogAgeLimit | Tee-Object -FilePath $LOGFILENAME -Append | Write-Host -ForegroundColor Green
        }
    }
ELSEIF ($mode -eq "UPDate")
{
    $UsersToAudit = Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox" -or RecipientTypeDetails -eq "SharedMailbox" -or RecipientTypeDetails -eq "RoomMailbox" -or RecipientTypeDetails -eq "DiscoveryMailbox"} | Where-Object {$_.AuditEnabled -eq $True}

    ForEach ($UserToAudit in $UsersToAudit) 
        {
        Set-Mailbox -Identity $UserToAudit.UserPrincipalName -AuditEnabled $True -AuditLogAgeLimit $Duration -AuditAdmin Update, MoveToDeletedItems, SoftDelete, HardDelete, SendAs, SendOnBehalf, Create, UpdateFolderPermission -AuditDelegate Update, SoftDelete, HardDelete, SendAs, Create, UpdateFolderPermissions, MoveToDeletedItems, SendOnBehalf -AuditOwner UpdateFolderPermission, MailboxLogin, Create, SoftDelete, HardDelete, Update, MoveToDeletedItems 
        $CheckUser = Get-Mailbox $UserToAudit.UserPrincipalName
        "$($MyDate) ," + $CheckUser.Name, ","+ $CheckUser.UserPrincipalName, ","+ $CheckUser.AuditEnabled, ","+ $CheckUser.AuditLogAgeLimit | Tee-Object -FilePath $LOGFILENAME -Append | Write-Host -ForegroundColor Yellow
        }
    }


#Double-Check It!

IF ($Report -eq "screen")
    {
    Get-Mailbox -ResultSize Unlimited | Select-Object Name, AuditEnabled, AuditLogAgeLimit | Out-GridView
    }
ELSEIF ($Report -eq "mail")
{
#########################################################################################################################
#
#   E-mail alerting
#
#########################################################################################################################

$TestContent = Get-Content -Path $LOGFILENAME
    if ($TestContent -eq $null)
        {
        Write-Host "No work thanks" -ForegroundColor Red
        }
    else
        {
        Write-Host "Yeah I'm working so well" -ForegroundColor White -BackgroundColor DarkGreen

#Build HTML for send mail
        $filedata = import-csv $LOGFILENAME -Header Date,Name,UserPrincipalName,AuditEnabled,AuditLogAgeLimit -Delimiter ","
        $filedata | export-csv $LOGFILENAME -NoTypeInformation -Delimiter ","
        $CSVtoHTML = Import-CSV $LOGFILENAME | ConvertTo-Html 
$EmailBody = @"
<p>
    <br>In attachment reporting of AuditLog Activation </br>
</p>

$CSVtoHTML

<p>Enjoy</p>
<p>Ai3 Teams</p>
"@
IF ($destcc -neq $null)
    {
    Send-MailMessage -From $from -To $dest -Cc $destcc -subject $subj -BodyAsHTML -Body $EmailBody -Attachments $LOGFILENAME -SmtpServer "$smtp" -Port $SMTPPorToUsed 
    }
else 
    {
    Send-MailMessage -From $from -To $dest -subject $subj -BodyAsHTML -Body $EmailBody -Attachments $LOGFILENAME -SmtpServer "$smtp" -Port $SMTPPorToUsed
    }

        
        }

$max = 10
for ($i=$max; $i -gt 1; $i--)
    {
    Write-Progress -Activity "Wait 10 seconds before delete LOGS files" -Status "Send mail InProgress" `
    -SecondsRemaining $i 
    Start-Sleep 1
    }   
Remove-Item $LOGFILENAME
}