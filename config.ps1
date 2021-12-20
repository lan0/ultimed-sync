### Configuration to cutomize the watcher.ps1

    # Folder to watch
    $folder = "C:\inbox\dropzone\"
    # Hub access token
    $accessToken = ""
    # initial file upload
    $initialUpload = $true
    # successfully uploaded files will be deleted from folder
    $deleteUploadedFiles = $false
    # URL to API endpoint
    $apiUrl = "http://ultimed-api.test/v1/files/lab"

### Functions

    #Extracts 1024 from `/foo/bar/1024_Max_Mustermann/file.jpg` (input parameter: file path)
    function getPatientIdFromPath {
      return $false
    }

    #Upload filter - default all files are valid
    function shouldUploadFile {
      param($path)
      $fileName = Split-Path $path -Leaf
      if ($fileName -eq ".DS_Store") {
        return $false
      }
      return $true
    }