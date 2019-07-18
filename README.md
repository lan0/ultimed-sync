# ultimed-sync
This script watches a folder and uploads any changed files to mobi.MED every 5 seconds.

Adds parameter ```?patient=<patientId>``` to the upload request, where ```patientId``` is prefix of the foldername (patientId_xxx_xxxxx)

imported.dat: List of imported files (hashes)

log.txt: Log of uploaded files

## Configuration Options:

* ```$folder``` the folder which is watched
* ```$accessToken``` the Token witch is used
* ```$initialUpload``` if true, then existing files in the specific folder will be uploaded initially
* ```$deleteUploadedFiles``` if true, successfully uploaded files will be deleted from specific folder

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