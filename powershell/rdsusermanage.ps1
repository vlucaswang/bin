$Users = ([ADSISearcher]"(&(objectCategory=person)(objectClass=user))").findall() | select path
 foreach ($user in $users) {
 $userSearch = [adsi]"$($user.path)"
 # $userSearch.psbase.InvokeGet("displayname")
 $userSearch.psbase.InvokeGet("terminalservicesprofilepath")
 }

 Get-ADUser -SearchBase "OU=Pirie Medical,DC=piriemedical,DC=local" -Filter * -Properties profilePath | Select SamAccountName, profilePath | Format-Table -AutoSize