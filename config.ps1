### Configuration to cutomize the watcher.ps1

    # Folder to watch
    $folder = "C:\inbox\dropzone\"
    # Hub access token
    $accessToken = ""
    # initial File Upload
    $initialUpload = $true
    # Successfully uploaded Files will be deleted from Folder
    $deleteUploadedFiles = $false

### Function to get PatientId - Parameter: Path

    #Extracts 1024 from `/foo/bar/1024_Max_Mustermann/file.jpg`
    function getPatientIdFromPath {
      param($path)
      $folderName = Split-Path (Split-Path $path -Parent) -Leaf
      $patientId = $folderName.Split("_")[0] -as [int]
      return $patientId
    }
