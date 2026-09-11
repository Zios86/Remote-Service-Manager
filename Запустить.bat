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

call :verify_hash ".\Remote-Service-Manager.ps1" "006b03bec7b8b6ec0d8b1171453704b5fc7bd83d41da088dd70b68dc41f3ce17"
if errorlevel 1 goto integrity_error
call :verify_hash ".\Linux-Remote.ps1" "fb7fab20401e3c608ed0e639ed6be616f8286ed62e2a4616a5fe265502582519"
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
