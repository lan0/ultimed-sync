### Configuration

    # Folder to watch
    $folder = "C:\inbox\dropzone\"
    # Hub access token
    $accessToken = ""
    # initial File Upload
    $initialUpload = $true
    # Succsessfully uploaded Files will be deleted from Folder
    $deleteUploadedFiles = $false

### Functions

    $apiUrl = "https://hub.mobimed.at/api/files"
    $global:filesToUpload = [System.Collections.ArrayList]@()


    function log {
      param($text)
      $logline = "$(Get-Date), $($text)"
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

    function uploadFile {
      param($path)

      while ($global:filesToUpload.Contains($path)) {
        $global:filesToUpload.Remove($path)
      }

      if (!(Test-Path ".\imported.dat")) {
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
      if (isFileAlreadyUploaded -hash $hash) {
        log -text "File already uploaded ($($fileName))"
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
      if($deleteUploadedFiles) {
          Remove-Item –path $path
          log -text "Deleted $fileName from $path"
      }
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
      $allfiles = Get-ChildItem $folder -Recurse | select -ExpandProperty FullName
      $global:filesToUpload.AddRange($allfiles);
    }

    # Example: folderName "1024_Max_Mustermann"
    function getPatientIdFromPath {
      param($path)
      $folderName = Split-Path (Split-Path $path -Parent) -Leaf
      $patientId = $folderName.Split("_")[0] -as [int]
      return $patientId
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
