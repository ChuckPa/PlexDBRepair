@echo off
REM  DBRepair.bat - Database maintenance / rebuild tool for Windows.
REM
REM  This tool currently works as a "full shot" service.
REM  - everything is done without need to interact.
REM
REM -- WARNNING -- WARNING -- WARNING
REM
REM This is stable working software but not "Released" software.  Development will continue.

setlocal enabledelayedexpansion

echo.
echo NOTE: This script is being replaced with the PowerShell script DBRepair-Windows.ps1,
echo       which aims to better emulate DBRepair.sh (more options, interactive mode, etc).
echo       Consider moving over to the new script.
echo.

REM ### Create Timestamp
set Hour=%time:~0,2%
set Min=%time:~3,2%
set Sec=%time:~6,2%

REM ## Remove spaces from Hour ##
set Hour=%Hour: =%

REM ## Set TimeStamp ##
set TimeStamp=%Hour%-%Min%-%Sec%

REM Find PMS database location
for /F "tokens=2* skip=2" %%a in ('REG.EXE QUERY "HKCU\Software\Plex, Inc.\Plex Media Server" /v "LocalAppDataPath" 2^> nul') do set "PlexData=%%b\Plex Media Server\Plug-in Support\Databases"
if not exist "%PlexData%" (
  if exist "%LOCALAPPDATA%\Plex Media Server\Plug-in Support\Databases" (
    set "PlexData=%LOCALAPPDATA%\Plex Media Server\Plug-in Support\Databases"
  ) else (
    echo Could not determine Plex database path.
    echo Normally %LOCALAPPDATA%\Plex Media Server\Plug-in Support\Databases
    echo.
    goto :EOF
  )
)

REM Find PMS installation location.
for /F "tokens=2* skip=2" %%a in ('REG.EXE QUERY "HKCU\Software\Plex, Inc.\Plex Media Server" /v "InstallFolder" 2^> nul') do set "PlexSQL=%%b\Plex SQLite.exe"

if not exist "%PlexSQL%" (
  REM InstallFolder might be set under HKLM, not HKCU
  for /F "tokens=2* skip=2" %%a in ('REG.EXE QUERY "HKLM\Software\Plex, Inc.\Plex Media Server" /v "InstallFolder" 2^> nul') do set "PlexSQL=%%b\Plex SQLite.exe"
)

REM If InstallFolder wasn't set, or the resulting file doesn't exist, iterate through the
REM PROGRAMFILES variables looking for it. If we still can't find it, ask the user to provide it.
if not exist "%PlexSQL%" (
  if exist "%PROGRAMFILES%\Plex\Plex Media Server\Plex SQLite.exe" (
    set "PlexSQL=%PROGRAMFILES%\Plex\Plex Media Server\Plex SQLite.exe"
  ) else (
    if exist "%PROGRAMFILES(X86)%\Plex\Plex Media Server\Plex SQLite.exe" (
      echo NOTE: 32-bit version of PMS detected on a 64-bit version of Windows. Updating to the 64-bit release of PMS is recommended.
      set "PlexSQL=%PROGRAMFILES(X86)%\Plex\Plex Media Server\Plex SQLite.exe"
    ) else (
      echo Could not determine SQLite path. Please provide it below
      echo Normally %PROGRAMFILES%\Plex\Plex Media Server\Plex SQLite.exe
      echo.
      REM Last ditch effort, ask the user for the full path to Plex SQLite.exe
      set /p "PlexSQL=Path to Plex SQLite.exe: "
      if not exist "!PlexSQL!" (
        echo "!PlexSQL!" could not be found. Cannot continue.
        goto :EOF
      )
    )
  )
)

REM Set temporary file locations
set "DBtmp=%PlexData%\dbtmp"
set "TmpFile=%DBtmp%\results.tmp"


REM Time now.
echo %time% --  ====== Session begins. (%date%) ======
echo %time% --  ====== Session begins. (%date%) ====== >> "%PlexData%\DBRepair.log"

REM Make certain Plex is NOT running.
tasklist | find /I "Plex Media Server.exe" >NUL
if %ERRORLEVEL%==0 (
  echo %time% --  Plex is running.  Please stop Plex Media Server and try again.
  echo %time% --  Plex is running.  Please stop Plex Media Server and try again. >> "%PlexData%\DBRepair.log"
  exit /B 1
)


cd "%PlexData%"

md "%PlexData%\dbtmp" 2>NUL
del "%TmpFile%"  2>NUL

echo %time% -- Performing DB cleanup tasks
echo %time% -- Performing DB cleanup tasks >> "%PlexData%\DBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db" "DELETE FROM statistics_bandwidth WHERE account_id IS NULL;"

echo %time% --  Exporting Main DB
echo %time% --  Exporting Main DB >> "%PlexData%\DBRepair.log"
echo .dump | "%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db"  > "%DBtmp%\library.sql_%TimeStamp%"
if not %ERRORLEVEL%==0 (
  echo %time% -- ERROR:  Cannot export Main DB.  Aborting.
  exit /b 2
)

