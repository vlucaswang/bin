for ($i=0; $i -lt $IPport.length; $i++)
{
Add-PrinterPort -Name $IPport.PortName[$i] -PrinterHostAddress $IPport.PortName[$i] -SNMP 1 -SNMPCommunity public
} 

$printers | ft

for ($i=0; $i -lt $printers.length; $i++)
{
Add-Printer -Name $printers.Name[$i] -DriverName $printers.DriverName[$i] -PortName $printers.PortName[$i] -ShareName $printers.ShareName[$i] -Comment $printers.Comment[$i] -Location $printers.Location[$i] -Shared
}