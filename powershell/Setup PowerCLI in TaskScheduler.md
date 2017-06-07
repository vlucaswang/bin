PRE PowerCli 6:

Program/script:

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

Add arguments (optional):

-PSConsoleFile “C:Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\vim.psc1” -command “&{Z:\ScriptFolder\ScriptName.ps1}”

 

POST PowerCli 6:

Program/script:

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

Add arguments (optional):

-c “. \”C:Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1\” $true; C:\ScriptFolder\ScriptName.ps1″