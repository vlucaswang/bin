$logpath = "c:\supports\dailycheck"
$logfile = "tp_simple_log_$(Get-Date -f dd-MM-yyyy).csv"

if (Test-Path $logpath\$logfile) {
    clear-content $logpath\$logfile
}
else {
    md -Force $logpath | out-null
}

function CheckDiskFreePercent {
$percentWarning = 15;
$disk_state = "OK"
$disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $env:computername -Filter "DriveType = 3"
foreach($disk in $disks)
    {
    $disksize = $disk.Size/1gb;
    $diskfreespace = $disk.FreeSpace/1gb; 
    $percentFree = [Math]::Round(($diskfreespace / $disksize) * 100, 2);
    if($percentFree -lt $percentWarning)
        {
        $disk_state = "Failed";
        }
    }
[System.IO.File]::AppendAllText("$logpath\$logfile", $disk_state, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
}

function CheckAutoServiceState {
$servicevalue = Get-WmiObject -Class win32_service -ComputerName $env:computername -Filter "startmode = 'auto' AND state != 'running' AND name != 'sppsvc' AND name != 'RemoteRegistry' AND name != 'W32Time' AND name != 'gupdate' AND name != 'TSGateway' AND name != 'TBS'" | Select Name, State, ExitCode
[System.IO.File]::AppendAllText("$logpath\$logfile", ($servicevalue | measure).Count, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
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
    $drive_state_exec = & $drive_state 'ctrl all show config' | Where-Object { $_ } | select-string -pattern Failed,Recover,Failure,Rebuilding
    if ($drive_state_exec -ne $null) {
        $array_state = "Failed"
    }
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $array_state, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
}

function CheckShadowCopy {
$Output = @()
$vss_state = "OK"
$Volumes = gwmi Win32_Volume -Property SystemName,DriveLetter,DeviceID,Capacity,FreeSpace -Filter "DriveType=3" -ComputerName $env:computername |
                Select SystemName,@{n="DriveLetter";e={$_.DriveLetter.ToUpper()}},DeviceID,@{n="CapacityGB";e={([math]::Round([int64]($_.Capacity)/1GB,2))}},@{n="FreeSpaceGB";e={([math]::Round([int64]($_.FreeSpace)/1GB,2))}} | Sort DriveLetter
$ShadowCopies = gwmi Win32_ShadowCopy -Property VolumeName,InstallDate,Count -ComputerName $env:computername |
    Select VolumeName,InstallDate,Count,@{n="CreationDate";e={$_.ConvertToDateTime($_.InstallDate)}}
If($Volumes)
{
    ForEach($Volume in $Volumes)
    {
        $VolumeShadowCopies = $Null
        $VolumeShadowCopies = $ShadowCopies | ?{$_.VolumeName -eq $Volume.DeviceID} | Sort InstallDate
        $Object = New-Object psobject
        $Object | Add-Member NoteProperty DriveLetter $Volume.DriveLetter -PassThru | Add-Member NoteProperty LatestShadowCopy "" -PassThru | Add-Member NoteProperty TimeShadowCopy ""
        If($VolumeShadowCopies)
        {   $Object.LatestShadowCopy = (($VolumeShadowCopies | Select -Last 1).CreationDate)
            $Object.TimeShadowCopy =  ((Get-Date) - (($VolumeShadowCopies | Select -Last 1).CreationDate)).Days
                    If($Object.TimeShadowCopy -gt 0) {
            $vss_state = "Failed"
        }
        else {
            $vss_state = "NONE"
        }
        }
    }
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $vss_state, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
}

function CheckShadowProtect {
$sp_state = "OK"
$sp_job_state = Get-EventLog -Computername $env:computername -LogName "Application" -After (get-date).AddDays(-1) | Where-Object {$_.EventID -eq 1120 -or $_.EventID -eq 1121 -or $_.EventID -eq 1122 -and $_.Source -eq "ShadowProtectSvc" -and (Get-Date $_.TimeWritten) -gt ((Get-Date).AddHours(-24))} | select -first 1 | select-string -pattern "Failed"
if ($sp_job_state -ne $null) {
    $sp_state = "Failed"
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $sp_state, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
}

function CheckLanSafe {
$ls_state = "OK"
$ls_log_state = Get-EventLog -Computername $env:computername -LogName "Application" -EntryType Error,Warning -After (get-date).AddDays(-1) | Where-Object {$_.Source -eq "LanSafe PM" -and (Get-Date $_.TimeWritten) -gt ((Get-Date).AddHours(-24))} | select -first 1
if ($ls_log_state -ne $null) {
    $ls_state = "Failed"
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $ls_state, [System.Text.Encoding]::Unicode)
}

function CheckESETUpdate {
$eset_state = "OK"
$key = "HKLM:\software\eset\eset security\currentversion\info"
$string = (Get-ItemProperty -Path $key -Name ScannerVersion).ScannerVersion
$string -match ".?\((.*?)\).*" | Out-Null
$dbdate = $matches[1]

if ($dbdate -ne (Get-Date -format yyyyMM)) {
    $eset_state = "Failed"
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $eset_state, [System.Text.Encoding]::Unicode)
}

function CheckMDref {
$mdref_state = "OK"
$update_date = (-split (get-content "C:\Users\lucasw\Desktop\server check\HcnContentUpdate.LOG" | select-string  'update successful' | select-object -last 1) | select -first 1)
$diff_date = ((Get-Date) - (Get-Date $update_date)).Days

if ($diff_date -gt 15) {
    $mdref_state = "Failed"
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $mdref_state, [System.Text.Encoding]::Unicode)
}

function UploadToFTP {
$ftpurl = "ftp://52.62.250.69:19897/dir/"
$ftpuser = "user"
$ftppass = "pass"

$webclient = New-Object System.Net.webclient
$webclient.Credentials = New-Object System.Net.NetworkCredentials($ftpuser,$ftppass)
$uri = New-Object System.Uri($ftpurl+$logfile)
$weblclient.UploadFile($uri, "$logpath\$logfile")
}


CheckDiskFreePercent
CheckAutoServiceState
CheckSmartArray
CheckShadowCopy
CheckShadowProtect
CheckLanSafe
CheckESETUpdate
CheckMDref
#UploadToFTP

notepad $logpath\$logfile