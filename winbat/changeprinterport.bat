reg query "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports" | findstr 32. > printerports.txt

FOR /F "tokens=*" %%X IN (printerports.txt) DO (
	reg copy "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports\IP_172.16.32.%%X" "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports\IP_172.16.44.%%X"
	reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports\IP_172.16.44.%%X" /v IPAddress /t REG_SZ /d 172.16.44.%%X /f
)