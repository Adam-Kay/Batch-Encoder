@echo off
setlocal enabledelayedexpansion

set "icongray=[7;90m"
set "iconyellow=[7;33m"
set "icongreen=[7;32m"
set "iconred=[7;31m"
set "textgray=[90m"
set "textgreen=[32m"
set "textred=[31m"
set "formatend=[0m"


if /i "%1"=="--silent" (
	set "par_silent=true"
)


:AskProceed
	cls
	if "%par_silent%"=="true" (goto AskFile)
	SET /p "ProceedConf=%icongray% i %formatend% This program will attempt to forcibly update the batch encoder script. Do you want to proceed? %textgray%[Y/N]%formatend%: "
	IF /i "%ProceedConf%"=="n" exit
	IF /i "%ProceedConf%"=="y" (goto AskFile)
	goto AskProceed
	
	
:AskFile
	cls
	for %%f in (*batch*encode*.bat) do (
		if "%par_silent%"=="true" (
			set "FileConf=y"
		) else (
			SET /p "FileConf=%icongray% ? %formatend% Is this the current batch encoder script file?: '%%f' %textgray%[Y/N]%formatend%: "
		)
		IF /i "!FileConf!"=="y" (
			set BEFile=%%f
			goto Update
		)
		IF /i "!FileConf!"=="n" (
			echo Trying next file...
			echo.
		) else (
			echo Unknown response '!FileConf!'. The program will now restart.
			call:GrayPause
			goto AskFile
		)
	)
	
:AskAnyway
	SET /p "AnywayConf=%iconyellow% X %formatend% Unable to find batch encoder script. Would you like to download the latest file anyway? %textgray%[Y/N]%formatend%: "
	IF /i "%AnywayConf%"=="n" exit
	IF /i "%AnywayConf%"=="y" (goto Update)
	goto AskAnyway


:Update
	cls
	if exist "batch encoder %UpdateVersion%%append%-u.bat" (del "batch encoder %UpdateVersion%%append%-u.bat")
	echo %icongray% i %formatend% Downloading information...
	set "updateFileName=batch_update.json"
	curl --silent -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version:2022-11-28" -o %updateFileName% https://api.github.com/repos/Adam-Kay/Batch-Encoder/releases/latest
	if not exist "%updateFileName%" (goto AutoUpdateError)
	
	>%TEMP%\batch_update.tmp findstr "tag_name" %updateFileName%
	<%TEMP%\batch_update.tmp set /p "ver_entry="
	set "ver=%ver_entry:~15,-2%"
	set "UpdateVersion=v%ver:~1%"
	
	set regex_command=powershell -Command "$x = Get-Content %updateFileName% -Raw; $k = $x | Select-String -Pattern '(?s)url(((?^^^!url).)*?)batch\.encoder'; $g = $k.Matches.Value | Select-String -Pattern '^""[^^^^"""]+?^""",'; $g.Matches.Value"
	
	FOR /F "tokens=*" %%g IN ('%regex_command%') do (SET API_link_entry=%%g)
	set "UpdateAPIURL=%API_link_entry:~1,-2%"

	for %%a in (ver_entry, API_link_entry, UpdateVersion, UpdateAPIURL) do if not defined %%a goto AutoUpdateError
	
	echo.
	echo %iconyellow% ^^! %formatend% Version found^^! ^(%textgreen%%UpdateVersion%^%formatend%)
	echo Proceeding with force update in 5 seconds; close window to cancel.
	echo.
	timeout /nobreak /t 5 > nul
	echo Downloading files...
	curl --silent -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%-u.bat" %UpdateAPIURL%
	echo.
	if not exist "batch encoder %UpdateVersion%-u.bat" (
		echo %iconred% ^^! %formatend% Download failed. & echo. & echo Attempting alternate download...
		curl --silent --ssl-no-revoke -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%-u.bat" %UpdateAPIURL%
		echo.
		if not exist "batch encoder %UpdateVersion%-u.bat" (
			echo %iconred% ^^! %formatend% Alternate download failed.
			goto AutoUpdateError
		)
	)
	move /Y "batch encoder %UpdateVersion%%append%-u.bat" "batch encoder %UpdateVersion%%append%.bat" > nul
	if "%par_silent%"=="true" (
		echo %icongreen% i %formatend% Download complete. The program will now clean up and exit.
	) else (
		echo %icongreen% i %formatend% Download complete. The program will now clean up and restart.
	)
	
	call:GrayPause
	if defined BEFile (
		if not "%BEFile%"=="batch encoder %UpdateVersion%.bat" (
			del "%BEFile%"
		)
	)
	del "%updateFileName%"
	if "%par_silent%"=="true" (
		(goto) 2>nul & del "%~f0"
	) else (
		(goto) 2>nul & "batch encoder %UpdateVersion%.bat" --updated-from "%~f0"
	)

:AutoUpdateError
	del "%updateFileName%"
	echo.
	echo.
	echo %textred%************************************************************%formatend%
	echo.
	echo There was a problem with the auto-updater. You can download the latest version of the program at: 
	echo https://github.com/Adam-Kay/Batch-Encoder/releases
	echo.
	echo The program will now exit.
	call:GrayPause
	exit
	
:GrayPause
	echo %textgray%
	if /i not "%par_silent%"=="true" (pause)
	echo %formatend%
	goto:eof