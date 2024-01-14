@echo off
setlocal enabledelayedexpansion

set CurrentVersion=v1.7.1
cls

set "icongray=[7;90m"
set "iconyellow=[7;33m"
set "icongreen=[7;32m"
set "iconred=[7;31m"
set "textgray=[90m"
set "textgreen=[32m"
set "textred=[31m"
set "textcyan=[36m"
set "formatend=[0m"
(set eline=^
%=this line is empty=%
)
set "space= "


for %%G in (%*) DO (if "%%G"=="--debug" (set "par_debug=true" & goto ArgParser))
	
:ArgParser
	set "FLAG=0"
	for %%G in (%*) DO (
		set ARG=%%G
		rem if FLAG, record the flag name
		echo !ARG! | findstr "\--" > nul && (
			if not ["!FLAG!"]==["0"] ( rem Check if FLAG is set - if it is, then previous was a boolean.
				set "par_!FLAG!=true"
				if "%par_debug%"=="true" (echo %iconyellow%par_!FLAG!=TRUE%formatend%)
			)
			set ARG_NAME=!ARG:~2!
			set "FLAG=!ARG_NAME!"
			if "%par_debug%"=="true" (echo %iconyellow%FLAG=!ARG_NAME!%formatend%)
		) || (
			set "par_!FLAG!=!ARG!"
			if "%par_debug%"=="true" (echo %iconyellow%par_!FLAG!=!ARG!%formatend%)
			set "FLAG=0"
		)
	)

	if not ["!FLAG!"]==["0"] ( rem Final boolean catch
		set "par_!FLAG!=true"
		if "%par_debug%"=="true" (echo %iconyellow%par_!FLAG!=TRUE%formatend%)
	)

if "%par_debug%"=="true" (pause)
cls

if defined par_help (
	::list help for args, then exit
	echo %formatend%Help for Batch Encoder %CurrentVersion%
	echo Program usage:
	echo.
	echo "batch encoder v%textgray%x%formatend%.%textgray%x%formatend%.%textgray%x%formatend%.bat"
	echo "batch encoder v%textgray%x%formatend%.%textgray%x%formatend%.%textgray%x%formatend%.bat" [options]
	echo "batch encoder v%textgray%x%formatend%.%textgray%x%formatend%.%textgray%x%formatend%.bat" --silent --update ^(true^|false^|force^) --ffmpegloc ^<path^> [options]
	echo.
	echo %textcyan%--silent%formatend%			Allows the program to operate without any prompts. 
	echo 				Requires --ffmpegloc and --update to be set.
	echo.
	echo %textcyan%--update%formatend% ^(true^|false^|force^)	Sets if the program should check for an update or not. 
	echo					'force' will update regardless of version.
	echo.
	echo %textcyan%--ffmpegloc%formatend% ^<path^>		Sets the path of FFmpeg. Will accept a relative path.
	echo.
	echo %textcyan%--verbose%formatend%			Restores FFmpeg display behavior to pre-v1.6.4 ^(expanded details^).
	echo.
	echo %textcyan%--speed%formatend% ^(1-9^)			Sets speed value. 1 is slowest, 9 is fastest. See prompt for more info.
	echo 				Currently only works when --silent flag is used.
	echo.
	echo %textcyan%--quality%formatend% ^(1-9^)			Sets quality value. 1 is lowest, 9 is highest. See prompt for more info.
	echo 				Currently only works when --silent flag is used.
	echo.
	
	goto EndPause
)

if defined par_updated-from (
	echo %icongray% ^^! %formatend% Just updated^^! Running cleanup...
	timeout /nobreak 2 > nul
	::↓ special format to remove " from string
	del "%par_updated-from:"=%"
)


:AskProceed
	call:ClearAndTitle
	if "%par_silent%"=="true" (goto AskUpdate)
	echo %icongray% i %formatend% This program will aim to encode all .mp4 files in the folder it's placed in and recycle the originals.
	set /p "startconfirmation=Do you want to proceed? %textgray%[Y/N]%formatend%: "
	if /i "%startconfirmation%"=="n" exit
	if /i "%startconfirmation%"=="y" (goto AskUpdate)
	goto AskProceed

