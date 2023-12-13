@echo off
setlocal enabledelayedexpansion

SET CurrentVersion=v1.5.1

cls
if /i "%1"=="--updated-from" (
	echo Just updated^^! Running cleanup...
	timeout 1
	del %2
)

set "icongray=[7;90m"
set "iconyellow=[7;33m"
set "icongreen=[7;32m"
set "iconend=[0m"


:AskProceed
	call:ClearAndTitle
	echo %icongray% i %iconend% This program will aim to encode all .mp4 files in the folder it's placed in and delete the originals.
	SET /P "startconfirmation=Do you want to proceed? [90m[Y/N][0m: "
	IF /i "%startconfirmation%"=="n" exit
	IF /i "%startconfirmation%"=="y" (goto AskUpdate)
	goto AskProceed

:AskUpdate
	call:ClearAndTitle
	SET /P "updateconfirmation=%icongray% ^ %iconend% Would you like to check for an update? [90m[Y/N][0m: "
	IF /i "%updateconfirmation%"=="n" (goto FFMPEGLocation)
	IF /i "%updateconfirmation%"=="y" (goto AutoUpdate)
	goto AskUpdate
	
:AutoUpdate
	call:ClearAndTitle
	echo %icongray% i %iconend% Downloading information...
	set "updateFileName=batch_update.json"
	curl --silent -L -H "Accept: application/vnd.github+json" -o %updateFileName% https://api.github.com/repos/Adam-Kay/Batch-Encoder/releases/latest
	rem curl --silent -o batch_update.txt https://gist.githubusercontent.com/Adam-Kay/ec5da0ff40e8eb14beee2242161f5191/raw
	
	>%TEMP%\batch_update.tmp findstr "tag_name" %updateFileName%
	<%TEMP%\batch_update.tmp set /p "ver_entry="
	set "ver=%ver_entry:~15,-2%"
	set "UpdateVersion=v%ver:~1%"
	
	set regex_command=powershell -Command "$x = Get-Content %updateFileName% -Raw; $k = $x | Select-String -Pattern '(?s)url(((?^^^!url).)*?)batch\.encoder'; $g = $k.Matches.Value | Select-String -Pattern '^""[^^^^"""]+?^""",'; $g.Matches.Value"
	
	FOR /F "tokens=*" %%g IN ('%regex_command%') do (SET API_link_entry=%%g)
	set "UpdateAPIURL=%API_link_entry:~1,-2%"

	for %%a in (ver_entry, API_link_entry, UpdateVersion, UpdateAPIURL) do if not defined %%a goto AutoUpdateError
	
	if exist "batch encoder %UpdateVersion%.bat" set "append=_new"

	echo.
	if /i "%UpdateVersion%"=="%CurrentVersion%" (
		echo %icongray% - %iconend% Current version is up-to-date.
		echo.
		echo Restarting program...
		call:GrayPause
		del "%updateFileName%"
		goto AskProceed
	) else (
		echo %iconyellow% ^^! %iconend% Differing version found^^! ^([31m%CurrentVersion%[0m -^> [32m%UpdateVersion%[0m^)
		echo Proceeding with update in 5 seconds, press CTRL+C or close window to cancel.
		echo.
		timeout /nobreak /t 5 > nul
		echo Downloading files...
		curl --silent -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%%append%.bat" %UpdateAPIURL%
		echo.
		echo Download complete. The program will now clean up and restart. 
		call:GrayPause
		del "%updateFileName%"
		(goto) 2>nul & "batch encoder %UpdateVersion%%append%.bat" --updated-from "%~f0"
	)

:FFMPEGLocation
	call:ClearAndTitle
	rem TODO: detect FFMPEG if in same folder
	SET /P "LOCATION=%icongray% ? %iconend% Where is FFMPEG.exe located? (paste full path): "
	
set /a "COUNTER=-1" 

:Count
	for %%f in (.\*) do set /a "COUNTER+=1"
	set "TOTAL=%COUNTER%"
	
set /a "COUNTER=0"
set "INPUTFILE="

:Conversion
	for %%f in (.\*) do (
	
		call:ClearAndTitle
		
		set "INPUTFILE=%%f"
		set "INPUTFILE=!INPUTFILE:~2!
		rem ^ removing ".\" from start of filename
	
		if /i "!INPUTFILE!"=="%~n0%~x0" (
			echo Skipping self.
			call:GrayTimeout 2
		) else (
			set /a "COUNTER+=1" 
			echo [100m Encoding !COUNTER! of %TOTAL% [0m
			rem echo **********************************
				
			set "TESTSTRING=!INPUTFILE:~-4!"
			if /i NOT "!TESTSTRING!"==".mp4" (
				echo Skipping unsupported file^: ^(!INPUTFILE!^)
				call:GrayTimeout 3
			) else ( 
				set "TESTSTRING=!INPUTFILE:~-8!"
				if /i "!TESTSTRING!"==".DVR.mp4" (
					set "OUTPUTFILE=!INPUTFILE:~0,-8!.ENC.mp4"
				) else (
					set "OUTPUTFILE=!INPUTFILE:~0,-4!.ENC.mp4"
				)
				
				echo Supported file found^: ^(!INPUTFILE!^)
				
				call:GrayTimeout 5
			
				%LOCATION% -i "%CD%\!INPUTFILE!" -map 0 "%CD%\!OUTPUTFILE!"
				
				echo.
				echo.
				echo Performing file checks:
				echo ***********************
				echo.
				
				echo %icongray% ^| %iconend% Checking for output file...
				if /i NOT exist "%CD%\!OUTPUTFILE!" goto CritError
				echo - Output file exists^^!
				echo.
				
				echo %icongray% ^| %iconend% Checking output file length...
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
				echo %icongreen% ^| %iconend% Safely proceeding with input file recycling...
				timeout /nobreak /t 1 > nul
				
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').CreationTime=((Get-Item '%CD%\!INPUTFILE!').CreationTime)"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').LastWriteTime=((Get-Item '%CD%\!INPUTFILE!').LastWriteTime)"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').LastAccessTime=((Get-Item '%CD%\!INPUTFILE!').LastAccessTime)"
				
				REM delete to recycle bin
				powershell -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('%CD%\!INPUTFILE!','OnlyErrorDialogs','SendToRecycleBin')"
			)
		)
	)
	
call:ClearAndTitle
echo [42;97m Completed encoding %TOTAL% files. [0m

:EndPause
	call:GrayPause
	exit
	
:CritError
	timeout /t 1
	echo.
	call:ErrorLine
	echo.
	echo A critical error occurred. The latest file has not been modified.
	goto EndPause
	
:AutoUpdateError
	del "%updateFileName%"
	echo.
	call:ErrorLine
	echo.
	echo There was a problem with the auto-updater. You can download the latest version of the program at: 
	echo https://github.com/Adam-Kay/Batch-Encoder/releases
	echo.
	echo The program will now restart.
	call:GrayPause
	goto AskProceed
	
:GrayPause
	echo [90m
	pause
	echo [0m
	goto:eof
	
:GrayTimeout
	set timer=%~1
	<nul set /p=[90m
	for %%a in (timer) do if not defined %%a (
		timeout /t 5
	) else (
		timeout /t %timer%
	)
	echo [0m
	goto:eof
	
:ErrorLine
	rem echo [4;31m                                                            [0m
	echo [31m************************************************************[0m
	rem echo [7;31m ********************************************************** [0m
	goto:eof

:ClearAndTitle
	cls
	echo [7m Batch Encoder %CurrentVersion% [0m
	echo.
	goto:eof