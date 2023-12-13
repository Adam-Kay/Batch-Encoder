@echo off
setlocal enabledelayedexpansion

set "icongray=[7;90m"
set "iconyellow=[7;33m"
set "icongreen=[7;32m"
set "iconend=[0m"


:AskProceed
	cls
	SET /p "ProceedConf=%icongray% i %iconend% This program will attempt to forcibly update the batch encoder script. Do you want to proceed? [90m[Y/N][0m: "
	IF /i "%ProceedConf%"=="n" exit
	IF /i "%ProceedConf%"=="y" (goto AskFile)
	goto AskProceed
	
	
:AskFile
	cls
	set CONFIRMATION=
	for %%f in (*batch*encode*.bat) do (
		SET /p "FileConf=%icongray% ? %iconend% Is this the current batch encoder script file?: '%%f' [90m[Y/N][0m: "
		IF /i "!FileConf!"=="y" (
			set BEFile=%%f
			goto Update
		)
		IF /i "!FileConf!"=="n" (
			echo Trying next file...
			echo.
		) else (
			echo Unknown response '!FileConf!'. Restarting.
			call:GrayPause
			goto AskFile
		)
	)
	
:AskAnyway
	SET /p "AnywayConf=%iconyellow% X %iconend% Unable to find batch encoder script. Would you like to download the latest file anyway? [90m[Y/N][0m: "
	IF /i "%AnywayConf%"=="n" exit
	IF /i "%AnywayConf%"=="y" (goto Update)
	goto AskAnyway


:Update
	cls
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
	
	echo.
	echo %iconyellow% ^^! %iconend% Version found^^! ^([32m%UpdateVersion%^[0m)
	echo Proceeding with force update in 5 seconds, press CTRL+C or close window to cancel.
	echo.
	timeout /nobreak /t 5 > nul
	echo Downloading files...
	curl --silent -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%.bat" %UpdateAPIURL%
	echo.
	echo %icongreen% i %iconend% Download complete. The program will now clean up and restart.
	call:GrayPause
	if defined BEFile (
		if not "%BEFile%"=="batch encoder %UpdateVersion%.bat" (
			del "%BEFile%"
		)
	)
	del "%updateFileName%"
	(goto) 2>nul & "batch encoder %UpdateVersion%.bat" --updated-from "%~f0"
	
:AutoUpdateError
	del "%updateFileName%"
	echo.
	echo.
	echo [31m************************************************************[0m
	echo.
	echo There was a problem with the auto-updater. You can download the latest version of the program at: 
	echo https://github.com/Adam-Kay/Batch-Encoder/releases
	echo.
	echo The program will now exit.
	call:GrayPause
	exit
	
:GrayPause
	echo [90m
	pause
	echo [0m
	goto:eof