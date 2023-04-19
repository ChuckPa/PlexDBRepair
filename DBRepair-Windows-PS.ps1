# Script Info
cls
Write-Host "  PlexDBRepair.ps1 - Database maintenance / rebuild tool for Windows." -ForegroundColor Cyan
Write-Host ""
Write-Host "  This tool currently works as a 'full shot' service."
Write-Host "  - everything is done without need to interact."
Write-Host ""
Write-Host " -- WARNNING -- WARNING -- WARNING" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1. This is stable working software but not 'Released' software.  Development will continue."
Write-Host " 2. You must ensure variable PlexData points to your databases. (there is no automatic detection at this time)"
Write-Host ""

##################
# Variable Start #
##################

# Create Timestamp
$TimeStamp = Get-Date -Format 'hh-mm-ss'
$Date = Get-Date -Format 'dd.MM.yyyy'

# Query PMS default Locations
$InstallLocation = ((Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -ErrorAction SilentlyContinue | Get-ItemProperty -ErrorAction SilentlyContinue| Where-Object {$_.DisplayName -match 'Plex Media Server'})).InstallLocation
$PlexData = "$env:LOCALAPPDATA\Plex Media Server\Plug-in Support\Databases"
$PlexDBPath = "$PlexData\com.plexapp.plugins.library.db"
$PlexSQL = $InstallLocation +"Plex SQLite.exe"
$DBtmp = "$PlexData\dbtmp"
$TmpFile = "$DBtmp\results.tmp"

################
# Variable End #
################

function WriteOutput($output) {
    $log = $(Get-Date -Format 'hh:mm:ss tt')+' --  '+$output
    Write-Host $log
    Add-Content -Path "$PlexData\PlexDBRepair.log" -Value $log
}

if ($InstallLocation){
    Write-Host "Plex Media Server is installed..."
    Write-Host  "Testing DB Path now..." -ForegroundColor Cyan
    if (Test-Path $PlexDBPath){
        Write-Host "Found DB" -ForegroundColor Green
        $CanRun = $true
    }
}

# Script start

