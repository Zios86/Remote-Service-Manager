@echo off
setlocal

rem PUSHD supports local folders, mapped drives and UNC network paths.
pushd "%~dp0" >nul 2>&1
if errorlevel 1 (
    echo Cannot open the program folder:
    echo %~dp0
    pause
    exit /b 1
)

call :verify_hash ".\Remote-Service-Manager.ps1" "f690bfba0b65c2ad7f0a2be816deaf585f743e563d205871a8cf0f6825ecf2a9"
if errorlevel 1 goto integrity_error
call :verify_hash ".\Linux-Remote.ps1" "3a8f56ed10da04950ca441c9e2fbd2360b5279bfa086265378b77e2353acb7a3"
if errorlevel 1 goto integrity_error
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File ".\Remote-Service-Manager.ps1"
set "APP_EXIT_CODE=%ERRORLEVEL%"

popd
if not "%APP_EXIT_CODE%"=="0" (
    echo.
    echo The program stopped with error code %APP_EXIT_CODE%.
    pause
)

exit /b %APP_EXIT_CODE%

:verify_hash
set "ACTUAL_HASH="
for /f "usebackq delims=" %%H in (`powershell.exe -NoLogo -NoProfile -Command "(Get-FileHash -LiteralPath '%~1' -Algorithm SHA256).Hash.ToLowerInvariant()"`) do set "ACTUAL_HASH=%%H"
if /I not "%ACTUAL_HASH%"=="%~2" exit /b 1
exit /b 0

:integrity_error
echo.
echo Integrity check failed. Program files were changed or damaged.
echo Download and extract a clean application package.
pause
popd
exit /b 2
