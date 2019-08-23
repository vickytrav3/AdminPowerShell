#################################################################################

##

## Server Health Check

## Created by Vikram Kumar

## Date : 21 Aug 2019

## Version : 1.0

## Email: spdevvikram@hotmail.com  

## This scripts check the server Avrg CPU and Memory utlization along with C drive

## disk utilization and sends an email to the receipents included in the script

################################################################################

 

 

$thresholdspace = 100

[int]$EventNum = 3

[int]$ProccessNumToFetch = 10

$ListOfAttachments = @()

$CurrentTime = Get-Date

 

 

$FilePath = "D:\Vikram\"

$ServerListFile = $FilePath+"list.txt" 

$ServerList = Get-Content $ServerListFile -ErrorAction SilentlyContinue

$Result = @()

$Outputreport = "<HTML><TITLE> Server Health Report </TITLE>

                     <Head><style>

                     body {

font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;

}

                     table{

    border-collapse: collapse;

    border: 1px solid black;

    border: none;

    font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;

    color: black;

    margin-bottom: 10px;

}

 

    table td{

    font-size: 12px;

    padding-left: 0px;

    padding-right: 20px;

    text-align: left;

    border: 1px solid black;

}

 

    table th {

    font-size: 12px;

    font-weight: bold;

    padding-left: 0px;

    padding-right: 20px;

    text-align: left;

    border: 1px solid black;

}

 

h2{ clear: both; font-size: 130%; }

 

h3{

    clear: both;

    font-size: 115%;

    margin-left: 20px;

    margin-top: 30px;

}

 

p{ margin-left: 20px; font-size: 12px; }

 

table.list{ float: left; }

 

    table.list td:nth-child(1){

    font-weight: bold;

    border-right: 1px grey solid;

    text-align: right;

}

 

table.list td:nth-child(2){ padding-left: 7px; }

table tr:nth-child(even) td:nth-child(even){ background: #CCCCCC; }

table tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }

table tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }

table tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }

div.column { width: 320px; float: left; }

div.first{ padding-right: 20px; border-right: 1px  grey solid; }

div.second{ margin-left: 30px; }

table{ margin-left: 20px;border: 1px solid black; }

  

</style></Head><BODY>

                     <font color =""#99000"" face=""Microsoft Tai le"">

                     <H2> Server Health Report </H2></font>"

 

Function Create-PieChart() {

    param([string]$FileName)

       

    [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

   

    #Create our chart object

    $Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart

    $Chart.Width = 300

    $Chart.Height = 290

    $Chart.Left = 10

    $Chart.Top = 10

 

    #Create a chartarea to draw on and add this to the chart

    $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea

    $Chart.ChartAreas.Add($ChartArea)

    [void]$Chart.Series.Add("Data")

 

    #Add a datapoint for each value specified in the arguments (args)

    foreach ($value in $args[0]) {

        Write-Host "Now processing chart value: " + $value

        $datapoint = new-object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $value)

        $datapoint.AxisLabel = "Value" + "(" + $value + " GB)"

        $Chart.Series["Data"].Points.Add($datapoint)

    }

 

    $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie

    $Chart.Series["Data"]["PieLabelStyle"] = "Outside"

    $Chart.Series["Data"]["PieLineColor"] = "Black"

    $Chart.Series["Data"]["PieDrawingStyle"] = "Concave"

    ($Chart.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true

 

    #Set the title of the Chart to the current date and time

    $Title = new-object System.Windows.Forms.DataVisualization.Charting.Title

    $Chart.Titles.Add($Title)

    $Chart.Titles[0].Text = "RAM Usage Chart (Used/Free)"

 

    #Save the chart to a file

    $Chart.SaveImage($FileName + ".png","png")

}

 

Function Get-HostUptime {

    param ([string]$ComputerName)

    $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName

    $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)

    $Time = (Get-Date) - $LastBootUpTime

    Return '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds

}

ForEach($computer in $ServerList)

