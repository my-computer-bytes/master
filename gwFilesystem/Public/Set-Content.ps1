﻿<#######<Script>#######>
<#######<Header>#######>
# Name: Set-Content
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-Content
{
    <#
.Synopsis
Adds formatted text to the beginning and end of all text, log, and powershell files in the source directory. 
Make sure to edit the $Preformatting and $Postformatting variables before running it!
.Description
Adds formatted text to the beginning and end of all text, log, and powershell files in the source directory. 
Make sure to edit the $Preformatting and $Postformatting variables before running it!
.Parameter Source
Mandatory parameter that specifies a source directory where your files are located.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Set-Content -Source C:\scripts
Adds formatted text to the beginning and end of all files at c:\scripts.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>   [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-Content.Log"
    )

    Begin
    {
        
        # Edit these extensions to the type of files you want to add content to.
        $Include = @("*.txt", "*.ps1", "*.log")
        
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }
    
    Process
    {    
        
        


        # $Source = Get-Childitem "C:\Test" -Include "$Include" -Recurse
        $Source = Get-Childitem "C:\Test" -Include "$Include"

        Foreach ($File In $Source)
        {

            Log "Processing $File ..." 
            
            # Remember to use the escape character "`" before every dollar sign and ` character. For example `$myVar and ``r``n (new line)
            $Preformatting = @"
Multi-Line
Text
To
Insert
At
Top
"@

            $CurrentFile = Get-Content $File

            $PostFormatting = @"
Multi-Line
Text
To
Insert
At
Bottom
"@

            $Val = -Join $Preformatting, $CurrentFile, $PostFormatting
            Set-Content -Path $File -Value $Val
            Log "$File rewritten successfully"
        }
    }

    End
    {
        Stop-Log  
    }

}

# Set-Content -Source C:\scripts

<#######</Body>#######>
<#######</Script>#######>