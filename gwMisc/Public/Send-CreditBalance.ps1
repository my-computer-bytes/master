<#######<Script>#######>
<#######<Header>#######>
# Name: Send-CreditBalance
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Send-CreditBalance
{
    <#
.Synopsis
Function to send credit card balance by text message daily based on email alerts from bank.
.Description
Function to send credit card balance by text message daily based on email alerts from bank. 
Requires that you set your bank to send you "Available Credit" emails daily.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
.Example
Send-CreditBalance
Sends a text message of the daily credit balance.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-CreditBalance.log"
    )
    
    Begin
    {       
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Console
        Start-Log 
    }
    
    Process
    {   

        # See https://www.gerrywilliams.net/2018/01/using-powershell-to-access-gmail-api/
        # Get Access Token
        $clientId = "(Your Client ID)";
        $secret = "(Your Secret)";
        $redirectURI = "urn:ietf:wg:oauth:2.0:oob";
        $refreshToken = "(Your refresh token)";
        $refreshTokenParams = @{
            client_id     = $clientId;
            client_secret = $secret;
            refresh_token = $refreshToken;
            grant_type    = 'refresh_token';
        }
        $refreshedToken = Invoke-WebRequest -Uri "https://accounts.google.com/o/oauth2/token" -Method POST -Body $refreshTokenParams | ConvertFrom-Json
        $accesstoken = $refreshedToken.access_token
        
        # Initialize counter variables
        $Results = 0
        # Create a counter variable that if, equals 0, means no emails matched.
        $Counter = 0
        
        # Get all emails
        $Request = Invoke-WebRequest -Uri "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken" -Method Get | ConvertFrom-Json
        $messages = $($Request.messages)
        Log "Found $($messages.count) messages to go through"
        
        ForEach ($message in $messages)
        {
            $a = $($message.id)
            $b = Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a" + "?access_token=$accesstoken") -Method Get | ConvertFrom-Json
            # Find emails from bank
            Log "Message Subject : $($b.snippet)"
            Log "Seeing if this message matches the automated email we are looking for"
            # Here we are parsing the subject line of the email for our last four of our account number
            If ($($b.snippet) -match "(Your Account Number)")
            {
                Log "Matched"
                # Increment counter for email sending at the bottom
                $Counter += 1
                # Gets the Base64 message and decrypts it
                $c = $b.payload.parts.body.data[0]
                $d = $c.Replace('-', '+').Replace('_', '/')
                [String]$e = [System.Text.Encoding]::Ascii.GetString([System.Convert]::FromBase64String($d))
                
                #Places decrypted email in a single block of text. Searches for the balance and places in a variable.
                $f = $e -Replace '\s', ''
                $g = $f.IndexOf('$')
                $h = $f.Substring($g, 11)
                $i = $h -match '\$(.*)[V]'
                $j = $matches[1] -as [single]
                Log "Amount extracted from email: $j"
                
                # Here I have two credit cards. One with called 'Bills CC' with a Credit limit of 4500 and another 'Purchasing CC' with a credit limit of 10500
                If ($f -match "(Last four of Purchaing CC Credit card account number)")
                {
                    $k = 10500 - $j
                    $l = "Purchasing CC"
                }
                Else
                {
                    $k = 4500 - $j
                    $l = "Bills CC"
                }
                $matches = $null
                Log "Card: $l"
                Log "Amount to add to total: `$$k"
                [single]$Results += $k
                # Move to trash so it won't confuse the script for the next day
                Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken") -Method Post
            }
            Else
            {
                Log "Didn't match"
                $Counter += 0
            }
        }
        Log "Total charged: `$$Results"

        # Generate all paydays for the year
        [DateTime] $StartDate = "2018-01-05"
        [Int]$DaysToSkip = 14
        [DateTime]$EndDate = "2018-12-31"
        $Arr = @()
        while ($StartDate -le $EndDate) 
        {
            $Arr += $StartDate 
            $StartDate = $StartDate.AddDays($DaysToSkip)
        }

        # Remove all paydays less than today and place in new array
        $NewArr = @()
        ForEach ($Ar in $Arr)
        {
            $s = (Get-Date)
            $e = $Ar
            $Difference = New-TimeSpan -Start $s -End $e
            If ( $Difference -ge 1)
            {
                $NewArr += $Ar
            }
        }

        # Select the first one
        $ClosestPayday = $NewArr[0].ToString("yyyy-MM-dd")

        # Calculate how many days from now until payday
        $Span = New-TimeSpan -Start (Get-Date) -End $NewArr[0]

        # Round up one because there is always a whole number and some change
        $DaysTilPayday = ($Span.Days + 1).ToString()
        
        # Add in recurring bills.
        <#
        Bills: Day - Bill - Amount
        1 - Internet - $100
        14 - Internet Streaming - $12
        15 - Water - $130
        22 - Cell Phone - $40
        23 - Internet Streaming - $11
        26 - Electric - $170
        28 - Auto Ins. - $233
        #>
        
        $DayofMonth = $($(Get-Date).Day)
        # Ignore Internet because it's already charged. Add Internet Streaming + Water bills until they are paid.
        If (($DayofMonth -ge 1) -And ($DayofMonth -le 13))
        {
            $ResultsWithBills = $Results + 142
            $UpcomingBills = '14 - Internet Streaming - $12<br>'
            $UpcomingBills += '15 - Water - $130<br>'
        }
        # Bills should be paid by now, don't add anything
        If (($DayofMonth -ge 14) -And ($DayofMonth -le 15))
        {
            $ResultsWithBills = $Results
        }
        # Still have rest of the months bills coming, credit card should be paid off (hopefully)
        If (($DayofMonth -ge 16) -And ($DayofMonth -le 22))
        {
            $ResultsWithBills = $Results + 458
            $UpcomingBills = '22 - Cell Phone - $40<br>'
            $UpcomingBills += '23 - Internet Streaming - $11<br>'
            $UpcomingBills += '26 - Electric - $170<br>'
            $UpcomingBills += '28 - Auto Ins. - $233'
        }
        # Take off Internet Streaming and Cell Phone from the balance
        If (($DayofMonth -ge 23) -And ($DayofMonth -le 26))
        {
            $ResultsWithBills = $Results + 403
            $UpcomingBills = '26 - Electric - $170<br>'
            $UpcomingBills += '28 - Auto Ins. - $233'
        }
        # Take off Electric
        If (($DayofMonth -ge 27) -And ($DayofMonth -le 28))
        {
            $ResultsWithBills = $Results + 233
            $UpcomingBills = '28 - Auto Ins. - $233'
        }
        # Finally, take off Auto Ins
        If (($DayofMonth -ge 28) -And ($DayofMonth -le 31))
        {
            $ResultsWithBills = $Results
            $UpcomingBills = '1 - Internet - $100'
        }

        $Budget = 1200 - $Results
        $RealisticBudget = 1200 - $ResultsWithBills
        Log "Budget: `$$Budget"
        Log "RealisticBudget: `$$RealisticBudget"
        ###########

        # Build creds
        # see https://www.gerrywilliams.net/2016/05/using-passwords-with-powershell/
        $User = "me@gmail.com"
        $PasswordFile = "$Psscriptroot\AESpassword.txt"
        $KeyFile = "$Psscriptroot\aes.key"
        $Key = Get-Content $KeyFile
        $Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $Key)

        # Send to emails
        
        If ($Counter -ge 1)
        {
            $From = "me@gmail.com"
            $To = "someone@gmail.com"
            $Subject = "Daily Budget Automated Task"
            $Body = '<p style="color:#006400"><b>Next payday:</b></p>' + $ClosestPayday + '<br><br>'
            $Body += '<p style="color:#006400"><b>Days until payday</b></p>' + $DaysTilPayday + '<br><br>'
            $Body += '<p style="color:#006400"><b>Budget before payday:</b></p>$' + $RealisticBudget + '<br><br>'
            $Body += '<p style="color:#006400"><b>Actual combined balance:</b></p>$' + $Results + '<br><br>'
            $Body += '<p style="color:#006400"><b>Budget (1200 - Combined balance):</b></p>$' + $Budget + '<br><br>'
            $Body += '<p style="color:#006400"><b>Upcoming Bills:</b></p><br>' + $UpcomingBills
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -BodyAsHTML -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Log "Sent email $From to $To" 
		
            # Email text to email. Here I'm using ATT but your provider probably offers it
            $From = "me@gmail.com"
            $To = "1234567890@txt.att.net"
            $Subject = "MyBudget"
            $Body = "Budget before payday: `$$RealisticBudget"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Log "Sent text message $From to $To" 
        }
        Else
        {
            $From = "me@gmail.com"
            $To = "someone@gmail.com"
            $Subject = "Daily Budget Automated Task"
            $Body = "Email didn't arrive"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Log "Sent email $From to $To" 
		
            $From = "me@gmail.com"
            $To = "1234567890@txt.att.net"
            $Subject = "Budget"
            $Body = "Email didn't arrive"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Log "Sent text message $From to $To" 
		}
    
    }

    End
    {
        # Get all emails and put them in the trash so that we don't have too many messages to go through tomorrow
        $Request = Invoke-WebRequest -Uri "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken" -Method Get | ConvertFrom-Json
        $messages = $($Request.messages)
        Log "Found $($messages.count) messages to delete"

        ForEach ($message in $messages)
        {
            $a = $($message.id)
            $b = Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken") -Method POST | ConvertFrom-Json
        }
		
        Stop-Log  
    }

}

<#######</Body>#######>
<#######</Script>#######>