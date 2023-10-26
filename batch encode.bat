@echo off
setlocal enabledelayedexpansion

:AskProceed
cls
	SET /P "CONFIRMATION=This program will aim to encode all .mp4 files in the folder it's placed in and delete the originals. Do you want to proceed? [Y/N] : "
	IF /i "%CONFIRMATION%"=="n" exit
	IF /i "%CONFIRMATION%"=="y" (goto AskLocation)
	goto AskProceed

:AskLocation
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
			echo ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
				
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
			
				%LOCATION% -i "%CD%\!INPUTFILE!" "%CD%\!OUTPUTFILE!"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').CreationTime=((Get-Item '%CD%\!INPUTFILE!').CreationTime)"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').LastWriteTime=((Get-Item '%CD%\!INPUTFILE!').LastWriteTime)"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').LastAccessTime=((Get-Item '%CD%\!INPUTFILE!').LastAccessTime)"
				del "!INPUTFILE!"
			)
		)
	)
	
cls
echo Completed encoding %TOTAL% files.
echo ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
	
:EndPause
	pause
