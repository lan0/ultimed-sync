### Loading Configuration

    . .\config.ps1

### Functions

    $apiUrl = "https://hub.mobimed.at/api/files"
    $global:filesToUpload = [System.Collections.ArrayList]@()

    function log {
      param($text)
      $logline = "$((Get-Date).toString('u')), $($text)"
      Add-content "./log.txt" -value $logline
    }

    function isFileAlreadyUploaded {
      param($hash)
      foreach($line in Get-Content "./imported.dat") {
        if($line -match $hash) {
          return $true
        }
      }
      return $false
    }

    function deleteLocalFile {
      param($path)
      if(! $deleteUploadedFiles) {
        return
      }
      Remove-Item –path $path
      log -text "Deleted $fileName from $path"
    }

    function uploadFile {
      param($path)

      while ($global:filesToUpload.Contains($path)) {
        $global:filesToUpload.Remove($path)
      }
      if (! (Test-Path ".\imported.dat")) {
        New-Item -path .\ -name imported.dat -type "file"
      }
      if (! (Test-Path -Path $path)) {
        return
      }
      if ((Get-Item $path) -is [System.IO.DirectoryInfo]) {
        return
      }
      if ((Get-Content $path).length -eq 0 ) {
        return
      }

      $fileName = Split-Path $path -leaf
      $patientId = getPatientIdFromPath -path $path

      $hash = Get-FileHash $path
      $hash = $hash.hash

	  if (! (shouldUploadFile -path $path)) {
        return
      }

      if (isFileAlreadyUploaded -hash $hash) {
        log -text "File already uploaded ($($fileName))"
        deleteLocalFile -path $path
        return
      }

      # API expects multipart/form-data request
      # see https://stackoverflow.com/a/48580319
      $fileBin = [System.IO.File]::ReadAllBytes($path)
      $fileBin = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($fileBin);
      $boundary = [System.Guid]::NewGuid().ToString()
      $LF = "`r`n"
      $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
        "Content-Type: application/octet-stream$LF",
        $fileBin,
        "--$boundary--$LF"
      ) -join $LF

      if($patientId) {
        $apiUrl = "$($apiUrl)?patient=$patientId"
      }

      # for Powershell 6 add -SkipHeaderValidation
      $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $bodyLines  -ContentType "multipart/form-data; boundary=`"$boundary`"" -Headers @{Authorization=("Bearer {0}" -f $accessToken)}

      if (-Not $response.file.id) {
        log -text "Upload of $fileName to $apiUrl failed"
        return
      }
      # Upload to patient was successful
      if($response.file.patient) {
        log -text "Uploaded $fileName ($($response.file.id)) to patient $($response.file.patient)"
      } else{
        log -text "Uploaded $fileName ($($response.file.id))"
      }
      deleteLocalFile -path $path
      Add-content "./imported.dat" -value $hash
    }

    function uploadNewFiles {
      $filesToUpload = $global:filesToUpload.ToArray() | select -uniq
      foreach ($path in $filesToUpload) {
        uploadFile -path $path
      }
    }

    # initial File Upload
    function addFilesToFileList {
      param($folder)
      $allFiles = Get-ChildItem $folder -Recurse | select -ExpandProperty FullName
      if (-not $allFiles) {
        return;
      }
      if ($allFiles -isnot [array]) {
        $allFiles = @($allFiles)
      }
      $global:filesToUpload.AddRange($allFiles);
    }

### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $folder
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = {
                $path = $Event.SourceEventArgs.FullPath
                $global:filesToUpload.Add($path);
              }
### DECIDE WHICH EVENTS SHOULD BE WATCHED
    Register-ObjectEvent $watcher "Created" -Action $action
    Register-ObjectEvent $watcher "Changed" -Action $action
    Register-ObjectEvent $watcher "Renamed" -Action $action

    if ($initialUpload) {
        addFilesToFileList -folder $folder
    }

    while ($true) {
      sleep 5
      uploadNewFiles
    }
