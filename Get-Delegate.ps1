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
"Identity,FolderName,User,AccessRights" | Tee-Object -FilePath $MBXDelegateLog -Append -ErrorAction SilentlyContinue

#Build
#########################################################################################################################
$ResultSize = "Unlimited"
$ImportRecipient = Get-Mailbox -ResultSize $ResultSize

#Get Permission
#########################################################################################################################

foreach ($mbx in $ImportRecipient)
    {
    $Perm = Get-MailboxFolderPermission $mbx.PrimarySmtpAddress | Where-Object {$_.User -notlike "NT AUTHORITY\*"-and $_.User -notlike "Default" -and $_.User -notlike "Anonymous" -and $_.User -notlike "Utilisateur NT*" -and $_.AccessRights -ne "none"}
    IF ($Perm) 
        {
        $($mbx.PrimarySmtpAddress)+";"+$Perm.FolderName+";"+$Perm.User+";"+$Perm.AccessRights | Tee-Object -FilePath $MBXDelegateLog -Append | Write-Host -ForegroundColor Green
        }
    }