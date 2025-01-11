## Prerequisites

Before you begin, ensure you have the following:

- **PowerShell 5.1 or higher**: The script requires at least Windows PowerShell 5.1. (PowerShell 7+ untested at this time but it might work)
- **Log files**: A directory containing the `ps-log-audit*.log` and `mass-data*.log` files.

## Downloading the Script

To download the `Parse-PowerSchoolLogs.ps1` script from GitHub, follow these steps:

1. **Navigate to the GitHub repository**: Open your web browser and go to the [GitHub repository](https://github.com/raijuninja/PowerSchool).

2. **Locate the script**: Find the `Parse-PowerSchoolLogs.ps1` file in the repository.

3. **Download the script**:
	- Click on the file name to open it.
	- Click the "Download Raw File" button to view the raw file.
	- You may receive a warning that the file is potentially harmful. This is a standard warning for script files. Confirm that you want to download the file. Click `Keep` to download the script file.
	- **Unblock the file**: After downloading, right-click the file, select `Properties`, and check the `Unblock` option if it is present. This step may be necessary based on your execution policy settings.

Alternatively, you can clone the entire repository using Git:

```powershell
git clone https://github.com/raijuninja/PowerSchool.git
```

This will download all the files in the repository, including `Parse-PowerSchoolLogs.ps1`.

## Usage

1. **Open PowerShell**: (The minimum version would be Windows PowerShell 5.1).

2. **Navigate to the script directory**:
	```powershell
	cd "C:/path/to/script/"
	```

3. **Run the script**:
	```powershell
	.\Parse-PowerSchoolLogs.ps1 -LogFilePath "C:\path\to\your\logFileDirectory"
	```

	> **Note**: The `LogFilePath` directory should contain the zipped or unzipped log folders with the `.log` files inside.

	The script will generate a CSV file named `log-results.csv` in root of your log directory. This CSV file will contain the parsed log data, including columns for Filename where the hit existed, IP, url, executionID, Line info, and all associated actions with the same ID. (Multiple actions should append a new column - If they try more than once each attempt should be captured in a new column).