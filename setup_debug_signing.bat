@echo off
if not exist "%USERPROFILE%\.android" mkdir "%USERPROFILE%\.android"
copy /Y "debug.keystore" "%USERPROFILE%\.android\debug.keystore"
echo Installed. Expected SHA-1: 2A:7B:78:30:20:FD:3B:27:D4:4D:35:AA:37:21:32:B7:F3:04:B9:13
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -alias androiddebugkey | findstr "SHA1"
