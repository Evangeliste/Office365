#########################################################################################################################
#
#		Script for : Auto Connect Tenant
#
#		Script author : Alexis / Evangeliste
#		mail 	: alexis@inventiq.fr
#		Create 	: 27 February 2018
#		Version	: 1.3.0
#		UPDate v1.1.0 : 14 November 2018, Add genCred capacities
#       UPDate v1.2.0 : 20 November 2018, Add Microsoft Teams Module and change import session and connect order
#       UPDate v1.3.0 : 19 December 2019, correction of connexion to SPO
#       UPDate v1.4.0 : 26 September 2020, UPDate connexion for SfBO with Teams Module
#
#########################################################################################################################

<#     
    .DESCRIPTION 
        This script help you to connect to an Office 365 or Azure Tenant and load all module
        
    .EXAMPLE 
        Generate your credential in XML File
        .\Auto-Connect.ps1 -GenCred "YourPath"

        Connection
        .\Auto-Connect.ps1 -MyCred "YourPath"

    Use : This script is provided as it and I accept no responsibility for any issues arising from its use. 
#> 


#Function/Module
#########################################################################################################################
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [String]$MyCred,
    [String]$GenCred,
    $SfBO = $false
    )

IF ($GenCred -notlike $Null)
    {
    Get-Credential | Export-Clixml -Path $GenCred
    }
ELSE
    {
    Import-Module MSOnline
    Import-Module AzureADPreview
    #Import-Module LyncOnlineConnector
    Import-Module MicrosoftTeams
    Import-Module ExchangeOnlineManagement

    $errorActionPreference = "SilentlyContinue"
    
    $CheckModule = Get-Module
        IF ($CheckModule.name -eq "MSOnline")
            {
            Write-Host "Module MSOnline is OK ! Check next module" -ForegroundColor Green
            }
        else 
            {
            Write-Host "You do not have MSOnline requiered module installed ! Please make the necesarry" -ForegroundColor Red
            Write-host "Please refer to https://blogs.technet.microsoft.com/cloudlojik/2018/07/02/how-to-install-the-msonline-powershell-module/ for install this module" -ForegroundColor Red
            Break
            }

        IF ($CheckModule.name -eq "ExchangeOnlineManagement")
            {
            Write-Host "Module ExchangeOnlineManagement is OK ! Check next module" -ForegroundColor Green
            }
        else 
            {
            Write-Host "You do not have ExchangeOnlineManagement requiered module installed ! Please make the necesarry" -ForegroundColor Red
            Write-host "Please refer to https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/exchange-online-powershell-v2/exchange-online-powershell-v2?view=exchange-ps for install this module" -ForegroundColor Red
            }

        IF ($CheckModule.name -eq "AzureADPreview")
            {
            Write-Host "Module AzureAD is OK ! Check next module" -ForegroundColor Green
            }
        else 
            {
            Write-Host "You do not have AzureADPreview requiered module installed ! Please make the necesarry" -ForegroundColor Red
            Write-host "Please refer to https://www.powershellgallery.com/packages/AzureADPreview for install this module" -ForegroundColor Red
            Break
            }

        IF ($CheckModule.name -eq "MicrosoftTeams")
            {
            Write-Host "Module MicrosoftTeams is OK ! Check next module" -ForegroundColor Green
            }
        else 
            {
            Write-Host "You do not have MicrosoftTeams requiered module installed ! Please make the necesarry" -ForegroundColor Red
            Write-host "Please refer to https://www.powershellgallery.com/packages/MicrosoftTeams for install this module" -ForegroundColor Red
            Break
            }

    Write-Host "All Module are OK !! Well done on" $env:COMPUTERNAME',' $env:UserName "the script continue" -ForegroundColor White -BackgroundColor DarkGreen
    Start-Sleep 5

    Get-PsSession | Remove-PsSession

    #Define variables
    #########################################################################################################################

    $TenantCredentials = Import-Clixml $MyCred

    Connect-MsolService -Credential $TenantCredentials
    Connect-AzureAD -Credential $TenantCredentials
    Connect-MicrosoftTeams -Credential $TenantCredentials
    #Connect-ExchangeOnline -UserPrincipalName $TenantCredentials.UserName -ShowProgress $true
    Connect-ExchangeOnline -Credential $TenantCredentials -ShowProgress $true
    

    IF ($SfBO -eq $True)
        {
        $CSSession = New-CsOnlineSession -Credential $TenantCredentials
        Import-PSSession $CSSession
        }
    else 
        {
        Write-Host "SfBO module was not loaded" -ForegroundColor Yellow
        }
    
    $DomainTenant = ""
    $DomainTenant = ((Get-MsolDomain | Where-Object {$_.Name -like "*onmicrosoft.com" -and $_.Name -notlike "*mail.onmicrosoft.com"}).Name).replace(".onmicrosoft.com","")
    #Clear-Host

    #Connect to SharePoint Online (SPO)
    #########################################################################################################################
    $SPOURI = "https://"+$DomainTenant+"-admin.sharepoint.com"
    Connect-SPOService -Url $SPOURI -Credential $TenantCredentials

    Write-Host ""
    Write-Host "#########################################################################################################################" -ForegroundColor Green
    Write-Host "#                                                                                                                        " -ForegroundColor Green
    Write-Host "#                                   You are now connected to" $DomainTenant.ToUpper() "Tenant                            " -ForegroundColor Green
    Write-Host "#                                                                                                                        " -ForegroundColor Green
    Write-Host "#########################################################################################################################" -ForegroundColor Green
    }
