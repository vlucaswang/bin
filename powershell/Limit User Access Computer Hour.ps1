$QUser = Query User

For ($i=1;$i -le $Quser.Count-1;$i++)
{
    #Get Current User Name
	$user =$QUser[$i].Split(" ")[0].Split(">")[1]
    #Get Current User Logon Time
    $time = [DateTime]($QUser[$i].Split("-")[2].Split(" ")[1])

    #If Current User is not Admin and Logon hour>2, disable the account
    IF(($user -ne "Administrator")-and (((Get-Date)-$time).Totalhours -get 0.1))
    {
        #Prompt User is being logged out after 1 minutes
        $vbs = New-Object -ComObject WScript.Shell
        $vbs.popup("Will be logged out after 1 minutes, please save data.",5,"Prompt")
        #Delay 60 seconds
        Start-Sleep -Seconds 60
        #Disable Current User
        $userc = gwmi win32_useraccount | where {$_.name -eq $user}
        $userc.Disabled = $true
        $userc.put()
        #Logged Out
        shutdowm -l
    }
}