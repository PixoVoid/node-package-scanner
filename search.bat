@echo off
REM =============================================================
REM node-package-scanner
REM Copyright (c) 2025 PixoVoid (https://PixoVoid.dev)
REM For private use only. Use at your own risk.
REM No warranty or guarantee of correctness. The author accepts no liability.
REM CSV source: https://www.koi.ai/incident/live-updates-sha1-hulud-the-second-coming-hundred-npm-packages-compromised (25.11.2025, 13:00 CET)
REM =============================================================
setlocal enabledelayedexpansion

REM === CONFIGURATION ===
set "CSV_FILE=packages.csv"
set "OUTPUT_FILE=found_packages.txt"
set "ROOTS_FILE=roots.txt"

REM Default search locations
set "DEFAULT_ROOTS=%USERPROFILE%\Desktop;%USERPROFILE%\Documents;%USERPROFILE%\Herd;%USERPROFILE%\OneDrive;%APPDATA%\npm\node_modules;%LOCALAPPDATA%\Yarn\Data\global\node_modules;C:\Program Files\nodejs\node_modules"

REM Support command-line args
if not "%~1"=="" set "CSV_FILE=%~1"
if not "%~2"=="" set "OUTPUT_FILE=%~2"
if not "%~3"=="" set "ROOTS_FILE=%~3"

REM Check CSV
if not exist "%CSV_FILE%" (
    echo ERROR: CSV file "%CSV_FILE%" not found!
    pause
    exit /b 1
)

REM Prepare output
echo Search started at %date% %time% > "%OUTPUT_FILE%"
echo CSV source: %CSV_FILE% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo Scanned roots: >> "%OUTPUT_FILE%"

REM Load roots
set "ROOT_COUNT=0"
if exist "%ROOTS_FILE%" (
    for /f "usebackq tokens=* delims=" %%r in ("%ROOTS_FILE%") do (
        set "LINE=%%r"
        for /f "tokens=*" %%t in ("!LINE!") do set "LINE=%%t"
        if not "!LINE!"=="" (
            if not "!LINE:~0,1!"=="#" (
                set /a ROOT_COUNT+=1
                set "ROOT!ROOT_COUNT!=!LINE!"
                echo    !LINE! >> "%OUTPUT_FILE%"
            )
        )
    )
) else (
    REM Corrected processing so that paths with spaces are not split
    for %%x in ("%DEFAULT_ROOTS:;=";"%") do (
        set "item=%%~x"
        set "item=!item:"=!"
        set /a ROOT_COUNT+=1
        set "ROOT!ROOT_COUNT!=!item!"
        echo    !item! >> "%OUTPUT_FILE%"
    )
)

if !ROOT_COUNT!==0 (
    echo ERROR: No search roots configured!
    pause
    exit /b 1
)

echo ================================================== >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

echo ================================================
echo Step 1: Finding all node_modules folders...
echo ================================================
echo.

REM Find all node_modules
set "TEMP_NM=%TEMP%\nm_paths_%RANDOM%.txt"
if exist "%TEMP_NM%" del "%TEMP_NM%"

for /l %%i in (1,1,!ROOT_COUNT!) do (
    set "ROOT=!ROOT%%i!"
    if exist "!ROOT!" (
        echo Searching in: !ROOT!
        dir /s /b /ad "!ROOT!\node_modules" 2>nul >> "%TEMP_NM%"
    )
)

set "nm_count=0"
if exist "%TEMP_NM%" (
    for /f %%a in ('type "%TEMP_NM%" 2^>nul ^| find /c /v ""') do set "nm_count=%%a"
)

echo.
echo Found: !nm_count! node_modules folders
echo.
echo ================================================
echo Step 2: Searching packages...
echo ================================================
echo.

set "found_count=0"
set "total_count=0"
set "critical_count=0"

REM Read CSV
set "skip_header=1"
for /f "usebackq tokens=1,2 delims=," %%a in ("%CSV_FILE%") do (
    if !skip_header!==1 (
        set "skip_header=0"
    ) else (
        set /a total_count+=1
        set "package=%%a"
        set "version=%%b"
        
        REM Clean
        set "package=!package: =!"
        set "package=!package:"=!"
        set "version=!version: =!"
        set "version=!version:"=!"
        
        REM Replace / with \
        set "searchPackage=!package:/=\!"
        
        echo [!total_count!] Searching: !package! ^(v!version!^)
        
        set "found_this=0"
        if exist "%TEMP_NM%" (
            for /f "usebackq delims=" %%n in ("%TEMP_NM%") do (
                set "pkgPath=%%n\!searchPackage!"
                if exist "!pkgPath!" (
                    REM Read version
                    set "pkgFile=!pkgPath!\package.json"
                    set "pkgVer=unknown"
                    if exist "!pkgFile!" (
                        for /f "usebackq tokens=2 delims=:, " %%v in (`findstr /i "\"version\"" "!pkgFile!" 2^>nul`) do (
                            set "pkgVer=%%~v"
                        )
                    )
                    
                    REM First occurrence
                    if !found_this!==0 (
                        if "!pkgVer!"=="!version!" (
                            echo [CRITICAL] !package! ^(!pkgVer!^) >> "%OUTPUT_FILE%"
                            echo    Path: !pkgPath! >> "%OUTPUT_FILE%"
                            echo    Status: VERSION MATCHES COMPROMISED VERSION! >> "%OUTPUT_FILE%"
                            echo    --^> CRITICAL: !package! ^(!pkgVer!^) at !pkgPath!
                            set /a critical_count+=1
                        ) else (
                            if "!pkgVer!"=="unknown" (
                                echo [INFO] !package! ^(no version info^) >> "%OUTPUT_FILE%"
                                echo    Path: !pkgPath! >> "%OUTPUT_FILE%"
                            ) else (
                                echo [WARNING] !package! ^(found: !pkgVer! / compromised: !version!^) >> "%OUTPUT_FILE%"
                                echo    Path: !pkgPath! >> "%OUTPUT_FILE%"
                            )
                        )
                        set "found_this=1"
                    ) else (
                        REM Additional location
                        echo    Path: !pkgPath! >> "%OUTPUT_FILE%"
                    )
                )
            )
        )
        
        if !found_this!==1 (
            set /a found_count+=1
            echo. >> "%OUTPUT_FILE%"
        )
    )
)

REM Cleanup
if exist "%TEMP_NM%" del "%TEMP_NM%"

REM Summary
echo. >> "%OUTPUT_FILE%"
echo ================================================== >> "%OUTPUT_FILE%"
echo SUMMARY >> "%OUTPUT_FILE%"
echo ================================================== >> "%OUTPUT_FILE%"
echo Searched packages: !total_count! >> "%OUTPUT_FILE%"
echo Packages found: !found_count! >> "%OUTPUT_FILE%"
echo CRITICAL matches: !critical_count! >> "%OUTPUT_FILE%"
echo node_modules scanned: !nm_count! >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo Search finished at %date% %time% >> "%OUTPUT_FILE%"

echo.
echo ================================================
echo SEARCH COMPLETED
echo ================================================
echo Searched packages: !total_count!
echo Packages found: !found_count!
echo CRITICAL matches: !critical_count!
echo node_modules scanned: !nm_count!
echo.
echo Results: %OUTPUT_FILE%
echo ================================================
echo.

if !critical_count! gtr 0 (
    echo.
    echo *** WARNING ***
    echo Found !critical_count! package^(s^) with exact compromised version!
    echo Please review %OUTPUT_FILE% immediately!
    echo.
)

pause