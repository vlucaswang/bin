$mountResult = Mount-DiskImage \"%CD%\en_windows_server_2012_r2_with_update_x64_dvd_4065220.iso\" -PassThru
$driveLetter = ($mountVolume | Get-Volume).DriveLetter

Import-Module Servermanager
Import-Clixml .\Server2012R2roles.xml | Add-WindowsFeature -Source $driveLetter:\Sources\SxS

restart-computer