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
$disk_state
}

function CheckAutoServiceState {
$service_state = "OK"
$servicevalue = Get-WmiObject -Class win32_service -ComputerName $env:computername -Filter "startmode = 'auto' AND state != 'running'" | Select Name, State, ExitCode
if(@($servicevalue | measure).Count -gt 0) {
	$service_state = "Failed"
	}
$service_state
}

function CheckSmartArray {
$array_state = "OK"
$drive_state = C:\Windows\System32\cmd.exe /c "C:\Program Files (x86)\Compaq\Hpacucli\Bin\hpacucli.exe" controller slot=0 physicaldrive all show | select-string -pattern "Failed"
if ($drive_state -ne $null) {
    $array_state = "Failed"
}
$array_state
}

function CheckShadowCopy {
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
    $Output = @()
    ForEach($Volume in $Volumes)
    {
        $VolumeShares = $VolumeShadowStorage = $DiffVolume = $VolumeShadowCopies = $Null
        If($Volume.DriveLetter -ne $Null){[array]$VolumeShares = $Shares | ?{$_.Path.StartsWith($Volume.DriveLetter)}}
        $VolumeShadowStorage = $ShadowStorage | ?{$_.Volume -eq $Volume.DeviceID}
        If($VolumeShadowStorage){$DiffVolume = $Volumes | ?{$_.DeviceID -eq $VolumeShadowStorage.DiffVolume}}
        $VolumeShadowCopies = $ShadowCopies | ?{$_.VolumeName -eq $Volume.DeviceID} | Sort InstallDate
        $Object = New-Object psobject
        $Object | Add-Member NoteProperty SystemName $Volume.SystemName -PassThru | Add-Member NoteProperty DriveLetter $Volume.DriveLetter -PassThru |
            Add-Member NoteProperty CapacityGB $Volume.CapacityGB -PassThru | Add-Member NoteProperty FreeSpaceGB $Volume.FreeSpaceGB -PassThru |
            Add-Member NoteProperty ShareCount "" -PassThru | Add-Member NoteProperty Shares "" -PassThru |
            Add-Member NoteProperty ShadowAllocatedSpaceGB "" -PassThru | Add-Member NoteProperty ShadowUsedSpaceGB "" -PassThru |
            Add-Member NoteProperty ShadowMaxSpaceGB "" -PassThru | Add-Member NoteProperty DiffVolumeDriveLetter "" -PassThru |
            Add-Member NoteProperty DiffVolumeCapacityGB "" -PassThru | Add-Member NoteProperty DiffVolumeFreeSpaceGB "" -PassThru |
            Add-Member NoteProperty ShadowCopyCount "" -PassThru | Add-Member NoteProperty OldestShadowCopy "" -PassThru |
            Add-Member NoteProperty LatestShadowCopy "" -PassThru | Add-Member NoteProperty ShadowAverageSizeGB "" -PassThru | Add-Member NoteProperty ShadowAverageSizeMB ""
        If($VolumeShares)
        {   $Object.ShareCount = $VolumeShares.Count
            If($VolumeShares.Count -eq 1){$Object.Shares = $VolumeShares[0].Name}
            Else{$Object.Shares = [string]::join(", ", ($VolumeShares | Select Name)).Replace("@{Name=", "").Replace("}", "")}
        }
        If($VolumeShadowStorage)
        {   $Object.ShadowAllocatedSpaceGB = $VolumeShadowStorage.AllocatedSpaceGB
            $Object.ShadowUsedSpaceGB = $VolumeShadowStorage.UsedSpaceGB
            $Object.ShadowMaxSpaceGB = $VolumeShadowStorage.MaxSpaceGB
            If($DiffVolume)
            {   $Object.DiffVolumeDriveLetter = $DiffVolume.DriveLetter
                $Object.DiffVolumeCapacityGB = $DiffVolume.CapacityGB
                $Object.DiffVolumeFreeSpaceGB = $DiffVolume.FreeSpaceGB
            }
        }
        If($VolumeShadowCopies)
        {   $Object.ShadowCopyCount = (($VolumeShadowCopies | Measure-Object -Property Count -Sum).Sum)
            $Object.OldestShadowCopy = (($VolumeShadowCopies | Select -First 1).CreationDate)
            $Object.LatestShadowCopy = (($VolumeShadowCopies | Select -Last 1).CreationDate)
            If($VolumeShadowStorage.UsedSpaceGB -gt 0 -And $Object.ShadowCopyCount -gt 0)
            {   $Object.ShadowAverageSizeGB = ([math]::Round($VolumeShadowStorage.UsedSpaceGB/$Object.ShadowCopyCount,2))
                $Object.ShadowAverageSizeMB = ([math]::Round(($VolumeShadowStorage.UsedSpaceGB*1KB)/$Object.ShadowCopyCount,2))
            }
        }
        If($VolumeShadowStorage -Or $ShowAllVolumes){$Output += $Object}
    }
    $Output
}
}

#$servicevalue
#$servicevalue | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Add-Content C:\Temp\"$env:computername"_DetailedReport.csv


#$from = "MailID"
#$to = "MailID"
#$smtp = "SMTP NAME"
#$subject = "Disk Space Report"
#Send-MailMessage -From $from -To $to -SmtpServer $smtp -Subject $subject -Body "Disk Space Report" -Attachments C:\Temp\DiskReport.csv