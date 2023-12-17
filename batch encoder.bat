@echo off
setlocal enabledelayedexpansion

set CurrentVersion=v1.5.2
cls

set "icongray=[7;90m"
set "iconyellow=[7;33m"
set "icongreen=[7;32m"
set "textgray=[90m"
set "textgreen=[32m"
set "textred=[31m"
set "formatend=[0m"

:ArgParser
	set "FLAG=0"
	for %%G in (%*) DO (
		set ARG=%%G
		rem if FLAG, record the flag name
		echo !ARG! | findstr "\--" > nul && (
			if not ["!FLAG!"]==["0"] ( rem Check if FLAG is set - if it is, then previous was a boolean.
				set "par_!FLAG!=true"
				echo %iconyellow%par_!FLAG!=TRUE%formatend%
			)
			set ARG_NAME=!ARG:~2!
			set "FLAG=!ARG_NAME!"
			echo %iconyellow%FLAG=!ARG_NAME!%formatend%
		) || (
			set "par_!FLAG!=!ARG!"
			echo %iconyellow%par_!FLAG!=!ARG!%formatend%
			set "FLAG=0"
		)
	)

	if not ["!FLAG!"]==["0"] ( rem Final boolean catch
		set "par_!FLAG!=true"
		echo %iconyellow%par_!FLAG!=TRUE%formatend%
	)


if defined par_updated-from (
	echo %icongray% ^^! %formatend% Just updated^^! Running cleanup...
	timeout /nobreak 2 > nul
	rem ↓ special format to remove " from string
	del "%par_updated-from:"=%"
)

pause rem remove

:AskProceed
	call:ClearAndTitle
	if "%par_silent%"=="true" (goto AskUpdate)
	echo %icongray% i %formatend% This program will aim to encode all .mp4 files in the folder it's placed in and delete the originals.
	set /p "startconfirmation=Do you want to proceed? %textgray%[Y/N]%formatend%: "
	if /i "%startconfirmation%"=="n" exit
	if /i "%startconfirmation%"=="y" (goto AskUpdate)
	goto AskProceed

:AskUpdate
	call:ClearAndTitle
	if /i "%par_silent%"=="true" (
		if not defined par_update (echo Error: --silent switch used but --update [true/false] not provided. & exit /b 1)
		set "par_update=%par_update:"=%"
		if /i "%par_update%"=="false" (goto FFMPEGLocation)
		if /i "%par_update%"=="true" (goto AutoUpdate)
		echo Error: --update argument invalid ^(should be [true/false]^). & exit /b 1
	)
	set /p "updateconfirmation=%icongray% ^ %formatend% Would you like to check for an update? %textgray%[Y/N]%formatend%: "
	if /i "%updateconfirmation%"=="n" (goto FFMPEGLocation)
	if /i "%updateconfirmation%"=="y" (goto AutoUpdate)
	goto AskUpdate
	
