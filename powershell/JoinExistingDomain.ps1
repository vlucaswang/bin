#
# Windows PowerShell script for AD DS Deployment
#
# Domain Variables:
$DomainName = "test02.dmz";
# Path Variables
$DatabasePath = "C:\Windows\NTDS";
$LogPath = "C:\Windows\NTDS";
$SysvolPath = "C:\Windows\SYSVOL";
# Installing needed roles/feautres
Install-WindowsFeature-Name AD-Domain-Services -IncludeManagementTools
#
#Promote Domain Controller and join existing domain in existing forest.
#
Install-ADDSDomainController`
-NoGlobalCatalog:$false
-CreateDnsDelegation:$false `
-CriticalReplicationOnly:$false `
-DatabasePath $DatabasePath `
-LogPath $LogPath `
-SysvolPath $SysvolPath `
-DomainName $DomainName `
-InstallDns:$true `
-NoRebootOnCompletion:$false `
-SafeModeAdministratorPassword ((Get-Credential).Password)
-Force:$true