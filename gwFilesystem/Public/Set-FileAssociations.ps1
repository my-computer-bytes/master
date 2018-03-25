<#######<Script>#######>
<#######<Header>#######>
# Name: Set-FileAssociations
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-FileAssociations
{
    <#
.Synopsis
Sets file associations in Windows using the assoc and ftype commands.
.Description
Sets file associations in Windows using the assoc and ftype commands.
.Parameter Fileextensions
Mandatory. This string or set of strings defines the file extensions you want to associate with a program.
.Parameter OpenAppPath
Mandatory. This string defines the path to a program.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Set-FileAssociations -Fileextensions .Png, .Jpeg, .Jpg -Openapppath "C:\Program Files\Imageglass\Imageglass.Exe"
Sets file associations in Windows using the assoc and ftype commands.
In this case, the extensions ".png, .jpeg, and .jpg" are associated with a program called ImageGlass.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>   
    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]$Fileextensions,
        
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$Openapppath,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-FileAssociations.Log"
    )

    Begin
    {
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    
    }
    
    Process
    {   
        If (-Not (Test-Path $Openapppath))
        {
            Log "$Openapppath Does Not Exist." -Color Darkred -Error
        }   
        
        Foreach ($Extension In $Fileextensions)
        {
            $Filetype = (cmd /c "Assoc $Extension")
            $Filetype = $Filetype.Split("=")[-1] 
            cmd /c "ftype $Filetype=""$Openapppath"" ""%1"""
            Log "$Fileextensions set for $Filetype" 
        }               
    }

    End
    {
        Stop-Log  
    }

}   

# Set-FileAssociations -Fileextensions .Png, .Jpeg, .Jpg -Openapppath "C:\Program Files\Imageglass\Imageglass.Exe"

<#######</Body>#######>
<#######</Script>#######>