:AutoUpdate
	call:ClearAndTitle
	echo %icongray% i %formatend% Downloading information...
	set "updateFileName=batch_update.json"
	curl --silent -L -H "Accept: application/vnd.github+json" -o %updateFileName% https://api.github.com/repos/Adam-Kay/Batch-Encoder/releases/latest
	
	>%TEMP%\batch_update.tmp findstr "tag_name" %updateFileName%
	<%TEMP%\batch_update.tmp set /p "ver_entry="
	set "ver=%ver_entry:~15,-2%"
	set "UpdateVersion=v%ver:~1%"
	
	set regex_command=powershell -Command "$x = Get-Content %updateFileName% -Raw; $k = $x | Select-String -Pattern '(?s)url(((?^^^!url).)*?)batch\.encoder'; $g = $k.Matches.Value | Select-String -Pattern '^""[^^^^"""]+?^""",'; $g.Matches.Value"
	
	for /F "tokens=*" %%g in ('%regex_command%') do (set API_link_entry=%%g)
	set "UpdateAPIURL=%API_link_entry:~1,-2%"

	for %%a in (ver_entry, API_link_entry, UpdateVersion, UpdateAPIURL) do if not defined %%a goto AutoUpdateError
	
	if exist "batch encoder %UpdateVersion%.bat" set "append=_new"

	echo.
	if /i "%UpdateVersion%"=="%CurrentVersion%" (
		echo %icongray% - %formatend% Current version is up-to-date.
		echo.
		echo The program will now restart.
		call:GrayPause
		del "%updateFileName%"
		if /i "%par_silent%"=="true" (
			(goto) 2>nul & "%~f0" --silent --update false --ffmpegloc "%par_ffmpegloc%"
		) else (
			(goto) 2>nul & "%~f0"
		)
	) else (
		echo %iconyellow% ^^! %formatend% Differing version found^^! ^(%textred%%CurrentVersion%%formatend% -^> %textgreen%%UpdateVersion%%formatend%^)
		echo Proceeding with update in 5 seconds, press CTRL+C or close window to cancel.
		echo.
		timeout /nobreak /t 5 > nul
		echo Downloading files...
		curl --silent -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%%append%.bat" %UpdateAPIURL%
		echo.
		echo %icongreen% i %formatend% Download complete. The program will now clean up and restart. 
		call:GrayPause
		del "%updateFileName%"
		if /i "%par_silent%"=="true" (
			(goto) 2>nul & "batch encoder %UpdateVersion%%append%.bat" --updated-from "%~f0" --silent --update false --ffmpegloc "%par_ffmpegloc%"
		) else (
			(goto) 2>nul & "batch encoder %UpdateVersion%%append%.bat" --updated-from "%~f0"
		)
	)

:FFMPEGLocation
	call:ClearAndTitle
	if /i "%par_silent%"=="true" (
		if not defined par_ffmpegloc (echo Error: --silent switch used but --ffmpegloc [path] not provided. & exit /b 1)
		set "par_ffmpegloc=%par_ffmpegloc:"=%"
		if not exist "%par_ffmpegloc%" (
			echo Error: --ffmpegloc path "%par_ffmpegloc%" provided does not exist.
			exit /b 1
		) else (
			set "LOCATION=%par_ffmpegloc%"
			goto Count
		)
	)
	set /p "LOCATION=%icongray% ? %formatend% Where is FFMPEG.exe located? (paste full path): "

:Count
	set /a "COUNTER=-1"
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
			echo [100m Encoding !COUNTER! of %TOTAL% %formatend%
			rem echo **********************************
				
			set "TESTSTRING=!INPUTFILE:~-4!"
			if /i not "!TESTSTRING!"==".mp4" (
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
				
				echo %icongray% ^| %formatend% Checking for output file...
				if /i not exist "%CD%\!OUTPUTFILE!" goto CritError
				echo - Output file exists^^!
				echo.
				
				echo %icongray% ^| %formatend% Checking output file length...
				for /F "tokens=*" %%g in (
					'powershell -Command "$Shell = New-Object -ComObject Shell.Application; $Folder = $Shell.Namespace('%cd%'); $Folder.GetDetailsOf($Folder.ParseName('!INPUTFILE!'), 27)"'
					) do (set LEN_INP=%%g)
				for /F "tokens=*" %%g in (
					'powershell -Command "$Shell = New-Object -ComObject Shell.Application; $Folder = $Shell.Namespace('%cd%'); $Folder.GetDetailsOf($Folder.ParseName('!OUTPUTFILE!'), 27)"'
					) do (set LEN_OUT=%%g)
				echo Input file: !LEN_INP! - Output file: !LEN_OUT!
				if /i not "!LEN_INP!"=="!LEN_OUT!" goto CritError
				echo - File lengths match^^!
				echo.
				echo %icongreen% ^| %formatend% Safely proceeding with input file recycling...
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
echo [42;97m Completed encoding %TOTAL% files. %formatend%

:EndPause
	call:GrayPause
	exit
	
:CritError
	timeout /t 1
	echo.
	call:ErrorLine
	echo.
	echo A critical error occurred. The latest file has not been modified.
	if /i "%par_silent%"=="true" (exit /b 3)
	goto EndPause
	
:AutoUpdateError
	del "%updateFileName%"
	echo.
	call:ErrorLine
	echo.
	echo There was a problem with the auto-updater. You can download the latest version of the program at: 
	echo https://github.com/Adam-Kay/Batch-Encoder/releases
	echo.
	if /i "%par_silent%"=="true" (exit /b 2)
	echo The program will now restart.
	call:GrayPause
	(goto) 2>nul & "%~f0"
	
:GrayPause
	echo %textgray%
	if /i not "%par_silent%"=="true" (pause)
	echo %formatend%
	goto:eof
	
:GrayTimeout
	set timer=%~1
	<nul set /p=%textgray%
	for %%a in (timer) do if not defined %%a (
		timeout /t 5
	) else (
		timeout /t %timer%
	)
	echo %formatend%
	goto:eof
	
:ErrorLine
	rem echo [4;31m                                                            %formatend%
	echo %textred%************************************************************%formatend%
	rem echo [7;31m ********************************************************** %formatend%
	goto:eof

:ClearAndTitle
	cls
	echo [7m Batch Encoder %CurrentVersion% %formatend%
	echo.
	goto:eof
