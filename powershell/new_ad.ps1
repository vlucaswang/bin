
$Users = Import-Csv -Path "C:\Userlist-sn.csv"            
foreach ($User in $Users)            
{            
    $Displayname = $User.'Firstname' + " " + $User.'Lastname'            
    $UserFirstname = $User.'Firstname'            
    $UserLastname = $User.'Lastname'            
    $OU = $User.'OU'            
    $SAM = $User.'SAM'            
    $UPN = $User.'Firstname' + "." + $User.'Lastname' + "@" + $User.'Maildomain'            
    $Description = $User.'Description'            
    $Password = $User.'Password'            
    New-ADUser -Name "$Displayname" -DisplayName "$Displayname" -SamAccountName $SAM -UserPrincipalName $UPN -GivenName "$UserFirstname" -Surname "$UserLastname" -Description "$Description" -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -Path "$OU" -ChangePasswordAtLogon $false –PasswordNeverExpires $true -server domain.loc            
}