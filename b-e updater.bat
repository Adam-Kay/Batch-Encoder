:AskProceed
	cls
	SET /P "CONFIRMATION=This program will attempt to forcibly update the batch encoder script. Do you want to proceed? [Y/N] : "
	IF /i "%CONFIRMATION%"=="n" exit
	IF /i "%CONFIRMATION%"=="y" (goto Update)
	goto AskProceed
	
:Update
	echo Downloading information...
	curl --silent -o batch_update.txt https://gist.githubusercontent.com/Adam-Kay/ec5da0ff40e8eb14beee2242161f5191/raw
	for /f "tokens=1,2,3 delims=|" %%A in (batch_update.txt) do (
		set UpdateVersion=%%A
		set UpdateAPIURL=%%B
		set UpdateBrowserURL=%%C
	)

	rem Test if any of them are blank
	for %%a in (UpdateVersion, UpdateAPIURL, UpdateBrowserURL) do if not defined %%a goto AutoUpdateError


	echo Version found^^! ^(%UpdateVersion%^)
	echo Proceeding with force update in 5 seconds, press CTRL+C or close window to cancel.
	echo.
	timeout /nobreak /t 5 > nul
	echo Downloading files...
	curl --silent -L -H "Accept: application/octet-stream" -o "batch encoder %UpdateVersion%.bat" %UpdateAPIURL%
	echo.
	echo Download complete. The program will now clean up and restart.
	pause
	
	del "batch_update.txt"
	(goto) 2>nul & "batch encoder %UpdateVersion%.bat" --updated-from "%~f0"
	
:AutoUpdateError
	echo.
	echo There was a problem with the auto-updater. Exiting...
	echo.
	pause
	exit