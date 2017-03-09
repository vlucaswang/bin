<#
The sample scripts are not supported under any Microsoft standard support 
program or service. The sample scripts are provided AS IS without warranty  
of any kind. Microsoft further disclaims all implied warranties including,  
without limitation, any implied warranties of merchantability or of fitness for 
a particular purpose. The entire risk arising out of the use or performance of  
the sample scripts and documentation remains with you. In no event shall 
Microsoft, its authors, or anyone else involved in the creation, production, or 
delivery of the scripts be liable for any damages whatsoever (including, 
without limitation, damages for loss of business profits, business interruption, 
loss of business information, or other pecuniary loss) arising out of the use 
of or inability to use the sample scripts or documentation, even if Microsoft 
has been advised of the possibility of such damages.
#> 

#requires -Version 2
Function Remove-OSCSID
{   
<#
		.SYNOPSIS
		Function Remove-OSCSID is an advanced function which can reomve the orphaned SID from file/folders ACL.
		.DESCRIPTION
		Function Remove-OSCSID is an advanced function which can reomve the orphaned SID from file/folders ACL.
		.PARAMETER Path
		Indicates the path of the specified file or folder.
		.PARAMETER Recurse
		Indicates check the child items of the specified folder.
		.EXAMPLE
		Remove-OSCSID  -path C:\acls.txt
		
		Remove orphaned SIDs from C:\acls.txt
		.EXAMPLE
		Remove-OSCSID  -Path C:\test -Recurse
		
		Remove orphaned SIDs from all the files/folders ACL of C:\test
		.LINK
		Windows PowerShell Advanced Function
		http://technet.microsoft.com/en-us/library/dd315326.aspx
		.LINK
		Get-Acl
		http://technet.microsoft.com/en-us/library/hh849802.aspx
		.LINK
		Set-Acl
		http://technet.microsoft.com/en-us/library/hh849810.aspx
	#>

	[CmdletBinding()]
	Param
	(
		#Define parameters
		[Parameter(Mandatory=$true,Position=1)]
		[String]$Path,		
		[Parameter(Mandatory=$false,Position=2)]
		[Switch]$Recurse
	)
	#Try to get the object ,and define a flag to record the count of orphaned SIDs 
    Try
	{
		if(Test-Path -Path $Path)
		{ 
			$count = 0
			#If the object is a folder and the "-recurse" is chosen ,then get all of the folder childitem,meanwhile store the path into an array folders
			if ($Recurse) 
	    	{		
		 		$folders = Get-ChildItem -Path $path -Recurse 
		 		#For-Each loop to get the ACL in the folders and check the orphaned SIDs 
		 		ForEach ($folder in $folders)
				{
		   			$PSPath = $folder.fullname 
		   			DeleteSID($PSPath)	
				}
			}
			else
			#The object is a file or the "-recurse" is not chosen,check the orphaned SIDs .
			{
				$PSPath =$path
				DeleteSID($PSPath)	
			}	
		}
		else
		{
			Write-Error "The path is incorrect"
		}
	}	
	catch
	{
	 	Write-Error $Error
	}
}

Function DeleteSID([string]$path)
{  
  	try
  	{
   		#This function is used to delete the orphaned SID 
   		$acl = Get-Acl -Path $Path
   		foreach($acc in $acl.access )
   		{
   			$value = $acc.IdentityReference.Value
   			if($value -match "S-1-5-*")
   			{
   				$ACL.RemoveAccessRule($acc) | Out-Null
   				Set-Acl -Path $Path -AclObject $acl -ErrorAction Stop
   				Write-Host "Remove SID: $value  form  $Path "
   			}
   		}
  	}
   	catch
   	{
   		Write-Error $Error
   	}
}
	
