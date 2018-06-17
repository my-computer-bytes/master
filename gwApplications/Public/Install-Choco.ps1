<#######<Script>#######>
<#######<Header>#######>
# Name: Install-Choco
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Install-Choco
{
    <#
    .Synopsis
    Installs Chocolatey packages. To be used after "iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex"
    .DESCRIPTION
    Installs Chocolatey packages. To be used after "iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex"
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
    .EXAMPLE
    Install-Choco
    Installs Chocolatey
    .EXAMPLE
    "PC1", "PC2" | Install-Choco
    Installs Chocolatey
    .NOTES
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
    Main code usually starts around line 185ish.
    If -Verbose is not passed (Default) and logfile is not defined, don't show messages on the screen and don't transcript the session.
    If -Verbose is not passed (Default) and logfile is defined, enable verbose for them and transcript the session.
    If -Verbose is passed and logfile is defined, show messages on the screen and transcript the session.
    If -Verbose is passed and logfile is not defined, show messages on the screen, but don't transcript the session.
    2018-06-17: v1.1 Updated template.
    2017-09-08: v1.0 Initial script 
    #>    
    [CmdletBinding()]

    PARAM
    (
        [string]$LogFile = "$PSScriptRoot\..\Logs\Install-Choco.log"
    )

    Begin
    {
        <#######<Default Begin Block>#######>
        Function Write-ToString
        {
            <# 
        .Synopsis
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Description
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Parameter InputObject
        This can be any PSObject that will be converted to string.
        .Parameter Color
        The color in which to display the string on the screen.
        Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, 
        Red, White, and Yellow.
        .Example 
        Write-ToString "Hello Hello"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen and the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen in default text colors.
        .Example 
        Write-ToString "Hello Hello" -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow and to the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Example 
        Write-ToString (cmd /c "ipconfig /all") -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow that shows the computer's IP information.
        The same copy will be in the logfile. 
        The whole point of converting to strings is this works best with tables and such that usually distort in logfiles.
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Notes
        2018-06-13: v1.0 Initial function
        #>
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color
            )
            
            $ConvertToString = Out-String -InputObject $InputObject -Width 100
            
            If ($($Color.Length -gt 0))
            {
                $previousForegroundColor = $Host.PrivateData.VerboseForegroundColor
                $Host.PrivateData.VerboseForegroundColor = $Color
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                $Host.PrivateData.VerboseForegroundColor = $previousForegroundColor
            }
            Else
            {
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
            }
            
        }
        If ($($Logfile.Length) -gt 1)
        {
            $Global:EnabledLogging = $True 
            Set-Variable -Name Logfile -Value $Logfile -Scope Global
            $VerbosePreference = "Continue"
            Function Start-Log
            {
                <#
                .Synopsis
                Function to write the opening part of the logfile.
                .Description
                Function to write the opening part of the logfil.
                It creates the directory if it doesn't exists and then the log file automatically.
                It checks the size of the file if it already exists and clears it if it is over 10 MB.
                If it exists, it creates a header. This function is best placed in the "Begin" block of a script.
                .Notes
                NOTE: The function requires the Write-ToString function.
                2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                2017-10-19: v1.0 Initial function
                #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                # Create parent path and logfile if it doesn't exist
                $Regex = '([^\\]*)$'
                $Logparent = $Logfile -Replace $Regex
                If (!(Test-Path $Logparent))
                {
                    New-Item -Itemtype Directory -Path $Logparent -Force | Out-Null
                }
                If (!(Test-Path $Logfile))
                {
                    New-Item -Itemtype File -Path $Logfile -Force | Out-Null
                }
    
                # Clear it if it is over 10 MB
                [Double]$Sizemax = 10485760
                $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
                If ($($Size.Sum -ge $SizeMax))
                {
                    Get-Childitem $Logfile | Clear-Content
                    Write-ToString "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-ToString "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-ToString "####################<Script>####################"
                Write-ToString "Script Started on $env:COMPUTERNAME"
            }
            Start-Log -Logfile $Logfile -Verbose

            Function Stop-Log
            {
                <# 
                    .Synopsis
                    Function to write the closing part of the logfile.
                    .Description
                    Function to write the closing part of the logfile.
                    This function is best placed in the "End" block of a script.
                    .Notes
                    NOTE: The function requires the Write-ToString function.
                    2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                    2017-10-19: v1.0 Initial function 
                    #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                Write-ToString "Script Completed on $env:COMPUTERNAME"
                Write-ToString "####################</Script>####################"
                Stop-Transcript
            }
        }
        Else
        {
            $Global:EnabledLogging = $False
        }
        <#######</Default Begin Block>#######>
     
        # Load the required module(s) 
        Try
        {
            Import-Module PackageManagement -ErrorAction Stop
        }
        Catch
        {
            Write-ToString "Module 'PackageManagement' was not found, stopping script"
            Exit 1
        }

    }
    
    Process
    {   
        # Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
        Install-PackageProvider NuGet -MinimumVersion '2.8.5.201' -Force
        Install-PackageProvider Chocolatey
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Write-ToString "Setting up repos"

        # Install Packages
        Write-ToString "Installing packages..."
        # choco install googlechrome --confirm --limitoutput
        # choco install flashplayeractivex --confirm --limitoutput
        # choco install flashplayerplugin --confirm --limitoutput
        # choco install 7zip.install --confirm --limitoutput
        # choco install adobeair --confirm --limitoutput
        # choco install jre8 --confirm --limitoutput
        # choco install dotnet3.5 --confirm --limitoutput
        # choco install python2 -y --confirm --limitoutput
        # choco install bleachbit -y --confirm --limitoutput
        # choco install notepadplusplus.install -y --confirm --limitoutput
        # choco install atom -y --confirm --limitoutput
        # choco install firefox -y --confirm --limitoutput
        # choco install vim -y --confirm --limitoutput
        # Set-Alias vim -Value "C:\Program Files (x86)\vim\vim80\gvim.exe"
        # choco install procexp -y --confirm --limitoutput
        # choco install putty -y --confirm --limitoutput
        # choco install virtualbox -y --confirm --limitoutput
        # choco install winscp.install -y --confirm --limitoutput
        # choco install sysinternals -y --confirm --limitoutput
        Clear-Host
        Write-ToString "Installing packages...completed"
        
        Write-ToString "Creating Daily Task To Automatically Upgrade Chocolatey Packages"
        $Taskname = "ChocolateyDailyUpgrade"
        $Taskaction = New-Scheduledtaskaction -Execute C:\Programdata\Chocolatey\Choco.Exe -Argument "Upgrade All -Y"
        $Tasktrigger = New-Scheduledtasktrigger -At 2am -Daily
        # Note about TaskUser, I noticed that you have to put the account name. 
        # If domain account, don't include the domain. int.domain.com\bob.domain would just be bob.domain
        $Taskuser = "ReplaceMe"
        Register-Scheduledtask -Taskname $Taskname -Action $Taskaction -Trigger $Tasktrigger -User $Taskuser
    
    }

    End
    {
        If ($Global:EnabledLogging)
        {
            Stop-Log -Logfile $Logfile
        }
        Else
        {
            $Date = $(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt")
            Write-Output "Function completed at $Date"
        }
    }

}

# Install-Choco

<#######</Body>#######>
<#######</Script>#######>