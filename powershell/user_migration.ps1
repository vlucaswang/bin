$HomeDrivePath = "C:\BAK\Users"
$CurrentHomeDrivePath = "C:\Users"
$HomeDirectories = Get-ChildItem $HomeDrivePath | Where {$_.PSIsContainer}
$DomainName = "virginia.local"



ForEach ($HomeDirectory in $HomeDirectories) {
  $HomeDirectoryPath = $HomeDirectory.FullName
  $HomeDirectoryName = $HomeDirectory.Name
  $Acl = Get-Acl $HomeDirectory.FullName
  $username = $DomainName + "\" + $HomeDirectoryName
  # Grant the user full control
  $accessLevel = "FullControl"
  # Should permissions be inherited from above?
  $inheritanceFlags = "ContainerInherit, ObjectInherit"
  # Should permissions propagate to below?
  $propagationFlags = "None"
  # Is this an Allow/Deny entry?
  $accessControlType = "Allow"
  # Create the Access Rule
  $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,$accessLevel,$inheritanceFlags,$propagationFlags,$accessControlType)
  $Acl.SetAccessRule($accessRule)
  Set-Acl -Path $HomeDirectory.FullName -AclObject $Acl

  reg load HKLM\${HomeDirectoryName}1 "$HomeDirectoryPath\NTUSER.DAT"
  reg load HKLM\${HomeDirectoryName}2 "$HomeDirectoryPath\AppData\Local\Microsoft\Windows\UsrClass.dat"
}