if ($CanRun){
    WriteOutput "====== Session begins. ($Date) ======"

    # Look for PMS exe and kill it
    $PMSexe = Get-Process "Plex Media Server" -ErrorAction SilentlyContinue
    if ($PMSexe){
        WriteOutput "ERROR: Plex is running.  Please stop Plex Media Server and try again."

        # Should i kill PMS for you?
        $question = "Should i kill it for you? (y/n)"
        $Answer = Read-Host $question

        if ($Answer -eq "y" -or $Answer -eq "Y"){
            WriteOutput "Killing PMS exe..."
            Stop-Process $PMSexe.id -Confirm:$false -Force
            sleep 5
        }
        Else {
            pause
            Exit 1
        }
    }
    WriteOutput "Plex is not running.  Starting now..."

    # Switching to PlexData dir
    Set-Location $PlexData

    # Creating Folder if not present
    if (!(Test-Path $DBtmp -ErrorAction SilentlyContinue)){
        New-Item -ItemType Directory "dbtmp"
    }
    # Deleteing tmp File if present
    if (Test-Path $TmpFile -ErrorAction SilentlyContinue){
        Remove-Item $TmpFile -Force -Confirm:$false
    }
    WriteOutput "Exporting Main DB"

    # Execute the command
    try {
        Write-Output ".dump" | & $PlexSQL "$PlexData\com.plexapp.plugins.library.db" | Out-File "$DBtmp\library.sql_$TimeStamp"
    }
    catch {
        WriteOutput "ERROR:  Cannot export Main DB.  Aborting."
        pause
        Exit 1
    }

    WriteOutput "Exporting Blobs DB"

    # Execute the command
    try {
        Write-Output ".dump" | & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db" | Out-File "$DBtmp\blobs.sql_$TimeStamp"
    }
    catch {
        WriteOutput "ERROR:  Cannot export Blobs DB.  Aborting."
        pause
        Exit 1
    }

    # Now create new databases from SQL statements
    WriteOutput "Exporting Complete..."
    WriteOutput "Creating Main DB..."

    # Execute the command
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PlexSQL
        $psi.Arguments = "`"$PlexData\com.plexapp.plugins.library.db_$TimeStamp`""
        $psi.RedirectStandardInput = $true
        $psi.UseShellExecute = $false

        $process = [System.Diagnostics.Process]::Start($psi)
        (Get-Content "$DBtmp\library.sql_$TimeStamp") | ForEach-Object { $process.StandardInput.WriteLine($_) }
        $process.StandardInput.Close()
        $process.WaitForExit()
    }
    catch {
        WriteOutput "ERROR:  Cannot create Main DB.  Aborting."
        pause
        Exit 1
    }

    # Now Verify created DB
    WriteOutput "Verifying Main DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "PRAGMA integrity_check(1)"| Out-File $TmpFile
    }
    catch {
        WriteOutput "ERROR: Main DB verificaion failed. Exiting."
        pause
        Exit 1
    }

    if ((Get-Content $TmpFile) -ne 'ok'){
        WriteOutput "ERROR: Main DB verificaion failed. Exiting."
        pause
        Exit 1
    }
    Else {
        WriteOutput "Main DB verification successful..."
    }

    WriteOutput "Creating Blobs DB..."

    # Execute the command
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PlexSQL
        $psi.Arguments = "`"$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp`""
        $psi.RedirectStandardInput = $true
        $psi.UseShellExecute = $false

        $process = [System.Diagnostics.Process]::Start($psi)
        (Get-Content "$DBtmp\blobs.sql_$TimeStamp") | ForEach-Object { $process.StandardInput.WriteLine($_) }
        $process.StandardInput.Close()
        $process.WaitForExit()
    }
    catch {
        WriteOutput "ERROR: Cannot create Blobs DB.  Aborting."
        pause
        Exit 1
    }

    # Now Verify created Blobs DB
    WriteOutput "Verifying Blobs DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "PRAGMA integrity_check(1)"| Out-File $TmpFile
    }
    catch {
        WriteOutput "ERROR: Blobs DB verificaion failed. Exiting."
        pause
        Exit 1
    }
    if ((Get-Content $TmpFile) -ne 'ok'){
        WriteOutput "ERROR: Blobs DB verificaion failed. Exiting."
        pause
        Exit 1
    }
    Else {
        WriteOutput "Blobs DB verification successful..."
        WriteOutput "Import and verification complete..."
    }

    WriteOutput "Reindexing Main DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "REINDEX;"
    }
    catch {
        WriteOutput "ERROR: Main DB Reindex failed. Exiting."
        pause
        Exit 1
    }

    WriteOutput "Reindexing Blobs DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "REINDEX;"
    }
    catch {
        WriteOutput "ERROR: Blobs DB Reindex failed. Exiting."
        pause
        Exit 1
    }

    WriteOutput "Reindexing complete..."
    WriteOutput "Moving current DBs to DBTMP and making new databases active..."

    # Moving files

    Move-Item "$PlexData\com.plexapp.plugins.library.db" "$DBtmp\com.plexapp.plugins.library.db_$TimeStamp" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Move-Item "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "$PlexData\com.plexapp.plugins.library.db"-Force -Confirm:$false -ErrorAction SilentlyContinue

    Move-Item "$PlexData\com.plexapp.plugins.library.blobs.db" "$DBtmp\com.plexapp.plugins.library.blobs.db_$TimeStamp" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Move-Item "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "$PlexData\com.plexapp.plugins.library.blobs.db" -Force -Confirm:$false -ErrorAction SilentlyContinue

    WriteOutput "Database repair/rebuild/reindex completed..."
    WriteOutput "Starting Plex Media Server now..."
    Start-Process "$InstallLocation\Plex Media Server.exe" -InformationAction SilentlyContinue
    WriteOutput "====== Session completed. ======"
    Pause
    Exit
}
Else {
    Write-Host "Could not locate DB, maybe you have to modify Variables at top of the Script..." -ForegroundColor Red
}