# ultimed-sync
This script watches a folder and uploads any changed files to mobi.MED every 5 seconds.

Adds parameter ```?patient=<patientId>``` to the upload request, where ```patientId``` is prefix of the foldername (patientId_xxx_xxxxx)

imported.dat: List of imported files (hashes)

log.txt: Log of uploaded files

## Configuration Options (config.ps1):

* ```$folder``` the folder to watch
* ```$accessToken``` the token to use - contact [support@mobimed.at](mailto:support@mobimed.at)
* ```$initialUpload``` (default: true) existing files in the watched folder will also be uploaded initially and not only after changes occurred
* ```$deleteUploadedFiles``` (default: false) successfully uploaded files will be deleted from specific folder
* ```function getPatientIdFromPath``` the function to determine the patientId, Input: [Path] -Path of the File, Output: [patientId] -internal ID of the patient
* ```function shouldUploadFile``` (defalut: all Files are uploaded) the function can be replaced to filter based on the file extensions

## Windows autorun:

* Create a new scheduled task on login
* Start Program: "PowerShell"
* With arguments: ```-Command "& C:\inbox\watcher_all.ps1" >> "%TEMP%\mobimed_watcher.txt" 2>&1```
* In folder: "C:\inbox"
* [ x ] Run whether user is logged on or not
* Run as administrator to allow PowerShell scripts:
* Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

## OSX autorun (El Capitan and newer):

* Create file in ~/Library/LaunchAgents:
* https://gist.github.com/lan0/1aaf9e6197c8fc5b089c3ad0e3059c86
* Run `launchctl load ~/Library/LaunchAgents/at.mobimed.importer.plist`
* To test, run `launchctl start at.mobimed.importer`