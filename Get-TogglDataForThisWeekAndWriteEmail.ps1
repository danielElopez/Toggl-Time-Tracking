Clear-Host

# Load data from the file; it should contain data of the format
# apitoken,laksjdhflaksjdhfaskljdfhalskdjfhalksdjfhalskdjfhaslkdf,workspaceid,123679
$PATH_TO_TOGGL_INFO_FILE = "D:\Users\dlopez\Documents\GitHub\danielElopez\Toggl-Time-Tracking\toggl_info.txt"

# Read content from the file
$togglInfoFileContents = Get-Content -Path $PATH_TO_TOGGL_INFO_FILE -ErrorAction Stop
$togglInfoFileContentsArray = $togglInfoFileContents -split ","

# Create auth header
$user = $togglInfoFileContentsArray[1] # The Toggl API key
$pass = 'api_token'
$webRequestHeaders = @{
    Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($user):$($pass)"))
}

# Specify the workspace
$TOGGL_WORKSPACE_ID = $togglInfoFileContentsArray[3]

# Allow the user to skip ahead one month
$userInput = ""
$userInput = (Read-host -Prompt "Enter 0 (or press ENTER) to report on the current week.`nEnter 1 to report on 1 week ago, 2 to report on 2 weeks ago, etc.")

# Get the start and end time; initialize them to the start of this week and now
$startDate = (Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(-1 * (Get-Date).DayOfWeek.value__)
$endDate = Get-Date

if (($userInput -eq "0") -or ($userInput -eq "") -or ($null -eq $userInput)) {
    Write-Host "Reporting on this week!"
}
else {
    $numberOfWeeks = [int]$userInput
    Write-Host "Reporting on" $numberOfWeeks "weeks ago..."
    $startDate = $startDate.AddDays(-7 * $numberOfWeeks)
    $endDate = $startDate.AddDays(7)
}

Write-Host "Start and end time:" $startDate $endDate

# Prepare the request URI
$requestURI = "https://toggl.com/reports/api/v2/weekly?workspace_id=" + $TOGGL_WORKSPACE_ID + "&since=" + $startDate.ToString("yyyy-MM-dd") + "&until=" + $endDate.ToString("yyyy-MM-dd") + "&user_agent=api_test"

Write-Host "Request uri:" $requestURI

# Fire the request
$response = Invoke-WebRequest -Uri $requestURI -Method Get -Headers $webRequestHeaders
Write-Host "Response status code:" $response.StatusCode

# Convert the response to JSON
Write-Host "Now processing results..."
$responseJSON = ConvertFrom-Json $response.Content

# Get the total time
$totalTimeInMilliseconds = $responseJSON.total_grand

# Extract the project names and durations
$projectNames = [System.Collections.ArrayList]@()
$projectPercentages = [System.Collections.ArrayList]@()

Foreach ($project in $responseJSON.data) {
    $projectName = $project.title.project
    $null = $projectNames.Add($projectName)
    $projectPercentage = $project.totals[7] / $totalTimeInMilliseconds * 100
    $null = $projectPercentages.Add($projectPercentage)
}

# Load needed assemblies, then create the chart
Write-Host "Now creating a chart of the processed results..."
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

$myChart = New-object System.Windows.Forms.DataVisualization.Charting.Chart

# Format the chart
$myChart.Width = 800
$myChart.Height = 500
$myChart.Left = 10
$myChart.Top = 10
$myChart.BackColor = [System.Drawing.Color]::White

# Title
$myChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
$myChartTitle.Text = "Dan Lopez Weekly Time Report - " + $startDate.ToString("dddd d MMM yyyy") + " until " + $endDate.ToString("dddd d MMM yyyy")
$myChartTitle.Font = New-Object System.Drawing.Font @('Microsoft Sans Serif', '12', [System.Drawing.FontStyle]::Bold)
$myChart.Titles.Add($myChartTitle)

# Chart area
$myChartAreaName = "ChartArea1"
$myChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$myChartArea.Name = $myChartAreaName
$myChart.ChartAreas.Add($myChartArea)
$myChartArea.AxisX.Interval = 1
$myChartArea.AxisY.Title = "% of my total week's work spent on this project"

# Series
$mySeriesName = "Series1"
$null = $myChart.Series.Add($mySeriesName)
$myChart.Series[$mySeriesName].ChartType = "Bar"
$myChart.Series[$mySeriesName].ChartArea = $myChartAreaName
$myChart.Series[$mySeriesName].Points.DataBindXY($projectNames, $projectPercentages)
$myChart.Series[$mySeriesName].Sort([System.Windows.Forms.DataVisualization.Charting.PointSortOrder]::Ascending, "Y")

# Save
$folderPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$filePath = "Dan_Lopez_Weekly_Time_" + $startDate.ToString("yyyy-MM-dd") + "_until_" + $endDate.ToString("yyyy-MM-dd") + ".png"
Write-Host "Now saving the chart to" ($folderPath + "\" + $filePath) "..."
$myChart.SaveImage($folderPath + "\" + $filePath, "png")

# Add the chart to a form and display the chart
Write-Host "Now displaying the chart..."
$AnchorAll = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
[System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$myForm = New-Object Windows.Forms.Form
$myForm.Width = $myChart.Width + 20
$myForm.Height = $myChart.Height + 50
$myForm.controls.add($myChart)
$myChart.Anchor = $AnchorAll
$myForm.Add_Shown( { $myForm.Activate() })
$null = $myForm.ShowDialog()

Write-Host "Script ended."
