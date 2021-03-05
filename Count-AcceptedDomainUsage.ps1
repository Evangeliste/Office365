#########################################################################################################################
#
#		Script for : Count SMTP addresses with a Domain Name present in Get-AcceptedDomain
#
#       Count number of Addresses by Domain Name 
#
#########################################################################################################################

#Variable
#########################################################################################################################
[CmdletBinding(SupportsShouldProcess = $true)]
param 
    (
    [String]$ADCred,
    [String]$ExchURL,
    [String]$ResultSize
    )

$MyDate = Get-Date -Format yyyy-MM-dd
$MyDateTime = "$($((Get-Date).ToString('yyyy-MM-dd_HH-mm')))"
Push-Location "C:\_Scripts\"
$CurrentDirectory = Get-Location

#Connect to Exchange
#########################################################################################################################
Get-PSSession | Remove-PSSession

$Cred = Import-Clixml -Path $ADCred
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExchURL -Authentication Kerberos -Credential $Cred
Import-PSSession $session -DisableNameChecking

#Export
#########################################################################################################################
$FolderBuild = $CurrentDirectory.Path
New-Item $FolderBuild -Type Directory -ErrorAction SilentlyContinue

$UsageNDD = $FolderBuild+"\"+$MyDateTime+"_UsageNDD.csv"
New-Item $UsageNDD -type file | Out-Null
"DomainName;Count" | Tee-Object -FilePath $UsageNDD -Append -ErrorAction SilentlyContinue

$UsageNDDPrimary = $FolderBuild+"\"+$MyDateTime+"UsageNDDPrimary.csv"
New-Item $UsageNDDPrimary -type file | Out-Null
"DomainName;Count" | Tee-Object -FilePath $UsageNDDPrimary -Append -ErrorAction SilentlyContinue

#Build
#########################################################################################################################
$ResultSize = "Unlimited"
$ImportRecipient = Get-Mailbox -ResultSize $ResultSize

#Let's Gooooo
#########################################################################################################################
$NDDs = Get-AcceptedDomain
Foreach ($NDD in $NDDs.Name)
    {
    $BuildSMTP = '@'+$NDD
    $CountNDD = ($ImportRecipient | Where-Object {$_.EmailAddresses -like "*$BuildSMTP"}).count
    $($NDD+";"+$CountNDD) | Tee-Object -FilePath $UsageNDD -Append | Write-Host -ForegroundColor Green
    }

$NDDs = Get-AcceptedDomain
Foreach ($NDD in $NDDs.Name)
    {
    $BuildSMTP = '@'+$NDD
    $CountNDD = ($ImportRecipient | Where-Object {$_.PrimarySmtpAddress -like "*$BuildSMTP"}).count
    $($NDD+";"+$CountNDD) | Tee-Object -FilePath $UsageNDDPrimary -Append | Write-Host -ForegroundColor Green
    }