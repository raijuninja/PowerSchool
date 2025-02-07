<# 
	copy and paste the values that are within the <columns> tag and paste them into the $inputdata variable here-string. 
	Then run the script. The output will be copied to the clipboard.
	example:
	<column column="terms.abbreviation">school_year</column>
	<column column="students.last_name">last_name</column>
	<column column="students.first_name">first_name</column>
	<column column="students.middle_name">middle_name</column>
#>

$inputdata = @"
	
"@

$header = "table_column`tplugin_named_column"
$processedLines = $inputdata -split "`n" | ForEach-Object {
    if ($_ -match '"(.*?)"') {$leftdata = $matches[1]}
    if ($_ -match '>(.*?)<') {$rightdata = $matches[1]}
    "$leftdata`t$rightdata"
}

# Join the processed lines with newline characters to ensure each is on a new line
$processedLinesJoined = $processedLines -join "`n"

# Add the header to the processed lines
$table = $header + "`n" + $processedLinesJoined

# Set the combined string to the clipboard
Set-Clipboard -Value $table