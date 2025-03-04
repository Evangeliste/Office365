#########################################################################################################################
#
#		Script for : Import-AutoPilotHash.ps1
#
#		Script author : Alexis Charrière / Evangeliste
#		mail 	: alexis@inventiq.fr
#		Create 	: 18 Avril 2024
#
#		Version	: 1.0
#		UPDate 	:
#
#########################################################################################################################
<#
  .DESCRIPTION
    This script generate the list view of site for ACTED or import the Hardware Hash to Windows Autopilot


  .EXAMPLE
    Simple execution (Import hash and TAG based on the computer name, ideal for existing comuter) : 
        Import-AutoPilotHash
  
    Import Hash for a single computer : 
        Import-AutoPilotHash -SetGroupTag AutoP_Common
 #>

#Param/Config
#########################################################################################################################
param (
    [Parameter(Mandatory=$False)]
    [string]$SetGroupTag
)

$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
$TenantID = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" ## Your Tenant ID
$AppID = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" ## Your App ID
$SecretAppID = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" ## Your Secret App ID

#Enroll device
#########################################################################################################################
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$False
Install-Module -Name PowerShellGet -Force -AllowClobber -Confirm:$False

Install-Script -Name Get-WindowsAutopilotInfo -Force

Write-Host "Welcome" $ENV:COMPUTERNAME "You are added to Autopilot for" -ForegroundColor Green
Get-WindowsAutoPilotInfo.ps1 -Online -TenantId $TenantID -AppId $AppID -AppSecret $SecretAppID -GroupTag $SetGroupTag