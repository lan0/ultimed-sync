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
    $apiUrl = "https://api-staging.mobimed.at/v1/files/ldt"

### Functions

    #Extracts 1024 from `/foo/bar/1024_Max_Mustermann/file.jpg` (input parameter: file path)
    function getPatientIdFromPath {
      param($path)
      return $false
    }

    #Upload filter - default all files are valid
    function shouldUploadFile {
      param($path)
      $extension = [System.IO.Path]::GetExtension($path)
      if ($extension -eq ".LDT") {
        return $true
      }
      return $true
    }