:AskUpdate
	call:ClearAndTitle
	if /i "%par_silent%"=="true" (
		if not defined par_update (echo Error: --silent switch used but --update ^(true^|false^|force^) not provided. & exit /b 1)
		set "par_update=%par_update:"=%"
		if /i "%par_update%"=="false" (goto FFMPEGLocation)
		if /i "%par_update%"=="true" (goto AutoUpdate)
		if /i "%par_update%"=="force" (goto AutoUpdate)
		echo Error: --update argument invalid ^(should be ^(true^|false^|force^)^). & exit /b 1
	)
	if /i "%par_update%"=="force" (goto AutoUpdate)
	set /p "updateconfirmation=%icongray% ^ %formatend% Would you like to check for an update? %textgray%[Y/N]%formatend%: "
	if /i "%updateconfirmation%"=="n" (goto FFMPEGLocation)
	if /i "%updateconfirmation%"=="y" (goto AutoUpdate)
	goto AskUpdate
	
:AutoUpdate
	call:ClearAndTitle
	if exist "batch encoder %UpdateVersion%%append%-u.bat" (del "batch encoder %UpdateVersion%%append%-u.bat")
	echo %icongray% i %formatend% Downloading information...
	set "updateFileName=batch_update.json"
	curl --silent -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version:2022-11-28" -o %updateFileName% https://api.github.com/repos/Adam-Kay/Batch-Encoder/releases/latest
	if not exist "%updateFileName%" (goto AutoUpdateError)
	
	>%TEMP%\batch_update.tmp findstr "tag_name" %updateFileName%
	<%TEMP%\batch_update.tmp set /p "entry_ver="
	set "ver=%entry_ver:~15,-2%"
	set "UpdateVersion=v%ver:~1%"
	
	>%TEMP%\batch_update.tmp findstr "body" %updateFileName%
	set "pwsh_replace=-replace '^!' -replace '^<\/\S*?^>', '#[FORMEND]#' -replace '^<\S*?^>', '#[FORM]#' -replace '^<', '(less)' -replace '^>', '(more)'"
	for /F "tokens=*" %%g in ('powershell -Command "(Get-Content $env:TEMP\batch_update.tmp) !pwsh_replace! "') do (set entry_body=%%g)
	set "changelog=%entry_body:~9,-1%"
	set "changelog=%changelog:#[FORM]#=[1m%"
	set "changelog=%changelog:#[FORMEND]#=!formatend!%"
	set "changelog=%changelog:\n#=\n\r\n#%"
	set "changelog=%changelog:#=[100;37m#%"
	set "changelog=%changelog:\r=!formatend!\r%"
	set "changelog=%changelog: `= [1m%"
	set "changelog=%changelog:` =!formatend! %"

	>%TEMP%\batch_update.tmp echo %changelog%
	for %%? in (%TEMP%\batch_update.tmp) do (set /A strlength=%%~z? - 2)
	if %strlength% gtr 1000 (set "changelog=%changelog:~0,1000%... %textgray%[More]%formatend%")
	
	set regex_command=powershell -Command "$x = Get-Content %updateFileName% -Raw; $k = $x | Select-String -Pattern '(?s)url(((?^^^!url).)*?)batch\.encoder'; $g = $k.Matches.Value | Select-String -Pattern '^""[^^^^"""]+?^""",'; $g.Matches.Value"
	
	for /F "tokens=*" %%g in ('%regex_command%') do (set entry_APILink=%%g)
	set "UpdateAPIURL=%entry_APILink:~1,-2%"

	for %%a in (entry_ver, entry_APILink, UpdateVersion, UpdateAPIURL) do if not defined %%a goto AutoUpdateError
	
	if exist "batch encoder %UpdateVersion%.bat" set "append=_new"

	echo.
	if /i not "%par_update%"=="force" (
		if /i "%UpdateVersion%"=="%CurrentVersion%" (
			echo %icongray% - %formatend% Current version is up-to-date.
			echo.
			echo The program will now restart.
			call:GrayPause
			del "%updateFileName%"
			if /i "%par_silent%"=="true" (
				(goto) 2>nul & "%~f0" %* --update false
			) else (
				(goto) 2>nul & "%~f0"
			)
		)
	)
	if /i "%par_update%"=="force" (
		echo %iconyellow% ^^! %formatend% Version found^^! ^(%textgreen%%UpdateVersion%%formatend%^)
		echo Proceeding with force update in 5 seconds; close window to cancel.
	) else (
		echo %iconyellow% ^^! %formatend% Differing version found^^! ^(%textred%%CurrentVersion%%formatend% -^> %textgreen%%UpdateVersion%%formatend%^)
		echo Proceeding with update in 5 seconds; close window to cancel.
	)
	:: ... anim
	echo. & echo [s
	for /l %%x in (1, 1, 6) do (
		timeout /nobreak /t 1 > nul
		echo [u.[s
	)
	echo [1ADownloading files...
	curl --silent -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%%append%-u.bat" %UpdateAPIURL%
	echo.
	if not exist "batch encoder %UpdateVersion%%append%-u.bat" (
		echo %iconred% ^^! %formatend% Download failed. & echo. & echo Attempting alternate download...
		curl --silent --ssl-no-revoke -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%%append%-u.bat" %UpdateAPIURL%
		echo.
		if not exist "batch encoder %UpdateVersion%%append%-u.bat" (
			echo %iconred% ^^! %formatend% Alternate download failed.
			goto AutoUpdateError
		)
	)
	move /Y "batch encoder %UpdateVersion%%append%-u.bat" "batch encoder %UpdateVersion%%append%.bat" > nul
	echo %icongreen% i %formatend% Download complete. 
	echo. & echo.
	echo %changelog:\r\n=!eline!%%formatend%
	echo.
	echo You can read the full changelog at: https://github.com/Adam-Kay/Batch-Encoder/releases
	echo.
	echo %icongray% i %formatend% The program will now clean up and restart.
	call:GrayPause
	del "%updateFileName%"
	if /i "%par_silent%"=="true" (
		(goto) 2>nul & "batch encoder %UpdateVersion%%append%.bat" --updated-from "%~f0" %* --update false
	) else (
		(goto) 2>nul & "batch encoder %UpdateVersion%%append%.bat" --updated-from "%~f0"
	)
	

:FFMPEGLocation
	call:ClearAndTitle
	if /i "%par_silent%"=="true" (
		if not defined par_ffmpegloc (echo Error: --silent switch used but --ffmpegloc ^<path^> not provided. & exit /b 1)
		set "par_ffmpegloc=%par_ffmpegloc:"=%"
		if not exist "%par_ffmpegloc%" (
			echo Error: --ffmpegloc path "%par_ffmpegloc%" provided does not exist.
			exit /b 1
		) else (
			set "LOCATION=%par_ffmpegloc%"
			goto EncodingOptSelect
		)
	)
	set /p "LOCATION=%icongray% ? %formatend% Where is FFMPEG.exe located? (paste full path): "
	set "LOCATION=%LOCATION:"=%"
	if not exist "%LOCATION%" (
		if not exist "%cd%\%LOCATION%" (
			echo.
			echo Error: Provided filepath "%LOCATION%" does not exist.
			call:GrayPause
			goto FFMPEGLocation
		)
	)

:EncodingOptSelect
	if /i "%par_silent%"=="true" (goto AdvancedEncodeSpeed)
	call:ClearAndTitle
	rem Remove in future release:
	if "%CurrentVersion%"=="v1.7.0" (echo [100m NEW^^! %formatend%) 
	echo There are multiple encoding options available. If you are not sure which to choose, select 'Simple'.
	echo.
	echo [%textcyan%s%formatend%] Simple encode - default options, and the one used in previous versions.
	echo [%textcyan%a%formatend%] Advanced encode - options to control quality and speed of output video.
	echo.
	set /p "encodeopt=Option: "
	if /i "%encodeopt%"=="s" (goto Before_Convert)
	if /i "%encodeopt%"=="a" (goto AdvancedEncodeSpeed)
	goto EncodingOptSelect
	
:AdvancedEncodeSpeed
	call:ClearAndTitle "Advanced Encoding"
	set "speeds[9]=ultrafast" & set "speeds[8]=superfast" & set "speeds[7]=veryfast" & set "speeds[6]=faster" & set "speeds[5]=fast"
	set "speeds[4]=medium" & set "speeds[3]=slow" & set "speeds[2]=slower" & set "speeds[1]=veryslow" & set "speeds[d]=medium"
	
	if /i "%par_silent%"=="true" (
		if defined par_speed (
			set "speed_inp=%par_speed%"
		) else ( 
			goto AdvancedEncodeQuality
		)
	) else (	
		echo [100m Speed %formatend%
		echo.
		echo Please enter a value between 1 and 9, where 1 is the slowest speed and 9 is the fastest
		echo - or enter [%textcyan%d%formatend%] for default ^(4^).
		echo.
		echo  Slower Speed		    		    Faster Speed
		echo  Smaller Filesize		   	 Larger Filesize
		echo 	[90m^|					^|[0m
		echo 	[90m+----+----+----+----+----+----+----+----+[0m
		echo 	1    2    3    4    5    6    7    8    9
		echo 		       [90m^|[0m
		echo			    Default
		echo.
		
		set /p "speed_inp=Speed: "
	)
	
	set "speed_choice=!speeds[%speed_inp%]!
	if not defined speed_choice (
		if /i "%par_silent%"=="true" (
			(echo Error: --speed value '%par_speed%' is invalid. Should be an integer between 1 and 9. & exit /b 1)
		) else (
			goto AdvancedEncodeSpeed
		)
	)

:AdvancedEncodeQuality
	call:ClearAndTitle "Advanced Encoding"
	if /i "%par_silent%"=="true" (
		if defined par_quality (
			set "quality_inp=%par_quality%"
		) else ( 
			goto Before_Convert
		)
	) else (
		echo [100m Quality %formatend%
		echo.
		echo Please select a value between 1 and 9, where 1 is the lowest quality and 9 is the highest
		echo - or enter [%textcyan%d%formatend%] for default ^(6^).
		echo.
		echo  Lower Quality		    		  Higher Quality
		echo  Smaller Filesize		   	 Larger Filesize
		echo 	[90m^|					^|[0m
		echo 	[90m+----+----+----+----+----+----+----+----+[0m
		echo 	1    2    3    4    5    6    7    8    9
		echo 				 [90m^|[0m
		echo 			      Default
		echo.

		set /p "quality_inp=Quality: "
	)
	
	if %quality_inp: =0% geq 1 (
		if %quality_inp: =0% leq 9 (
			set /a "quality_choice=%quality_inp%+0"
		)
	)
	if /i "%quality_input%"=="d" (set "quality_choice=4")
	
	if not defined quality_choice (
		if /i "%par_silent%"=="true" (
			(echo Error: --quality value '%par_quality%' is invalid. Should be an integer between 1 and 9. & exit /b 1)
		) else (
			goto AdvancedEncodeQuality
		)
	)
	
:Before_Convert
	set "LOC_TEST=%LOCATION:\=%"
	set "LOC_TEST=%LOC_TEST:/=%"
	if "%LOC_TEST%"=="%LOCATION%" (set "pwsh_prefix=.\")
	set "LOCATION_pwsh=%pwsh_prefix%%LOCATION:"=%
	
	set /a "COUNTER=-1"
	for %%f in (.\*) do set /a "COUNTER+=1"
	set "TOTAL=%COUNTER%"
	set /a "COUNTER=0"
	set /a "VALIDCOUNTER=0"
	set "INPUTFILE="
	
	if defined speed_choice (
		set "speed_arg=-preset %speed_choice%"
		if defined quality_choice (set "spacer= ")
		set "speed_text=Speed:%speed_inp%!spacer!"
	)
	if defined quality_choice (
		set /a crfval=40+^(%quality_choice%*-3^)
		set "quality_arg=-crf !crfval!"
		set "quality_text=Quality:%quality_choice%"
	)

:Conversion
	if /i not "%par_verbose%"=="true" (set "quietargs=-v quiet -stats ")
	for %%f in (.\*) do (
	
		call:ClearAndTitle "%speed_text%%quality_text%"
		
		set "outputfiledupe=false"
		set "INPUTFILE=%%f"
		set "INPUTFILE=!INPUTFILE:~2!
		rem ^ removing ".\" from start of filename
	
		if /i "!INPUTFILE!"=="%~n0%~x0" (
			echo Skipping self.
			call:GrayTimeout 2
		) else (
			set /a "COUNTER+=1" 
			echo [100m Encoding !COUNTER! of %TOTAL% %formatend%
				
			set "TESTSTRING=!INPUTFILE:~-4!"
			if /i not "!TESTSTRING!"==".mp4" (
				echo Skipping unsupported file^: ^(!INPUTFILE!^)
				call:GrayTimeout 3
			) else ( 
				set "TESTSTRING=!INPUTFILE:~-8!"
				if /i "!TESTSTRING!"==".DVR.mp4" (
					if not exist "!INPUTFILE:~0,-8!.ENC.mp4" (
						set "OUTPUTFILE=!INPUTFILE:~0,-8!.ENC.mp4"
					) else (
						set "outputfiledupe=true"
						set "OUTPUTFILE=!INPUTFILE:~0,-8!_!date!-!time::=-!.ENC.mp4"
					)
				) else (
					if not exist "!INPUTFILE:~0,-4!.ENC.mp4" (
						set "OUTPUTFILE=!INPUTFILE:~0,-4!.ENC.mp4"
					) else (
						set "outputfiledupe=true"
						set "OUTPUTFILE=!INPUTFILE:~0,-4!_!date!-!time::=-!.ENC.mp4"
					)
				)
				
				set /a "VALIDCOUNTER+=1" 
				echo Supported file found^: ^(!INPUTFILE!^)
				if /i "!outputfiledupe!"=="true" (echo Proposed output file already exists^^^! Appending timestamp...)
				
				call:GrayTimeout 5
				
				rem Move cursor 3 lines up
				echo [3A
			
				"%LOCATION%" %quietargs% -i "%CD%\!INPUTFILE!" -map 0 %quality_arg% %speed_arg% "%CD%\!OUTPUTFILE!"
				
				echo.
				echo.
				echo Performing file checks:
				echo ***********************
				echo.
				
				echo %icongray% ^| %formatend% Checking for output file...
				if /i not exist "%CD%\!OUTPUTFILE!" call:CritError "Output file '!OUTPUTFILE!' does not exist."
				echo - Output file exists^^!
				echo.
				
				echo %icongray% ^| %formatend% Checking output file length...
				for /F "tokens=*" %%g in ( 'powershell -Command "(^& '%LOCATION_pwsh%' -i '!INPUTFILE!' 2>&1 | select-String 'Duration: (.*), s').Matches.Groups[1].Value"'
					) do (set LEN_INP=%%g)
				for /F "tokens=*" %%g in ( 'powershell -Command "(^& '%LOCATION_pwsh%' -i '!OUTPUTFILE!' 2>&1 | select-String 'Duration: (.*), s').Matches.Groups[1].Value"'
					) do (set LEN_OUT=%%g)
				for /F "tokens=*" %%g in ( 'powershell -Command "[Math]::Abs(((Get-Date !LEN_INP!) - (Get-Date !LEN_OUT!)).TotalSeconds)"'
					) do (set LEN_DIFF=%%g)
				
				echo Input file: !LEN_INP! - Output file: !LEN_OUT!
				if !LEN_DIFF! gtr 1 (
					call:CritError "File length disparity outside of acceptable range ^(was !LEN_DIFF! seconds^^^)
				)
				echo - File lengths within range^^!
				echo.
				echo %icongreen% ^| %formatend% Safely proceeding with input file recycling...
				timeout /nobreak /t 1 > nul
				
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').CreationTime=((Get-Item '%CD%\!INPUTFILE!').CreationTime)"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').LastWriteTime=((Get-Item '%CD%\!INPUTFILE!').LastWriteTime)"
				powershell -Command "(Get-Item '%CD%\!OUTPUTFILE!').LastAccessTime=((Get-Item '%CD%\!INPUTFILE!').LastAccessTime)"
				
				::delete to recycle bin
				powershell -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('%CD%\!INPUTFILE!','OnlyErrorDialogs','SendToRecycleBin')"
			)
		)
	)
	
call:ClearAndTitle
set /a "SKIPCOUNTER=%TOTAL%-%VALIDCOUNTER%
if %VALIDCOUNTER% gtr 0 (echo [42;97m Completed encoding %VALIDCOUNTER% files. %formatend%)
if %SKIPCOUNTER% gtr 0 (echo [100;37m Skipped %SKIPCOUNTER% invalid files. %formatend%)
if %TOTAL% equ 0 (echo [100;37m No files found. %formatend%)

:EndPause
	call:GrayPause
	(goto) 2>nul || exit /b 0
	
:CritError
	timeout /t 1 > nul
	echo.
	call:ErrorLine
	echo.
	echo A critical error occurred. The latest file has not been modified.
	set errmsg=%~1
	if defined errmsg (echo Error message provided: %errmsg%)
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
	echo [91m____________________________________________________________%formatend%
	rem echo [91m************************************************************%formatend%
	rem echo [7;31m ********************************************************** %formatend%
	goto:eof

:ClearAndTitle
	cls
	set "message=%~1"
	if defined message (set "message=- %message% ")
	echo [7m Batch Encoder %CurrentVersion% %message%%formatend%
	echo.
	goto:eof
