#See who left their RDP sessions open and kick them if need be

$ServerName = Get-Content "C:\Users\USER\Desktop\ServerList.txt"

Function Disconnect-RDPSessions {
Param (
    [Parameter(Mandatory=$true, HelpMessage="List one server needing an RDP session kicked")]    
    [string]$ServerToDisconnect, 
    [Parameter(Mandatory=$true, HelpMessage="Specify the ID of session needing kicked")]
    [string]$RDPSessionID
)
If ("y", "Y" -contains $YesOrNo)
    {
        $Query = (rwinsta /server:$ServerToDisconnect $RDPSessionID)
        $YesOrNo = Read-Host -Prompt "Do you want to disconnect anymore RDP sessions? Y/N"
        If ("y", "Y" -contains $YesOrNo){Disconnect-RDPSessions}
    }
}

Write-host "`nActive RDP Sessions" -ForegroundColor White
Write-host "-------------------" -ForegroundColor White
$i = $null
ForEach ($Server in $ServerName)
    {
        $Query = (qwinsta /server:$Server) | ? { $_ -match '^[ >](\S+) +(\S*?) +(\d+) +(\S+)' } |
            select @{n='Service';e={$matches[1]}},
            @{n='Username';e={$matches[2]}}, 
            @{n='ID';e={$matches[3]}},
            @{n='Status';e={$matches[4]}} | % {
            $_.USERNAME 
            If ($_.USERNAME -ne '') 
                {
                    $i = 'rdpfound'; Write-host $Server ' - ' $_.USERNAME ' - ' $_.ID -ForegroundColor Cyan
                }
    }
}

If ($i -ne 'rdpfound') {write-host "No Active RDP Sessions Found"}
elseif ($i -eq 'rdpfound') 
{
   $YesOrNo = Read-Host -Prompt "Do you want to disconnect any RDP sessions? Y/N"
   If ("y", "Y" -contains $YesOrNo){Disconnect-RDPSessions}
}