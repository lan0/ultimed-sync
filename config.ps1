### Configuration to cutomize the watcher.ps1

    # Folder to watch
    $folder = "C:\inbox\dropzone\"
    # Hub access token
    $accessToken = ""
    # initial file upload
    $initialUpload = $true
    # successfully uploaded files will be deleted from folder
    $deleteUploadedFiles = $false

### Functions

    #Extracts 1024 from `/foo/bar/1024_Max_Mustermann/file.jpg` (input parameter: file path)
    function getPatientIdFromPath {
      param($path)
      $folderName = Split-Path (Split-Path $path -Parent) -Leaf
      $patientId = $folderName.Split("_")[0] -as [int]
      return $patientId
    }

    #Upload filter - default all files are valid
    function shouldUploadFile {
      param($path)
      return $true
    }