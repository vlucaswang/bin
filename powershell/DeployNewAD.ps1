#
# Windows PowerShell script for AD DS Deployment
#
# Domain Variables:
$DomainName = "test02.dmz";
$NetbiosName = "TEST02"
$DomainMode = "Win2012R2";
$ForestMode = "Win2012R2";
#
# Path Variables
$DatabasePath = "C:\Windows\NTDS";
$LogPath = "C:\Windows\NTDS";
$SysvolPath = "C:\Windows\SYSVOL";
# Installing needed roles/feautres
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
#
#Promote Domain Controller and create a new domain in new forest.
#
Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath $DatabasePath `
-LogPath $LogPath `
-SysvolPath $SysvolPath `
-DomainName $DomainName `
-DomainMode $DomainMode `
-ForestMode $ForestMode `
-DomainNetbiosName $NetbiosName `
-InstallDns:$true `
-NoRebootOnCompletion:$false `
-SafeModeAdministratorPassword ((Get-Credential).Password) `
-Force:$true