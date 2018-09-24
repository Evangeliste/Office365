#########################################################################################################################
#
#		Script for : UPDate Exchange Distribution List On Premises
#
#		Script author : Alexis Charrière / Evangeliste
#		mail 	: alexis.charriere@ai3.fr
#		Create 	: 10 Aout 2018
#		Version	: 1.0
#		UPDate 	:
#
#########################################################################################################################
<#     
    .DESCRIPTION 
        Reads the contents of a CSV specified during the runtime command, 
        then updates all Distribution lists with imported users. 
        within.
    .EXAMPLE 
        Debug Mode
        Import-DistributionGroupMembers.ps1 -SourceFile ".\Groups.CSV" -DebugMode $True

        Production Mode
        Import-DistributionGroupMembers.ps1 -SourceFile ".\Groups.CSV" -DebugMode $False

        Source CSV must contain headings Name (GroupName) and Members (All UPN users seprate with ",") to function 
    
    Use : This script is provided as it and I accept no responsibility for any issues arising from its use. 
#> 

#Variables
#########################################################################################################################
[CmdletBinding(SupportsShouldProcess = $true)]
param 
    (
    [parameter(Mandatory = $true, HelpMessage = "Location of CSV file containing both Distribution List and Members to Add", Position = 1)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path $_ })]
    [string]$SourceFile,
    $DebugMode = $true
    ) 

$errorActionPreference = "SilentlyContinue"

$MyDate = get-date -Format yyyy-MM-dd
$CurrentDirectory = Get-Location

$LOGFILENAME = $CurrentDirectory.Path+"\Import-DistributionGroupMembers_"+$MyDate+".log"
Remove-Item $LOGFILENAME
New-Item $LOGFILENAME -type file | Out-Null

$ERRORLOGFILENAME = $CurrentDirectory.Path+"\Import-DistributionGroupMembers_ERRORLOG_"+$MyDate+".log"
Remove-Item $ERRORLOGFILENAME
New-Item $ERRORLOGFILENAME -type file | Out-Null

$GROUPSERRORLOGFILENAME = $CurrentDirectory.Path+"\Import-DistributionGroupMembers_GROUPSERRORLOG_"+$MyDate+".log"
Remove-Item $GROUPSERRORLOGFILENAME
New-Item $GROUPSERRORLOGFILENAME -type file | Out-Null

#Module
#########################################################################################################################
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;
Import-Module ActiveDirectory
$CheckModule = Get-Module
    IF ($CheckModule.name -eq "ActiveDirectory")
        {
        Write-Host "Module Active Directory is OK ! the script can be run" -ForegroundColor Green
        }
    ELSE 
        {
        Write-Host "You do not have Active Directory requiered module installed ! Please make the necesarry" -ForegroundColor Red
        Break
        }

#Active Mode
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
#                                                /!\ Script begining /!\
#########################################################################################################################
$groups = Import-Csv -Path $SourceFile ";"

foreach ($group in $groups)
    {
    $CheckDL = Get-DistributionGroup -Identity $Group.Name
    IF ($CheckDL.PrimarySmtpAddress -like $null)
        {
        "$($MyDate) : " + "The Distribution Group : " + $group.name + " Doesn't exist in your Active Directory" | Tee-Object -FilePath $GROUPSERRORLOGFILENAME -Append | Write-Host -ForegroundColor Magenta
        }
    ELSE
        {
        $members = $group.members.split(",").replace(" ","")
        Foreach ($MemberToAdd in $members)
            {
            $CheckUser = Get-ADUser -Filter { UserPrincipalName -Eq $MemberToAdd }
            IF ($CheckUser.SamAccountName -like $null)
                {
                "$($MyDate) : " + "The user account " + $MemberToAdd + " Doesn't exist in your Active Directory, when adding to : " + $group.name | Tee-Object -FilePath $ERRORLOGFILENAME -Append | Write-Host -ForegroundColor Yellow
                }
            ELSE 
                {
                IF ($DebugMode -eq $true)
                    {
                    Add-DistributionGroupMember -Identity $group.Name -Member $MemberToAdd -confirm:$false -Whatif
                    }
                ELSE 
                    {
                    Add-DistributionGroupMember -Identity $group.Name -Member $MemberToAdd -confirm:$false -ErrorAction SilentlyContinue
                    "$($MyDate) : " + "The user account " + $MemberToAdd + " was added to " + $group.name | Tee-Object -FilePath $LOGFILENAME -Append | Write-Host -ForegroundColor Green
                    }
                }
            }
        }
    }