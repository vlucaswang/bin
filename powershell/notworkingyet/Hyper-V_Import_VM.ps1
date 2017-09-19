Import-Module -Name hyper-V
Get-VMSwitch | Remove-VMSwitch -Confirm
New-VMSwitch -name "Corp" -SwitchType Internal
Import-VM -Path "D:\IT Camp files\Virt-Camp\SCVMM01\Virtual Machines\EA047C67-B887-4679-99BF-95797BAF0DBF.xml" -Register
Grant-VMConnectAccess -UserName administrator -VMName "VIRT - DC01"


netsh advfirewall set allprofiles state off
Enable-PSRemoting
Enable-WSManCredSSP -Role server