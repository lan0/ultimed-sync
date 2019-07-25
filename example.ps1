# Replace the existing functions in config.ps1 to introduce new behavior
# Examples:

#Upload filter - uploads all files with specific file extension
function shouldUploadFile {
    param($path)
    $whitelist = @("jpg", "jpeg", "png", "bmp")
    $fileExtension = [System.IO.Path]::GetExtension($path).TrimStart(".")
    return $whitelist.Contains($fileExtension)
}

#Extracts patientId from csv - File (input parameter: file path)
function getPatientIdFromPath {
    param($path)
    $folderPath = Split-Path $path -Parent
    $csvFile = Get-ChildItem $folderPath | where {$_.extension -eq ".csv"} | select -ExpandProperty Fullname
    $columnName = "personId"
    #single row -> returns string
    $csvContent = (Get-Content $csvFile  -Encoding:string | convertfrom-csv -delimiter ",").$columnName
    $patientId = $csvContent -as [int]
    return $patientId
}