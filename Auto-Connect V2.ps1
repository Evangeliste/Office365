#########################################################################################################################
#
#		Script for : Auto Connect Tenant
#
#		Script author : Alexis / Evangeliste
#		mail 	: alexis@inventiq.fr
#		Create 	: 27 February 2018
#		Version	: 1.0
#		UPDate 	:
#
#########################################################################################################################

#Function/Module
#########################################################################################################################
[CmdletBinding(SupportsShouldProcess = $true)] 
param ( 
    [String]$MyCred,
    [String]$GenCred
    ) 

Import-Module MSOnline
Import-Module AzureADPreview
Import-Module LyncOnlineConnector

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
$CSSession = New-CsOnlineSession -Credential $TenantCredentials
Import-PSSession $Session
Import-PSSession $CSSession
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
