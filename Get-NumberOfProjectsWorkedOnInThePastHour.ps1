Clear-Host

# Load data from the file; it should contain data of the format
# apitoken,laksjdhflaksjdhfaskljdfhalskdjfhalksdjfhalskdjfhaslkdf,workspaceid,123679
$PATH_TO_TOGGL_INFO_FILE = ".\toggl_info.txt"

# Read content from the file
$togglInfoFileContentsEncrypted = Get-Content -Path $PATH_TO_TOGGL_INFO_FILE -ErrorAction Stop

$togglInfoFileContents = (New-Object System.Management.Automation.PSCredential -ArgumentList 'nulldomain,nulluser',($togglInfoFileContentsEncrypted | convertto-securestring -key (1..16))).GetNetworkCredential().password

$togglInfoFileContentsArray = $togglInfoFileContents -split ","

# Create auth header
$user = $togglInfoFileContentsArray[1] # The Toggl API key
$pass = 'api_token'
$webRequestHeaders = @{
    Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($user):$($pass)"))
}

# Specify the workspace
$TOGGL_WORKSPACE_ID = $togglInfoFileContentsArray[3]

# Get the start and end time -- make sure that this project runs every day at midnight
$endDate   = (Get-Date -Hour 0 -Minute 0 -Second 0)
$startDate = (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-1)

# Prepare the request URI
$requestURI = "https://toggl.com/reports/api/v2/summary?workspace_id=" + $TOGGL_WORKSPACE_ID + "&since=" + $startDate.ToString("yyyy-MM-ddT:hh:mm:ss") + "&until=" + $endDate.ToString("yyyy-MM-ddT:hh:mm:ss") + "&user_agent=api_test"
Write-Host "Request uri:" $requestURI

# Fire the request
$response = Invoke-WebRequest -Uri $requestURI -Method Get -Headers $webRequestHeaders -Verbose
Write-Host "Response status code:" $response.StatusCode

# Convert the response to JSON
$responseJSON = ConvertFrom-Json $response.Content

# Number of projects worked on
$numberOfProjectsWorkedOn = $responseJSON.data.Length

$PIDAConnection = Connect-PIDataArchive -PIDataArchiveMachineName "localhost" -Verbose -ErrorAction Stop

Add-PIValue -Value $numberOfProjectsWorkedOn -Time $startDate -Connection $PIDAConnection -PointName "Number of Projects Worked On Today" -ErrorAction Continue -Verbose
Disconnect-PIDataArchive $PIDAConnection -Verbose