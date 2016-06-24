$filepath = 'c:\supports\Daily_Check_ShortVer.ps1'

$trigger = New-JobTrigger -Daily -At "9:00AM"

$opt = New-ScheduledJobOption -RequireNetwork

Register-ScheduledJob -FilePath $filepath -Trigger $trigger -Name "DailyCheck" -ScheduledJobOption $opt