#-------------------------------------------#
#Creating User for Exchange 2010#
#-------------------------------------------#

Add-PSSnapin Microsoft.Exchange.Management.Powershell.E2010
Import-Module ActiveDirectory

#Parameters:
#Domain to use
$domain = "tpcloud.com.au"
#Default password to use
$password = "P@ssword123"

#Source:
New-Mailbox -Name 'Mike Horwath' -Alias 'tenant00001_mike' -OrganizationalUnit 'hosted.exchange/Habitats/Tenant00001' -UserPrincipalName 'mike@zsmtp.net' -SamAccountName 'tenant00001_mike' -FirstName 'Mike' -LastName 'Horwath' -Password $c.password -ResetPasswordOnNextLogon $false -AddressBookPolicy 'Tenant00001'
 
Set-Mailbox mike@zsmtp.net -CustomAttribute1 "Tenant00001"

write-host “DONE!”



OU=Flinders Reproductive Medicine,OU=Microsoft Exchange Hosted Organizations,DC=tpcloud,DC=com,DC=au


$c = Get-Credential