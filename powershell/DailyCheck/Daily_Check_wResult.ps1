#Force execution of non-signed script
Set-ExecutionPolicy Bypass -Force
#Ignore all errors during script execution
$ErrorActionPreference = 'silentlycontinue'

########################################################################################################
#If Powershell is running the 32-bit version on a 64-bit machine, we need to force powershell to run in
#64-bit mode to allow the OleDb access to function properly.
########################################################################################################
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}

function CheckDiskFreePercent {
$percentWarning = 15;
$disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $env:computername -Filter "DriveType = 3"
foreach($disk in $disks)
    {
    $disk_state = "OK"
    $disksize = $disk.Size/1gb;
    $diskfreespace = $disk.FreeSpace/1gb; 
    $percentFree = [Math]::Round(($diskfreespace / $disksize) * 100, 0);
    if($percentFree -lt $percentWarning)
        {
        $disk_state = "Failed";
        }
    Write-Host $disk.DeviceID $percentFree% $disk_state
}
}

function CheckAutoServiceState {
$servicevalue = Get-WmiObject -Class win32_service -ComputerName $env:computername -Filter "startmode = 'auto' AND state != 'running' AND name != 'sppsvc' AND name != 'RemoteRegistry' AND name != 'W32Time' AND name != 'gupdate' AND name != 'TSGateway' AND name != 'TBS'" | Select Name, State, ExitCode
if ($servicevalue -eq $null) {
    $servicevalue = "OK"
}
$servicevalue
}

function GetHPcliPath () {
$programPaths = (
    'C:\Program Files\HP\Hpacucli\Bin\hpacucli.exe',
    'C:\Program Files\Compaq\Hpacucli\Bin\hpacucli.exe',
    'C:\Program Files (x86)\HP\Hpacucli\Bin\hpacucli.exe',
    'C:\Program Files (x86)\Compaq\Hpacucli\Bin\hpacucli.exe',
    'C:\Program Files\hp\hpssacli\bin\hpssacli.exe',
    'C:\Program Files\Smart Storage Administrator\ssacli\bin\ssacli.exe'
);
foreach ($path in $programPaths) {
    if (Test-Path $path) {
        return $path
    }
}
return $false
}

function CheckSmartArray {
$array_state = "OK"
$drive_state = GetHPcliPath
if ($drive_state -eq $false) {
    $array_state = "NONE"
}
else {
    $drive_state_exec = & $drive_state 'ctrl all show config'
    $drive_state_exec_fl = $drive_state_exec | Where-Object { $_ } | select-string -pattern Failed,Recover,Failure,Rebuilding
    if ($drive_state_exec_fl -ne $null) {
        $array_state = "Failed"
    }
}
$drive_state_exec
Write-Host $array_state
}

function CheckLanSafe {
$ls_state = "OK"
$ls_log_state = Get-EventLog -Computername $env:computername -LogName "Application" -EntryType Error,Warning -After (get-date).AddDays(-1) | Where-Object {$_.Source -eq "LanSafe PM" -and (Get-Date $_.TimeWritten) -gt ((Get-Date).AddHours(-24))} | select -first 1
if ($ls_log_state -ne $null) {
    $ls_state = "Failed"
}
Write-Host $ls_log_state, $ls_state
}

function CheckShadowProtect {
$sp_state = "OK"
$sp_job_state = Get-EventLog -Computername $env:computername -LogName "Application" -After (get-date).AddDays(-1) | Where-Object {$_.EventID -eq 1120 -or $_.EventID -eq 1121 -or $_.EventID -eq 1122 -and $_.Source -eq "ShadowProtectSvc" -and (Get-Date $_.TimeWritten) -gt ((Get-Date).AddHours(-24))} | select -first 1
$sp_job_state_fl = $sp_job_state | select-string -pattern "Failed"
if ($sp_job_state_fl -ne $null) {
    $sp_state = "Failed"
}
Write-Host $sp_job_state, $sp_state
}

#TESTING
function CheckShadowProtectReg {
$query1 = reg query HKEY_LOCAL_MACHINE\System\CurrentControlSet\services\ShadowProtectSvc\Parameters\Jobs
$query2 = reg query $query1\Tasks
Foreach ($result in $query2) { #REG RESULTS
    $query3 = reg query $result
    echo $query3 >> drivechktmp.txt
} #END REG RESULTS

#Grab the text out of drivechktmp.txt to parse in the next IF statement
$test = Select-String -Path drivechktmp.txt -Pattern Status
}

function CheckESETUpdate {
$eset_state = "OK"
$key = 'HKLM:\SOFTWARE\ESET\ESET Security\CurrentVersion\Info'
$string = (Get-ItemProperty -Path $key -Name ScannerVersion).ScannerVersion
$string -match ".?\((.*?)\).*" | Out-Null
$dbdate = $matches[1]

if ($dbdate -ne (Get-Date -format yyyyMMdd)) {
    $eset_state = "Failed"
}
Write-Host $dbdate, $eset_state
}

function CheckMDref {
$mdref_state = "OK"
$update_date = (-split (get-content "C:\Users\Public\Documents\HCN\Hcn.Update\HcnContentUpdate.LOG" | select-string  'update successful' | select-object -last 1) | select -first 1)
$diff_date = ((Get-Date) - (Get-Date $update_date)).Days

if ($diff_date -gt 15) {
    $mdref_state = "Failed"
}
Write-Host $update_date, $mdref_state
}

Write-Host "-----------------"
Write-Host CheckDiskFreePercent
CheckDiskFreePercent

Write-Host "-----------------"
Write-Host CheckAutoServiceState
CheckAutoServiceState

Write-Host "-----------------"
Write-Host CheckSmartArray
CheckSmartArray

Write-Host "-----------------"
Write-Host CheckLanSafe
CheckLanSafe

Write-Host "-----------------"
Write-Host CheckShadowProtect
CheckShadowProtect

Write-Host "-----------------"
Write-Host CheckESETUpdate
CheckESETUpdate

Write-Host "-----------------"
Write-Host CheckMDref
CheckMDref

################
# END
################