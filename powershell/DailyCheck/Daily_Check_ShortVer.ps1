$logpath = "c:\supports\dailycheck"
$logfile = "tp_simple_log_$(Get-Date -f dd-MM-yyyy).csv"

md -Force $logpath | out-null

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
$service_state = "OK"
$servicevalue = Get-WmiObject -Class win32_service -ComputerName $env:computername -Filter "startmode = 'auto' AND state != 'running'" | Select Name, State, ExitCode
if(@($servicevalue | measure).Count -gt 0) {
	$service_state = "Failed"
	}
[System.IO.File]::AppendAllText("$logpath\$logfile", $service_state, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
}

function CheckSmartArray {
$array_state = "OK"
$drive_state = "C:\Windows\System32\cmd.exe /c 'C:\Program Files (x86)\Compaq\Hpacucli\Bin\hpacucli.exe' controller slot=0 physicaldrive all show | select-string -pattern 'Failed'"
if ($drive_state -ne $null) {
    $array_state = "Failed"
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $array_state, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
}

function CheckShadowCopy {
$Output = @()
$vss_state = "OK"
$Volumes = gwmi Win32_Volume -Property SystemName,DriveLetter,DeviceID,Capacity,FreeSpace -Filter "DriveType=3" -ComputerName $env:computername |
                Select SystemName,@{n="DriveLetter";e={$_.DriveLetter.ToUpper()}},DeviceID,@{n="CapacityGB";e={([math]::Round([int64]($_.Capacity)/1GB,2))}},@{n="FreeSpaceGB";e={([math]::Round([int64]($_.FreeSpace)/1GB,2))}} | Sort DriveLetter
$ShadowStorage = gwmi Win32_ShadowStorage -Property AllocatedSpace,DiffVolume,MaxSpace,UsedSpace,Volume -ComputerName $env:computername |
    Select @{n="Volume";e={$_.Volume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
    @{n="DiffVolume";e={$_.DiffVolume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
    @{n="AllocatedSpaceGB";e={([math]::Round([int64]($_.AllocatedSpace)/1GB,2))}},
    @{n="MaxSpaceGB";e={([math]::Round([int64]($_.MaxSpace)/1GB,2))}},
    @{n="UsedSpaceGB";e={([math]::Round([int64]($_.UsedSpace)/1GB,2))}}
$ShadowCopies = gwmi Win32_ShadowCopy -Property VolumeName,InstallDate,Count -ComputerName $env:computername |
    Select VolumeName,InstallDate,Count,
    @{n="CreationDate";e={$_.ConvertToDateTime($_.InstallDate)}}
$Shares = gwmi win32_share -Property Name,Path -ComputerName $env:computername | Select Name,@{n="Path";e={$_.Path.ToUpper()}}
If($Volumes)
{
    ForEach($Volume in $Volumes)
    {
        $VolumeShares = $VolumeShadowStorage = $DiffVolume = $VolumeShadowCopies = $Null
        If($Volume.DriveLetter -ne $Null){[array]$VolumeShares = $Shares | ?{$_.Path.StartsWith($Volume.DriveLetter)}}
        $VolumeShadowStorage = $ShadowStorage | ?{$_.Volume -eq $Volume.DeviceID}
        If($VolumeShadowStorage){$DiffVolume = $Volumes | ?{$_.DeviceID -eq $VolumeShadowStorage.DiffVolume}}
        $VolumeShadowCopies = $ShadowCopies | ?{$_.VolumeName -eq $Volume.DeviceID} | Sort InstallDate
        $Object = New-Object psobject
        $Object | Add-Member NoteProperty DriveLetter $Volume.DriveLetter -PassThru | Add-Member NoteProperty LatestShadowCopy "" -PassThru | Add-Member NoteProperty TimeShadowCopy ""
        If($VolumeShadowCopies)
        {   $Object.LatestShadowCopy = (($VolumeShadowCopies | Select -Last 1).CreationDate)
            $Object.TimeShadowCopy =  ((Get-Date) - (($VolumeShadowCopies | Select -Last 1).CreationDate)).Days
                    If($Object.TimeShadowCopy -gt 0) {
            $vss_state = "Failed"
        }
        }
        If($VolumeShadowStorage -Or $ShowAllVolumes){$Output += $Object}
    }
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $vss_state, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
}

function CheckShadowProtect {
$sc_state = "OK"
$sc_job_state = Get-EventLog -Computername $env:computername -LogName "Application" -After (get-date).AddDays(-1) | Where-Object {$_.EventID -eq 1120 -or $_.EventID -eq 1121 -or $_.EventID -eq 1122 -and $_.Source -eq "ShadowProtectSvc" -and (Get-Date $_.TimeWritten) -gt ((Get-Date).AddHours(-12))} | select -first 1 | select-string -pattern "Failed"
if ($sc_job_state -ne $null) {
    $sc_state = "Failed"
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $sc_state, [System.Text.Encoding]::Unicode)
[System.IO.File]::AppendAllText("$logpath\$logfile", ',', [System.Text.Encoding]::Unicode)
}

function CheckLanSafe {
$ls_state = "OK"
$ls_log_state = Get-EventLog -Computername $env:computername -LogName "Application" -EntryType Error,Warning -After (get-date).AddDays(-1) | Where-Object {$_.Source -eq "LanSafe PM" -and (Get-Date $_.TimeWritten) -gt ((Get-Date).AddHours(-12))} | select -first 1
if ($ls_log_state -ne $null) {
    $ls_state = "Failed"
}
[System.IO.File]::AppendAllText("$logpath\$logfile", $ls_state, [System.Text.Encoding]::Unicode)
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
#UploadToFTP
