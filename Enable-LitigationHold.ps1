#########################################################################################################################
#
#		Script for : Enable Litigation Hold on Mailbox
#
#		Script author : Alexis / Evangeliste
#		mail 	: alexis@inventiq.fr
#		Create 	: 24 September 2018
#		Version	: 1.0
#		UPDate 	:
#
#########################################################################################################################

<#     
    .DESCRIPTION 
        Reads your Office mailbox to find all mailbox with no LitigationHold enabled

    .EXAMPLE 
        Debug Mode
        Enable-LitigationHold.ps1 -MyCred YourCred.xml -Duration 1825 -DebugMode $True
        1825 = Numbers of days for Five Years

        Production Mode
        Enable-LitigationHold.ps1 -MyCred YourCred.xml -Duration 1825 -DebugMode $False
        1825 = Numbers of days for Five Years
    
    Use : This script is provided as it and I accept no responsibility for any issues arising from its use. 
#> 

#Variables
#########################################################################################################################
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [String]$MyCred,
    [String]$Duration,
    $DebugMode = $true
    )

#Display Running Mode
#########################################################################################################################
IF ($DebugMode -eq $true)
    {
    Write-Host "#####################################################################################################################" -ForegroundColor Yellow
    Write-Host "#                                                                                                                   #" -ForegroundColor Yellow
    Write-Host "#                                       /!\ Running in DEBUG mode /!\                                               #" -ForegroundColor Yellow
    Write-Host "#                                                                                                                   #" -ForegroundColor Yellow
    Write-Host "#####################################################################################################################" -ForegroundColor Yellow
    $errorActionPreference = "Continue"
    }
ELSE 
    {
    Write-Host "#####################################################################################################################" -ForegroundColor Green
    Write-Host "#                                                                                                                   #" -ForegroundColor Green
    Write-Host "#                                     /!\ Running in PRODUCTION mode /!\                                            #" -ForegroundColor Red
    Write-Host "#                                                                                                                   #" -ForegroundColor Green
    Write-Host "#####################################################################################################################" -ForegroundColor Green
    $errorActionPreference = "SilentlyContinue"
    }

Write-Host ""
Start-Sleep 5

#$errorActionPreference = "SilentlyContinue"

$MyDate = get-date -Format yyyy-MM-dd_HH-mm
$CurrentDirectory = Get-Location
 
#Logfiles
#########################################################################################################################
$LOGFILENAME = $CurrentDirectory.Path+"\"+$MyDate+"_UPDateUPN.log"
Remove-Item $LOGFILENAME
New-Item $LOGFILENAME -type file | Out-Null


#########################################################################################################################
#
#   Emailing
#
#########################################################################################################################
#Prod Client

$From = "YourSender@yourdomain.com"
$dest = "recipienta@yourdomain.com"
#$destcc = "recipientb@yourdomain.com" #If needed only
$smtp = "YourSMTPServer"
$subj = "[Lagardere Active] [$MyDate] LitigationHold reports Activations"
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


#                                                /!\ Script begining /!\
#########################################################################################################################

#Import Mailbox where LitigationHold was not yet enabled
#########################################################################################################################
$LitigationHoldToEnabled = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.LitigationHoldEnabled -eq $False -and $_.identity -notlike "DiscoverySearchMailbox*"}

ForEach ($MailboxToLitigationHold in $LitigationHoldToEnabled.UserPrincipalName)
    {
    IF ($DebugMode -eq $True)
        {
        Set-Mailbox -Identity $MailboxToLitigationHold -LitigationHoldEnabled $true -LitigationHoldDuration $Duration -whatif | Write-Host -ForegroundColor Yellow
        }
    ELSEIF ($DebugMode -eq $False)
        {
        Set-Mailbox -Identity $MailboxToLitigationHold -LitigationHoldEnabled $true -LitigationHoldDuration $Duration
        $CheckHold = Get-Mailbox -Identity $MailboxToLitigationHold
        $a = $CheckHold.DisplayName
        $b = $CheckHold.UserPrincipalName
        $c = $CheckHold.LitigationHoldDate
        $d = $CheckHold.LitigationHoldEnabled
        $e = $CheckHold.LitigationHoldDuration
        "$($MyDate), $a, $b, $c, $d, $e" | Tee-Object -FilePath $LOGFILENAME -Append | Write-Host -ForegroundColor Green
        }
    }


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
        Write-Host "Yeah I'm working so well" -ForegroundColor green

#Build HTML for send mail
        $filedata = import-csv $LOGFILENAME -Header Date,DisplayName,UserPrincipalName,LitigationHoldDate,LitigationHoldEnabled,LitigationHoldDuration -Delimiter ","
        $filedata | export-csv $LOGFILENAME -NoTypeInformation -Delimiter ","
        $CSVtoHTML = Import-CSV $LOGFILENAME | ConvertTo-Html
$EmailBody = @"
<p>
    <br>In attachment reporting of LitigationHold activation </br>
</p>

$CSVtoHTML

<p>Enjoy</p>
<p>Ai3 Teams</p>
"@
Send-MailMessage -From $from -To $dest -subject $subj -BodyAsHTML -Body $EmailBody -Attachments $LOGFILENAME -SmtpServer "$smtp" -Port $SMTPPorToUsed
        
        }

$max = 10
for ($i=$max; $i -gt 1; $i--)
    {
    Write-Progress -Activity "Wait 10 seconds before delete LOGS files" -Status "Send mail InProgress" `
    -SecondsRemaining $i 
    Start-Sleep 1
    }   
Remove-Item $LOGFILENAME