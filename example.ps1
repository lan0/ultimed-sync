# Replace the existing functions in config.ps1 to introduce new behavior
# Examples:

#Upload filter - uploads all files with specific file extension
function shouldUploadFile {
  param($path)
  $whitelist = @("jpg", "jpeg", "png", "bmp")
  $fileExtension = [System.IO.Path]::GetExtension($path).TrimStart(".")
  return $whitelist.Contains($fileExtension)
}