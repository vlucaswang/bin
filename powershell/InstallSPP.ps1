Mount-DiskImage \"%CD%\871790_001_spp-2016.10.0-SPP2016100.2016_1015.1910.iso\"

start-process -FilePath ".\launch_hpsum.bat" -ArgumentList "/silent /logdir 'c:\hpvs\logs\spp.log'"  -wait -NoNewWindow

restart-computer