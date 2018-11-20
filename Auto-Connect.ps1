#########################################################################################################################
#
#		Script for : Auto Connect Tenant
#
#		Script author : Alexis / Evangeliste
#		mail 	: alexis@inventiq.fr
#		Create 	: 27 February 2018
#		Version	: 1.1
#		UPDate 	: 14 November 2018, Add genCred capacities
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
    [String]$GenCred
    )

IF ($GenCred -notlike $Null)
    {
    Get-Credential | Export-Clixml -Path $GenCred
    }
ELSE
    {
    Import-Module MSOnline
    Import-Module AzureADPreview
    Import-Module LyncOnlineConnector
    Import-Module MicrosoftTeams
    
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

    Write-Host "All Module are OK !! Well done" $env:UserName "the script continue" -ForegroundColor White -BackgroundColor DarkGreen
    Start-Sleep 5


    Get-PsSession | Remove-PsSession

    #Define variables
    #########################################################################################################################

    #Save your credential to an XML file : Get-Credential | Export-Clixml -Path C:\_Labs\_MyCred\YourCred.xml
    $TenantCredentials = Import-Clixml $MyCred

    #Connect to O365 Tenant
    #$TenantCredentials = Get-Credential
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $TenantCredentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session

    $CSSession = New-CsOnlineSession -Credential $TenantCredentials
    Import-PSSession $CSSession

    $TenantCredentials = Import-Clixml $MyCred
    Connect-MsolService -Credential $TenantCredentials
    Connect-AzureAD -Credential $TenantCredentials
    Connect-MicrosoftTeams -Credential $TenantCredentials

    $DomainTenant = ""
    $DomainTenant = ((Get-MsolDomain | Where-Object {$_.Name -like "*onmicrosoft.com" -and $_.Name -notlike "*mail.onmicrosoft.com"}).Name).replace(".onmicrosoft.com","")
    #Clear-Host

    Write-Host "##########################################################################################################################" -ForegroundColor Green
    Write-Host "#                                                                                                                        #" -ForegroundColor Green
    Write-Host "#                                   You are now connected to" $DomainTenant.ToUpper() "Tenant                                              #" -ForegroundColor Green
    Write-Host "#                                                                                                                        #" -ForegroundColor Green
    Write-Host "##########################################################################################################################" -ForegroundColor Green
    }