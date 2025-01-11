param (
    [string]$LogFilePath,
    [string[]]$SearchStrings = @("UID=200A0", "/ws/md/v1/massdata/executeExport")
)

# Prompt the user to input the path to the logs directory if not provided as a parameter
if (-not $LogFilePath) {
    $LogFilePath = Read-Host "Please enter the path to the logs directory"
}

# Define the output CSV file
$outputCsv = Join-Path -Path $LogFilePath -ChildPath "log_search_results.csv"

# Initialize the CSV file if it doesn't exist
if (-not (Test-Path -Path $outputCsv)) {
    "File,IP,URL,executionID,Line,Execution_Data_1" | Out-File -FilePath $outputCsv
}

# Extract zip files before processing
$items = Get-ChildItem -Path $LogFilePath -Recurse

foreach ($item in $items) {
    if ($item.PSIsContainer) {
        # If the item is a directory, recursively process it
        $subItems = Get-ChildItem -Path $item.FullName -Recurse
        foreach ($subItem in $subItems) {
            if ($subItem.Extension -eq ".zip") {
                # If the item is a zip file, extract it
                $extractPath = Join-Path -Path $item.FullName -ChildPath ($subItem.BaseName + "_extracted")
                if (-not (Test-Path -Path $extractPath)) {
                    Expand-Archive -Path $subItem.FullName -DestinationPath $extractPath -Force
                }
            }
        }
    }
    elseif ($item.Extension -eq ".zip") {
        # If the item is a zip file, extract it
        $extractPath = Join-Path -Path $LogFilePath -ChildPath ($item.BaseName + "_extracted")
        if (-not (Test-Path -Path $extractPath)) {
            Expand-Archive -Path $item.FullName -DestinationPath $extractPath -Force
        }
    }
}

# Function to process initial log files
function Process-PSAuditLogFiles {
    param (
        [string]$directory,
        [string[]]$searchStrings
    )

    # Get all the files in the directory
    $items = Get-ChildItem -Path $directory -Recurse

    foreach ($item in $items) {
        if ($item.Name -like "ps-log-audit*") {
            # Inform the user of the current file in the loop
            Write-Output "Processing log entries in: $($item.FullName)"

            # If the item is a log file, read and process it
            $logContent = Get-Content -Path $item.FullName -Raw

            # Split the log content into individual log entries based on the timestamp format
            $logEntries = $logContent -split "(?=\[.*?\])"

            $ipValue = ""
            $urlValue = ""
            $executionID = ""

            # First pass: Check for the presence of all search strings and capture IP, URL, and EX values
            foreach ($log in $logEntries) {
                $allStringsFound = $true

                foreach ($searchString in $searchStrings) {
                    if ($log -notlike "*$searchString*") {
                        $allStringsFound = $false
                        break
                    }
                }

                if ($allStringsFound) {
                    if ($log -match "IP=([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})") { $ipValue = $matches[1] }
                    if ($log -match "URL=([^\s]+)") { $urlValue = $matches[1] }
                    if ($log -match "EX=([a-f0-9]+)") { $executionID = $matches[1] }
                    Write-Output "Found a match in log File: $($item.BaseName)`nIP: $ipValue`nURL: $urlValue`nEX: $executionID`nLine: $log"
                    $csvChunk = $log -replace "`n", " " -replace "`r", ""
                    $csvOutput = "$($item.FullName),$ipValue,$urlValue,$executionID,""$csvChunk"""
                    $csvOutput | Out-File -FilePath $outputCsv -Append
                    break
                }
            }
        }
    }
}

# Function to search log files for matching EX values and update the CSV with execution data
function Match-MassDataLogFileExecution {
    param (
        [string]$directory
    )

    # Get all log files and subdirectories in the specified directory
    $items = Get-ChildItem -Path $directory -Recurse

    $csvData = Import-Csv -Path $outputCsv
    $executionIdentifiers = $csvData | Select-Object -ExpandProperty executionID | Sort-Object -Unique

    foreach ($item in $items) {
        if ($item.Name -like "mass-data*.log") {
            # If the item is a log file, read and process it
            $logContent = Get-Content -Path $item.FullName -Raw
            $logEntries = $logContent -split "(?=\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3} \[Web Handler \d+ - EX=)"

            # Search all chunks for the new EX value using the resultant CSV
            foreach ($log in $logEntries) {
                foreach ($executionID in $executionIdentifiers) {
                    if ($log -like "*EX=$executionID*") {
                        Write-Output "File: $($item.FullName)`nEX: $executionID`nLine: $log"
                        $csvChunk = $log -replace "`n", " " -replace "`r", ""
                        $executionData = $csvChunk

                        # Update the CSV data with the execution data
                        foreach ($row in $csvData) {
                            if ($row.executionID -eq $executionID) {
                                $executionColumns = $row.PSObject.Properties.Name -match "^Execution_Data_\d+$"
                                $nextColumnIndex = ($executionColumns | Measure-Object).Count + 1
                                $nextColumnName = "Execution_Data_$nextColumnIndex"
                                $row | Add-Member -MemberType NoteProperty -Name $nextColumnName -Value $executionData
                            }
                        }
                    }
                }
            }
        }
    }

    # Write the updated CSV data back to the file
    $csvData | Export-Csv -Path $outputCsv -NoTypeInformation -Force
}

# Process the initial log files to capture IP, URL, and EX values
Process-PSAuditLogFiles -directory $LogFilePath -searchStrings $SearchStrings

# Search the different set of log files for matching EX values and update the CSV with execution data
Match-MassDataLogFileExecution -directory $LogFilePath