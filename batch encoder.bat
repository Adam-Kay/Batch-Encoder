@echo off
setlocal enabledelayedexpansion

SET version=v1.3.7

echo %1
if /i "%1"=="--updated-from" (
	del %2
)

	
:AskProceed
	call:ClearAndTitle
	SET /P "CONFIRMATION=This program will aim to encode all .mp4 files in the folder it's placed in and delete the originals. Do you want to proceed? [Y/N] : "
	IF /i "%CONFIRMATION%"=="n" exit
	IF /i "%CONFIRMATION%"=="y" (goto AskUpdate)
	goto AskProceed

:AskUpdate
	call:ClearAndTitle
	SET /P "CONFIRMATION=Would you like to check for an update? [Y/N] : "
	IF /i "%CONFIRMATION%"=="n" (goto FFMPEGLocation)
	IF /i "%CONFIRMATION%"=="y" (goto AutoUpdate)
	goto AskUpdate
	
:AutoUpdate
	call:ClearAndTitle
	echo Downloading information...
	curl -o batch_update.txt https://gist.githubusercontent.com/Adam-Kay/ec5da0ff40e8eb14beee2242161f5191/raw -q
	pause
	for /f "tokens=1,2,3 delims=|" %%A in (batch_update.txt) do (
		set UpdateVersion=%%A
		set UpdateAPIURL=%%B
		set UpdateBrowserURL=%%C
	)

	rem Test if any of them are blank
	for %%a in (UpdateVersion, UpdateAPIURL, UpdateBrowserURL) do if not defined %%a goto AutoUpdateError

	echo New Version: %UpdateVersion%
	curl -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%.bat" %UpdateAPIURL%
	pause
	exit

:FFMPEGLocation
	rem TODO: detect FFMPEG if in same folder
	SET /P "LOCATION=Where is FFMPEG.exe located? [paste full path]: "
	
set /a "COUNTER=-1" 

:Count
	for /f "usebackq delims=|" %%f in (`dir /b ""`) do set /a "COUNTER+=1"
	set "TOTAL=%COUNTER%"
	REM echo %TOTAL%
	
set /a "COUNTER=0"
set "INPUTFILE="

:Conversion
	for /f "usebackq delims=|" %%f in (`dir /b ""`) do (
	
		REM echo %%f
		REM echo %~n0%~x0
		REM pause
		
		
		cls
		
		set "INPUTFILE=%%f"
	
		if /i "%%f"=="%~n0%~x0" (
			echo Skipping self.
			timeout 2
		) else (
			set /a "COUNTER+=1" 
			echo Encoding !COUNTER! of %TOTAL%
			echo **********************************
				
			set "TESTSTRING=!INPUTFILE:~-4!"
			if /i NOT "!TESTSTRING!"==".mp4" (
				echo Skipping unsupported file^: ^(!INPUTFILE!^)
				timeout 3
				rem TODO: detect if unsupported is folder and change text appropriately, also discount from counter since that only counts files.
			) else ( 
				set "TESTSTRING=!INPUTFILE:~-8!"
				if /i "!TESTSTRING!"==".DVR.mp4" (
					set "OUTPUTFILE=!INPUTFILE:~0,-8!.ENC.mp4"
				) else (
					set "OUTPUTFILE=!INPUTFILE:~0,-4!.ENC.mp4"
				)
				
				echo Supported file found^: ^(!INPUTFILE!^)
				
				timeout /t 5
			
				%LOCATION% -i "%CD%\!INPUTFILE!" "%CD%\!OUTPUTFILE!"
				
				if /i NOT exist "%CD%\!OUTPUTFILE!" goto CritError
				
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').CreationTime=((Get-Item '%CD%\!INPUTFILE!').CreationTime)"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').LastWriteTime=((Get-Item '%CD%\!INPUTFILE!').LastWriteTime)"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').LastAccessTime=((Get-Item '%CD%\!INPUTFILE!').LastAccessTime)"
				
				REM delete to recycle bin
				powershell -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('%CD%\!INPUTFILE!','OnlyErrorDialogs','SendToRecycleBin')"
			)
		)
	)
	
cls
echo Completed encoding %TOTAL% files.
echo **********************************
	
:EndPause
	pause
	exit
	
:CritError
	echo.
	echo.
	echo *******************************************************
	echo A critical error occurred. No files have been modified.
	goto EndPause
	
:AutoUpdateError
	echo.
	echo There was a problem with the auto-updater. Restarting program...
	echo.
	pause
	goto AskProceed

:ClearAndTitle
	cls
	echo Batch Encoder %version%
	goto:eof