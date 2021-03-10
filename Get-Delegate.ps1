#########################################################################################################################
#
#		Script for : identifiyng the delegation on Mailbox
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

$MBXDelegateLog = $FolderBuild+"\"+$MyDateTime+"_ExportDelegation.csv"
New-Item $MBXDelegateLog -type file | Out-Null
"Identity;User;AccessRights" | Tee-Object -FilePath $MBXDelegateLog -Append -ErrorAction SilentlyContinue

#Build
#########################################################################################################################
$ResultSize = "Unlimited"
$ImportRecipient = Get-Mailbox -ResultSize $ResultSize

#Get Permission
#########################################################################################################################

foreach ($mbx in $ImportRecipient)
    {
    #$Perm = Get-MailboxPermission $mbx.PrimarySmtpAddress | Where-Object {$_.User -notlike "NT AUTHORITY\*"-and $_.User -notlike "Default" -and $_.User -notlike "Anonymous" -and $_.User -notlike "Utilisateur NT*" -and $_.AccessRights -ne "none"}
    $Perm = Get-MailboxPermission $mbx.PrimarySmtpAddress | Where-Object {$_.User -notlike "NT AUTHORITY\*" -and $_.User -notlike "Default" -and $_.User -notlike "*Management" -and $_.User -notlike "*Exchange*" -and $_.User -notlike "Anonymous" -and $_.User -notlike "Utilisateur NT*" -and $_.User -notlike "S-1-5-21-*" -and $_.User -notlike "*\Admin*" -and $_.User -notlike "*AC738250ADM" -and $_.User -notlike "*CA177404" -and $_.User -notlike "INFRAWIN\Delegated*" -and $_.User -notlike "INFRAWIN\Managed*"}
    IF ($Perm) 
        {
        $($mbx.PrimarySmtpAddress)+";"+$Perm.User+";"+$Perm.AccessRights | Tee-Object -FilePath $MBXDelegateLog -Append | Write-Host -ForegroundColor Green
        }
    }