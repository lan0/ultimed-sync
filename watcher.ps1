### Loading Configuration

    . .\config.ps1

### Functions

    $apiUrl = "https://<client>.mobimed.at/api/v1/files/labgate"
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
      $directory = Split-Path($path)
      if(! $deleteUploadedFiles) {
        return
      }

      Remove-Item –path $path
      log -text "Deleted $path"

      if (Test-Path -path "$directory/*") {
        return; # folder still contains files, abort and do not delete
      }
      if ($directory.TrimEnd(@("/","\")) -eq $folder.TrimEnd(@("/","\"))) {
        return; # do not delete parent folder
      }
      log -text "Deleted empty directory $directory"
      Remove-Item -path $directory
    }

    function uploadFile {
      param($path)

      if (! (shouldUploadFile -path $path)) {
        return
      }

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

      $gdtPath = $path;

      $patientId = $false

      $hash = Get-FileHash $gdtPath
      $hash = $hash.hash

      if (isFileAlreadyUploaded -hash $hash) {
        log -text "File already uploaded ($($gdtPath))"
        deleteLocalFile -path $gdtPath
        return
      }

      # API expects multipart/form-data request
      # see https://stackoverflow.com/a/48580319
      $gdtBin = [System.IO.File]::ReadAllBytes($gdtPath)
      $gdtBin = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($gdtBin);
      $boundary = [System.Guid]::NewGuid().ToString()
      $LF = "`r`n"
      $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"files[]`"; filename=`"meta.gdt`"",
        "Content-Type: application/octet-stream$LF",
        $gdtBin,
        "--$boundary--"
      ) -join $LF

      if($patientId) {
        $apiUrl = "$($apiUrl)?patient=$patientId"
      }

      # for Powershell 6 add -SkipHeaderValidation
      $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $bodyLines  -ContentType "multipart/form-data; boundary=`"$boundary`"" -Headers @{Authorization=("Bearer {0}" -f $accessToken)}

      log -text "Uploaded gdt file"
      
      deleteLocalFile -path $gdtPath
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
