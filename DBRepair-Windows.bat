@echo off
REM  PlexDBRepair.bat - Database maintenance / rebuild tool for Windows.
REM
REM  This tool currently works as a "full shot" service.
REM  - everything is done without need to interact.
REM
REM -- WARNNING -- WARNING -- WARNING
REM
REM 1. This is stable working software but not "Released" software.  Development will continue.
REM 2. You must ensure variable PlexData points to your databases. (there is no automatic detection at this time)
REM
REM ### Create Timestamp
set Hour=%time:~0,2%
set Min=%time:~3,2%
set Sec=%time:~6,2%

REM ## Remove spaces from Hour ##
set Hour=%Hour: =%

REM ## Set TimeStamp ##
set TimeStamp=%Hour%-%Min%-%Sec%

REM These assume PMS is in the default location
set "PlexData=%LOCALAPPDATA%\Plex Media Server\Plug-in Support\Databases"
set "PlexSQL=%PROGRAMFILES%\Plex\Plex Media Server\Plex SQLite"
set "DBtmp=%PlexData%\dbtmp"
set "TmpFile=%DBtmp%\results.tmp"


REM Time now.
echo %time% --  ====== Session begins. (%date%) ======
echo %time% --  ====== Session begins. (%date%) ====== >> "%PlexData%\PlexDBRepair.log"

REM Make certain Plex is NOT running.
tasklist | find /I "Plex Media Server.exe" >NUL
if %ERRORLEVEL%==0 (
  echo %time% --  Plex is running.  Please stop Plex Media Server and try again.
  echo %time% --  Plex is running.  Please stop Plex Media Server and try again. >> "%PlexData%\PlexDBRepair.log"
  exit /B 1
)


cd "%PlexData%"

mkdir "%PlexData%\dbtmp" 2>NUL
del "%TmpFile%"  2>NUL

echo %time% --  Exporting Main DB
echo %time% --  Exporting Main DB >> "%PlexData%\PlexDBRepair.log"
echo .dump | "%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db"  > "%DBtmp%\library.sql_%TimeStamp%"
if not %ERRORLEVEL%==0 (
  echo %time% -- ERROR:  Cannot export Main DB.  Aborting.
  exit /b 2
)

echo %time% --  Exporting Blobs DB
echo %time% --  Exporting Blobs DB >> "%PlexData%\PlexDBRepair.log"
echo .dump | "%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.blobs.db" > "%DBtmp%\blobs.sql_%TimeStamp%"
if not %ERRORLEVEL%==0 (
  echo %time% -- ERROR:  Cannot export Blobs DB.  Aborting.
)

REM Now create new databases from SQL statements
echo %time% --  Exporting Complete.
echo %time% --  Exporting Complete. >> "%PlexData%\PlexDBRepair.log"

echo %time% --  Creating Main DB
echo %time% --  Creating Main DB >> "%PlexData%\PlexDBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db_%TimeStamp%"       < "%DBtmp%\library.sql_%TimeStamp%"
if not %ERRORLEVEL%==0 (
  echo %time% --  ERROR:  Cannot create Main DB.  Aborting.
  echo %time% --  ERROR:  Cannot create Main DB.  Aborting. >> "%PlexData%\PlexDBRepair.log"
  exit /b 3
)

echo %time% --  Verifying Main DB
echo %time% --  Verifying Main DB >> "%PlexData%\PlexDBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db_%TimeStamp%" "PRAGMA integrity_check(1)"  >"%TmpFile%"
set /p Result= < "%TmpFile%"
del "%TmpFile%"

echo %time% --  Main DB verification check is: %Result%
echo %time% --  Main DB verification check is: %Result% >> "%PlexData%\PlexDBRepair.log"
if not "%Result%" == "ok" (
  echo %time% --  ERROR: Main DB verificaion failed. Exiting.
  echo %time% --  ERROR: Main DB verificaion failed. Exiting. >> "%PlexData%\PlexDBRepair.log"
  exit /B 4
)
echo %time% --  Main DB verification successful.
echo %time% --  Main DB verification successful. >> "%PlexData%\PlexDBRepair.log"


echo %time% --  Creating Blobs DB
echo %time% --  Creating Blobs DB >> "%PlexData%\PlexDBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.blobs.db_%TimeStamp%" < "%DBtmp%\blobs.sql_%TimeStamp%"
if not %ERRORLEVEL%==0 (
  echo %time% --  ERROR: Cannot create Blobs DB.  Aborting.
  echo %time% --  ERROR: Cannot create Blobs DB.  Aborting. >> "%PlexData%\PlexDBRepair.log"
  exit /b 5
)

echo %time% --  Verifying Blobs DB
echo %time% --  Verifying Blobs DB >> "%PlexData%\PlexDBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.blobs.db_%TimeStamp%" "PRAGMA integrity_check(1)" > "%TmpFile%"
set /p Result= < "%TmpFile%"
del "%TmpFile%"

echo %time% --  Blobs DB verification check is: %Result%
echo %time% --  Blobs DB verification check is: %Result% >> "%PlexData%\PlexDBRepair.log"
if not "%Result%" == "ok" (
  echo %time% -- ERROR: Blobs DB verificaion failed. Exiting.
  echo %time% -- ERROR: Blobs DB verificaion failed. Exiting. >> "%PlexData%\PlexDBRepair.log"
  exit /B 6
)
echo %time% --  Blobs DB verification successful.
echo %time% --  Blobs DB verification successful. >> "%PlexData%\PlexDBRepair.log"
echo %time% --  Import and verification complete.
echo %time% --  Import and verification complete. >> "%PlexData%\PlexDBRepair.log"

REM Import complete, now reindex
echo %time% --  Reindexing Main DB
echo %time% --  Reindexing Main DB >> "%PlexData%\PlexDBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.db_%TimeStamp%"       "REINDEX;"

echo %time% --  Reindexing Blobs DB
echo %time% --  Reindexing Blobs DB >> "%PlexData%\PlexDBRepair.log"
"%PlexSQL%" "%PlexData%\com.plexapp.plugins.library.blobs.db_%TimeStamp%" "REINDEX;"

REM Index complete, make active
echo %time% --  Reindexing complete.
echo %time% --  Reindexing complete. >> "%PlexData%\PlexDBRepair.log"
echo %time% --  Moving current DBs to DBTMP and making new databases active
echo %time% --  Moving current DBs to DBTMP and making new databases active >> "%PlexData%\PlexDBRepair.log"

move "%PlexData%\com.plexapp.plugins.library.db"             "%PlexData%\dbtmp\com.plexapp.plugins.library.db_%TimeStamp%"
move "%PlexData%\com.plexapp.plugins.library.db_%TimeStamp%" "%PlexData%\com.plexapp.plugins.library.db"

move "%PlexData%\com.plexapp.plugins.library.blobs.db"             "%PlexData%\dbtmp\com.plexapp.plugins.library.blobs.db_%TimeStamp%"
move "%PlexData%\com.plexapp.plugins.library.blobs.db_%TimeStamp%" "%PlexData%\com.plexapp.plugins.library.blobs.db"

echo %time% --  Database repair/rebuild/reindex completed.
echo %time% --  Database repair/rebuild/reindex completed. >> "%PlexData%\PlexDBRepair.log"
echo %time% --  ====== Session completed. ======
echo %time% --  ====== Session completed. ====== >> "%PlexData%\PlexDBRepair.log"

exit /b


REM #### Functions

REM Output -  Write text to the console and the log file
:Output

echo %time% %~1
echo %time% %~1 >> "%PlexData%\PlexDBRepair.log"
exit /B