{

 

    $DiskInfo= Get-WMIObject -ComputerName $computer Win32_LogicalDisk | Where-Object{$_.DriveType -eq 3} | Where-Object{ ($_.freespace/$_.Size)*100 -lt $thresholdspace} `

    | Select-Object SystemName, DriveType, VolumeName, Name, @{n='Size (GB)';e={"{0:n2}" -f ($_.size/1gb)}}, @{n='FreeSpace (GB)';e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n='PercentFree';e={"{0:n2}" -f ($_.freespace/$_.size*100)}} | ConvertTo-HTML -fragment

   

    #region System Info

    $OS = (Get-WmiObject Win32_OperatingSystem -computername $computer).caption

    $SystemInfo = Get-WmiObject -Class Win32_OperatingSystem -computername $computer | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory

    $TotalRAM = $SystemInfo.TotalVisibleMemorySize/1MB

    $FreeRAM = $SystemInfo.FreePhysicalMemory/1MB

    $UsedRAM = $TotalRAM - $FreeRAM

    $RAMPercentFree = ($FreeRAM / $TotalRAM) * 100

    $TotalRAM = [Math]::Round($TotalRAM, 2)

    $FreeRAM = [Math]::Round($FreeRAM, 2)

    $UsedRAM = [Math]::Round($UsedRAM, 2)

    $RAMPercentFree = [Math]::Round($RAMPercentFree, 2)

    #endregion

   

    $Outputreport +="<div><p><h2>"+$computer+"Report</h2></p><h3>System Info</h3></div>"

    $Outputreport +="<h3>Top Process</h3>"

    $TopProcesses = Get-Process -ComputerName $computer | Sort WS -Descending | Select ProcessName, Id, WS -First $ProccessNumToFetch | ConvertTo-Html -Fragment

    $Outputreport += $TopProcesses

    #region Services Report

    $Outputreport +="<h3>Services Report</h3>"

    $ServicesReport = @()

    $Services = Get-WmiObject -Class Win32_Service -ComputerName $computer | Where {($_.StartMode -eq "Auto") -and ($_.State -eq "Stopped")}

 

    foreach ($Service in $Services) {

        $row = New-Object -Type PSObject -Property @{

               Name = $Service.Name

            Status = $Service.State

            StartMode = $Service.StartMode

        }

       

    $ServicesReport += $row

   

    }

   

    $Outputreport += $ServicesReport | ConvertTo-Html -Fragment

    #endregion

       

    #region Event Logs Report

    $Outputreport +="<h3>System Events Report</h3>"

    $SystemEventsReport = @()

    $SystemEvents = Get-EventLog -ComputerName $computer -LogName System -EntryType Error,Warning -Newest $EventNum

    foreach ($event in $SystemEvents) {

        $row = New-Object -Type PSObject -Property @{

            TimeGenerated = $event.TimeGenerated

            EntryType = $event.EntryType

            Source = $event.Source

            Message = $event.Message

        }

        $SystemEventsReport += $row

    }

           

    $Outputreport += $SystemEventsReport | ConvertTo-Html -Fragment

    $Outputreport +="<h3>Application Events Report</h3>"

    $ApplicationEventsReport = @()

    $ApplicationEvents = Get-EventLog -ComputerName $computer -LogName Application -EntryType Error,Warning -Newest $EventNum

     foreach ($event in $ApplicationEvents) {

        $row = New-Object -Type PSObject -Property @{

            TimeGenerated = $event.TimeGenerated

            EntryType = $event.EntryType

            Source = $event.Source

           Message = $event.Message

        }

        $ApplicationEventsReport += $row

    }

   

    $Outputreport += $ApplicationEventsReport | ConvertTo-Html -Fragment

    #endregion

   

   Create-PieChart -FileName ($FilePath + "chart-$computer") $FreeRAM, $UsedRAM

   $ListOfAttachments += $FilePath +"chart-$computer.png"

 

    # Create HTML Report for the current System being looped through

       

   IF ($RAMPercentFree -le 10){ 

   $Outputreport += "<table><tr><td>OS</td><td>"+$OS+"</td></tr><tr><td>Total RAM (GB)</td><td>"+$TotalRAM+"</td></tr><tr><td>Free RAM (GB)</td><td bgcolor=""#FF0000"" >"+$FreeRAM+"</td></tr><tr><td>Percent free RAM</td><td bgcolor=""#FF0000"">"+$RAMPercentFree+"</td></tr></table>"

   }

    ELSE

    { 

    $Outputreport += "<table><tr><td>OS</td><td>"+$OS+"</td></tr><tr><td>Total RAM (GB)</td><td>"+$TotalRAM+"</td></tr><tr><td>Free RAM (GB)</td><td>"+$FreeRAM+"</td></tr><tr><td>Percent free RAM</td><td>"+$RAMPercentFree+"</td></tr></table>"

    }

   

    #have less than "+$thresholdspace+" % free space. Drives above this threshold will not be listed.

   

    $Outputreport +="<h3>Disk Info</h3><p>Drive(s) listed below </p><table>"+$DiskInfo+"</table><br></br>"

   

    

    # Add the current System HTML Report into the final HTML Report body

   

    

    }

    $Outputreport += "</BODY></HTML>"

$Outputreport | out-file $FilePath + Test.htm

#Invoke-Expression F:\Vikram\Test.htm

##Send email functionality from below line, use it if you want  

$smtpServer = "mail.sasol.com"

$smtpFrom = "vikram.kumar@sasol.com"

$smtpTo = "vikram.kumar@sasol.com"

$messageSubject = "Servers Health report"

$message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto

$message.Subject = $messageSubject

$message.IsBodyHTML = $true

$message.Body = "<head><pre>$style</pre></head>"

$message.Body += Get-Content $FilePath +Test.htm

ForEach($attachmentX in $ListOfAttachments)

{

    $attachment = new-object System.Net.Mail.Attachment $attachmentX

    $message.Attachments.Add($attachment)

}

$smtp = New-Object Net.Mail.SmtpClient($smtpServer)

$smtp.Send($message)