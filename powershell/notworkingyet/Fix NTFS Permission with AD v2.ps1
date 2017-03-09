# Requires the Active Directory PowerShell module.
# if the module cannot be loaded, script will stop.
Import-Module ActiveDirectory -ErrorAction Stop

# Set log file location.
# If a match cannot be made between folder name, username and home directory attribute, it will be reported in this log file.
$LogFile = "C:\Temp\HomeDrive-Fix.log"

# List of failed folders.
[string[]]$FailedFolders = @()

# Set the location of the base home folder share
$HomeDriveSharePath = "\\sibserver\Users Shared Folders"

# Users/groups who will be granted Full Control permissions
$AdministrativePermissions = "sibdomain\Administrators,NT AUTHORITY\SYSTEM"

# Get all subfolders and begin processing loop.
# This could be replaced with CSV/text file input if required.
$HomeDirectories = Get-ChildItem $HomeDriveSharePath
# Filter by letter of the alphabet, eg. name starting with A,B,C,D,E or F
#$HomeDirectories = Get-ChildItem $HomeDriveSharePath | Where {$_.Name -Match "^[abcdef]" -AND $_.PsIsContainer -eq $true}

ForEach ($HomeDirectory in $HomeDirectories){

# Set reference variables
$HomeDirectoryPath = $HomeDirectory.FullName
$HomeDirectoryName = $HomeDirectory.Name

# Attempt to get AD user details based on the directory name matching the login name.
# Include the HomeDirectory attribute for comparison
$ADUser = Get-ADUser -Properties HomeDirectory -Filter { SamAccountName -eq $HomeDirectoryName }

# If it all matches up, then process the ownership and permissions.
If ( $ADUser.HomeDirectory -eq $HomeDirectoryPath ){

$ADUserName = $ADUser.Name

# Use the Windows takeown tool to reset the ownership permissions to Administrators
Write-Host "Repairing ownership rights for user $ADUserName"
takeown /f $HomeDirectoryPath /a /r /d y

# Get the base ACL object
Write-Host "Creating ACLs..."
$ACL = Get-Acl $HomeDirectoryPath
$ACL.SetAccessRuleProtection($True, $False)

#Set FULL permissions (administrative permissions)
$AdministrativePermissions = $AdministrativePermissions -split ","
Write-Host "Set Admin permissions..."
ForEach ($Group in $AdministrativePermissions)
{
$Rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$Group", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.AddAccessRule($Rule)
}

#Set MODIFY permissions (User permissions)
Write-Host "Set User permissions..."
$Rule = New-Object system.security.AccessControl.FileSystemAccessRule($ADUser.UserPrincipalName,"FullControl",,,"Allow")
$ACL.RemoveAccessRuleAll($Rule)
$Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($ADUser.UserPrincipalName, "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.AddAccessRule($Rule)

Write-Host "Set ACL on top level directory..."
Set-Acl $HomeDirectoryPath $ACL

$ACL = Get-ACL $HomeDirectoryPath
$ACL.SetAccessRuleProtection($True, $False)
$AccessRule = New-Object system.security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl",,,"Allow")
$ACL.RemoveAccessRuleAll($AccessRule)
Set-Acl -Path $HomeDirectoryPath -AclObject $ACL

# Pause for a moment to allow permissions to propagate
Write-Host "Sleeping for 30 seconds to allow permissions to propagate..."
Start-Sleep -Seconds 30

# Cleanup permissions left over from takeown process
Write-Host "User and Administrators should now have access to the their home drive..."
Write-Host "Performing final cleanup of eronious permissions..."
$BadACECount = 1
While ($BadACECount -ne $null){
$FullContents = Get-ChildItem -Recurse $HomeDirectoryPath
$BadACECount = $null
ForEach ($Item in $FullContents){
$ACL = Get-ACL $Item.FullName
$ACL.SetAccessRuleProtection($False, $False)
$CustomACEs = $ACL.Access | Where { $_.IsInherited -eq $false }
If ( $CustomACEs -ne $null ){
$Item.FullName
$CustomACEs
ForEach ($CustomACE in $CustomACEs){
$ACL.RemoveAccessRule($CustomACE)
Set-Acl -Path $Item.FullName -AclObject $ACL
$BadACECount += 1
}
}
}

}
}
Else{
Write-Host "Could not match user to home directory for folder named $HomeDirectoryName"
$FailedFolders += "Could not match user to home directory for folder named $HomeDirectoryName"
}

}

$FailedFolders | Out-File $LogFile