echo %time% --  Exporting Blobs DB
echo %time% --  Exporting Blobs DB >> "%PlexData%\DBRepair.log"
echo .dump | "%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.blobs.db" > "%DBtmp%\blobs.sql_%TimeStamp%"
if not %ERRORLEVEL%==0 (
  echo %time% -- ERROR:  Cannot export Blobs DB.  Aborting.
)

REM Now create new databases from SQL statements
echo %time% --  Exporting Complete.
echo %time% --  Exporting Complete. >> "%PlexData%\DBRepair.log"

echo %time% --  Creating Main DB
echo %time% --  Creating Main DB >> "%PlexData%\DBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db_%TimeStamp%"       < "%DBtmp%\library.sql_%TimeStamp%"
if not %ERRORLEVEL%==0 (
  echo %time% --  ERROR:  Cannot create Main DB.  Aborting.
  echo %time% --  ERROR:  Cannot create Main DB.  Aborting. >> "%PlexData%\DBRepair.log"
  exit /b 3
)

echo %time% --  Verifying Main DB
echo %time% --  Verifying Main DB >> "%PlexData%\DBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db_%TimeStamp%" "PRAGMA integrity_check(1)"  >"%TmpFile%"
set /p Result= < "%TmpFile%"
del "%TmpFile%"

echo %time% --  Main DB verification check is: %Result%
echo %time% --  Main DB verification check is: %Result% >> "%PlexData%\DBRepair.log"
if not "%Result%" == "ok" (
  echo %time% --  ERROR: Main DB verification failed. Exiting.
  echo %time% --  ERROR: Main DB verification failed. Exiting. >> "%PlexData%\DBRepair.log"
  exit /B 4
)
echo %time% --  Main DB verification successful.
echo %time% --  Main DB verification successful. >> "%PlexData%\DBRepair.log"


echo %time% --  Creating Blobs DB
echo %time% --  Creating Blobs DB >> "%PlexData%\DBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.blobs.db_%TimeStamp%" < "%DBtmp%\blobs.sql_%TimeStamp%"
if not %ERRORLEVEL%==0 (
  echo %time% --  ERROR: Cannot create Blobs DB.  Aborting.
  echo %time% --  ERROR: Cannot create Blobs DB.  Aborting. >> "%PlexData%\DBRepair.log"
  exit /b 5
)

echo %time% --  Verifying Blobs DB
echo %time% --  Verifying Blobs DB >> "%PlexData%\DBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.blobs.db_%TimeStamp%" "PRAGMA integrity_check(1)" > "%TmpFile%"
set /p Result= < "%TmpFile%"
del "%TmpFile%"

echo %time% --  Blobs DB verification check is: %Result%
echo %time% --  Blobs DB verification check is: %Result% >> "%PlexData%\DBRepair.log"
if not "%Result%" == "ok" (
  echo %time% -- ERROR: Blobs DB verification failed. Exiting.
  echo %time% -- ERROR: Blobs DB verification failed. Exiting. >> "%PlexData%\DBRepair.log"
  exit /B 6
)
echo %time% --  Blobs DB verification successful.
echo %time% --  Blobs DB verification successful. >> "%PlexData%\DBRepair.log"
echo %time% --  Import and verification complete.
echo %time% --  Import and verification complete. >> "%PlexData%\DBRepair.log"

REM Import complete, now reindex
echo %time% --  Reindexing Main DB
echo %time% --  Reindexing Main DB >> "%PlexData%\DBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db_%TimeStamp%"       "REINDEX;"

echo %time% --  Reindexing Blobs DB
echo %time% --  Reindexing Blobs DB >> "%PlexData%\DBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.blobs.db_%TimeStamp%" "REINDEX;"

REM Index complete, make active
echo %time% --  Reindexing complete.
echo %time% --  Reindexing complete. >> "%PlexData%\DBRepair.log"
echo %time% --  Moving current DBs to DBTMP and making new databases active
echo %time% --  Moving current DBs to DBTMP and making new databases active >> "%PlexData%\DBRepair.log"

move "%PlexData%\com.plexapp.plugins.library.db"             "%PlexData%\dbtmp\com.plexapp.plugins.library.db_%TimeStamp%"
move "%PlexData%\com.plexapp.plugins.library.db_%TimeStamp%" "%PlexData%\com.plexapp.plugins.library.db"

move "%PlexData%\com.plexapp.plugins.library.blobs.db"             "%PlexData%\dbtmp\com.plexapp.plugins.library.blobs.db_%TimeStamp%"
move "%PlexData%\com.plexapp.plugins.library.blobs.db_%TimeStamp%" "%PlexData%\com.plexapp.plugins.library.blobs.db"

echo %time% --  Database repair/rebuild/reindex completed.
echo %time% --  Database repair/rebuild/reindex completed. >> "%PlexData%\DBRepair.log"
echo %time% --  ====== Session completed. ======
echo %time% --  ====== Session completed. ====== >> "%PlexData%\DBRepair.log"

exit /b


REM #### Functions

REM Output -  Write text to the console and the log file
:Output

echo %time% %~1
echo %time% %~1 >> "%PlexData%\DBRepair.log"
exit /B
