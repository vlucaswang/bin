function Get-PortInfo
{
[CmdletBinding()]
Param
(
[parameter(Mandatory=$true)]
[String]
$ServerName
)
$PortInfo = (Get-PrinterPort -ComputerName $ServerName -Verbose | select -Property HostName,
PrinterName, PortMonitor, PrinterHostIP, Name, LprQueueName,
PortNumber, PrinterHostAddress, SNMPCommunity , SNMPEnabled, SNMPIndex,
Description, Protocol) | export-csv -Path c:Temp"$ServerName"Ports.csv
}

function Get-PrintInfo
{
[CmdletBinding()]
Param
(
[parameter(Mandatory=$true)]
[String]
$ServerName
)
$PrintInfo = (Get-Printer -ComputerName $ServerName -Verbose | Select-Object -Property Name, ShareName,
Location, Comment, PortName, DriverName) | export-csv -Path c:Temp"$ServerName"Printers.csv
}