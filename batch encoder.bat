@echo off
setlocal enabledelayedexpansion

SET CurrentVersion=v1.5.0-alpha2

cls
if /i "%1"=="--updated-from" (
	echo Just updated^^! Running cleanup...
	timeout 1
	del %2
)

	
:AskProceed
	call:ClearAndTitle
	echo This program will aim to encode all .mp4 files in the folder it's placed in and delete the originals. 
	SET /P "CONFIRMATION=Do you want to proceed? [Y/N] : "
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
	curl --silent -L -H "Accept: application/vnd.github+json" -o batch_update.json https://api.github.com/repos/Adam-Kay/Batch-Encoder/releases/latest
	rem curl --silent -o batch_update.txt https://gist.githubusercontent.com/Adam-Kay/ec5da0ff40e8eb14beee2242161f5191/raw
	
	>%TEMP%\batch_update.tmp findstr "tag_name" batch_update.json
	<%TEMP%\batch_update.tmp set /p "ver_entry="
	set "ver=%ver_entry:~15,-2%"
	set "UpdateVersion=%ver:~1%"
	
	set regex_command=powershell -Command "$x = Get-Content _assetlist.json -Raw; $k = $x | Select-String -Pattern '(?s)url(((?^^^!url).)*?)batch\.encoder'; $g = $k.Matches.Value | Select-String -Pattern '^""[^^^^"""]+?^""",'; $g.Matches.Value"
	
	FOR /F "tokens=*" %%g IN ('%regex_command%') do (SET API_link_entry=%%g)
	set "UpdateAPIURL=%API_link_entry:~1,-2%"

	rem Test if any of them are blank
	for %%a in (UpdateVersion, UpdateAPIURL) do if not defined %%a goto AutoUpdateError
	
	if exist "batch encoder v%UpdateVersion%.bat" set "append=_new"

	echo.
	if /i "%UpdateVersion%"=="%CurrentVersion%" (
		echo Current version is up-to-date.
		echo.
		echo Restarting program...
		echo.
		pause
		del "batch_update.json"
		goto AskProceed
	) else (
		echo Differing version found^^! ^(%CurrentVersion% -^> %UpdateVersion%^)
		echo Proceeding with update in 5 seconds, press CTRL+C or close window to cancel.
		echo.
		timeout /nobreak /t 5 > nul
		echo Downloading files...
		curl --silent -L -H "Accept: application/octet-stream" -o "batch encoder v%UpdateVersion%%append%.bat" %UpdateAPIURL%
		echo.
		echo Download complete. The program will now clean up and restart.
		pause
		del "batch_update.txt"
		(goto) 2>nul & "batch encoder v%UpdateVersion%%append%.bat" --updated-from "%~f0"
	)

:FFMPEGLocation
	rem TODO: detect FFMPEG if in same folder
	SET /P "LOCATION=Where is FFMPEG.exe located? [paste full path]: "
	
set /a "COUNTER=-1" 

:Count
	for %%f in (.\*) do set /a "COUNTER+=1"
	set "TOTAL=%COUNTER%"
	
set /a "COUNTER=0"
set "INPUTFILE="

:Conversion
	for %%f in (.\*) do (
	
		cls
		
		set "INPUTFILE=%%f"
		set "INPUTFILE=!INPUTFILE:~2!
		rem ^ removing ".\" from start of filename
	
		if /i "!INPUTFILE!"=="%~n0%~x0" (
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
			) else ( 
				set "TESTSTRING=!INPUTFILE:~-8!"
				if /i "!TESTSTRING!"==".DVR.mp4" (
					set "OUTPUTFILE=!INPUTFILE:~0,-8!.ENC.mp4"
				) else (
					set "OUTPUTFILE=!INPUTFILE:~0,-4!.ENC.mp4"
				)
				
				echo Supported file found^: ^(!INPUTFILE!^)
				
				timeout /t 5
			
				%LOCATION% -i "%CD%\!INPUTFILE!" -map 0 "%CD%\!OUTPUTFILE!"
				
				echo.
				echo.
				echo Performing file checks:
				echo ***********************
				echo.
				
				echo Checking for output file...
				if /i NOT exist "%CD%\!OUTPUTFILE!" goto CritError
				echo - Output file exists^^!
				echo.
				
				echo Checking output file length...
				FOR /F "tokens=*" %%g IN (
					'powershell -Command "$Shell = New-Object -ComObject Shell.Application; $Folder = $Shell.Namespace('%cd%'); $Folder.GetDetailsOf($Folder.ParseName('!INPUTFILE!'), 27)"'
					) do (SET LEN_INP=%%g)
				FOR /F "tokens=*" %%g IN (
					'powershell -Command "$Shell = New-Object -ComObject Shell.Application; $Folder = $Shell.Namespace('%cd%'); $Folder.GetDetailsOf($Folder.ParseName('!OUTPUTFILE!'), 27)"'
					) do (SET LEN_OUT=%%g)
				echo Input file: !LEN_INP! - Output file: !LEN_OUT!
				if /i NOT "!LEN_INP!"=="!LEN_OUT!" goto CritError
				echo - File lengths match^^!
				echo.
				echo Safely proceeding with input file recycling...
				timeout /nobreak /t 1 > nul
				
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
	echo A critical error occurred. The latest file has not been modified.
	goto EndPause
	
:AutoUpdateError
	echo.
	echo There was a problem with the auto-updater. Restarting program...
	echo.
	pause
	goto AskProceed

:ClearAndTitle
	cls
	echo Batch Encoder %CurrentVersion%
	goto:eof