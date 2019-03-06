Clear-Host

# Load data from the file; it should contain data of the format
# apitoken,lkahfg893hr3o8haf387yf3a9y3fa3rf,workspaceid,123679
$PATH_TO_TOGGL_INFO_FILE = "D:\Users\dlopez\Documents\GitHub\Toggl-Time-Tracking\toggl_info.txt"

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

# Get the start and end time
$endDate = (Get-Date (Get-Date -Format "MM/dd/yyyy") -Day 1)
$startDate = (Get-Date (Get-Date -Format "MM/dd/yyyy") -Day 1 -Month 2)
Write-Host "Start and end time:" $startDate $endDate

# Count number of weekdays in this range
$numberOfWeekdays = 0
# Test every date between start and end to see if it is a weekend
for ($d = $startDate; $d -le $endDate; $d = $d.AddDays(1)){
    if ($d.DayOfWeek -notmatch "Sunday|Saturday") {
        # If the day of the week is not a Saturday or Sunday, increment the counter
        $numberOfWeekdays++    
    }
    else {
        # Verify these are weekend days
        Write-Verbose ("{0} is {1}" -f $d,$d.DayOfWeek)
    }
}

# Prepare the request URI
$requestURI = "https://toggl.com/reports/api/v2/summary?workspace_id=" + $TOGGL_WORKSPACE_ID + "&since=" + $startDate.ToString("yyyy-MM-dd") + "&until=" + $endDate.ToString("yyyy-MM-dd") + "&user_agent=api_test"
Write-Host "Request uri:" $requestURI

# Fire the request
$response = Invoke-WebRequest -Uri $requestURI -Method Get -Headers $webRequestHeaders
Write-Host "Response status code:" $response.StatusCode

# Convert the response to JSON
$responseJSON = ConvertFrom-Json $response.Content

# Create a table for displaying results
$tableName = "Toggl Report - " + $startDate + " until " + $endDate
$table = New-Object system.Data.DataTable “$tableName”

#Define Columns
$col1 = New-Object system.Data.DataColumn 'Service activity',([string])
$col2 = New-Object system.Data.DataColumn 'Raw duration in milliseconds',([int])
$col3 = New-Object system.Data.DataColumn 'Duration in workdays',([single])

#Add the Columns
$table.columns.add($col1)
$table.columns.add($col2)
$table.columns.add($col3)

ForEach ($project In $responseJSON.data) {

    #Create a row
    $row = $table.NewRow()

    #Enter data in the row
    $row.'Service activity' = $project.title.project
    $row.'Raw duration in milliseconds' = $project.time 
    $row.'Duration in workdays' = [math]::Round($project.time / 1000 / 60 / 60 / 8, 2)

    #Add the row to the table
    $table.Rows.Add($row)
}

#Display the table
Write-Host 'Results:'
Write-Host ''
Write-Host $tableName
$table | format-table -AutoSize 
#$table | Out-GridView -PassThru

Write-Host "Total time in workdays:" ([math]::Round($responseJSON.total_grand / 1000 / 60 / 60 / 8, 2)) "out of" $numberOfWeekdays "("(100*([math]::Round($responseJSON.total_grand / 1000 / 60 / 60 / 8 / $numberOfWeekdays,2)))"% )"