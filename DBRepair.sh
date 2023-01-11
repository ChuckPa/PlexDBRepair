#!/bin/sh
#########################################################################
# Plex Media Server database check and repair utility script.           #
# Maintainer: ChuckPa                                                   #
#########################################################################

# Flag when temp files are to be retained
Retain=0

# Have the databases passed integrity checks
CheckedDB=0

# Universal output function
Output() {
  echo "$@"
  $LOG_TOOL "$@"
}

# Write to Repair Tool log
WriteLog() {

  # Write given message into tool log file with TimeStamp
  echo "$(date "+%Y-%m-%d %H.%M.%S") - $*" >> "$LOGFILE"
  return 0
}

# Check given database file integrity
CheckDB() {

  # Confirm the DB exists
  [ ! -f "$1" ] && Output "ERROR: $1 does not exist." && return 1

  # Now check database for corruption
  Result="$("$PLEX_SQLITE" "$1" "PRAGMA integrity_check(1)")"
  if [ "$Result" = "ok" ]; then
    return 0
  else
     SQLerror="$(echo $Result | sed -e 's/.*code //')"
    return 1
  fi

}

# Check all databases
CheckDatabases() {

  # Arg1 = calling function
  # Arg2 = 'force' if present

  # Check each of the databases.   If all pass, set the 'CheckedDB' flag
  # Only force recheck if flag given

  # Check if not checked or forced
  NeedCheck=0
  [ $CheckedDB -eq 0 ] &&  NeedCheck=1
  [ $CheckedDB -eq 1 ] && [ "$2" = "force" ] && NeedCheck=1

  # Do we need to check
  if [ $NeedCheck -eq 1 ]; then

    # Clear Damaged flag
    Damaged=0
    CheckedDB=0

    # Info
    Output "Checking the PMS databases"

    # Check main DB
    if CheckDB $CPPL.db ; then
      Output "Check complete.  PMS main database is OK."
      WriteLog "$1"" - Check $CPPL.db - PASS"
    else
      Output "Check complete.  PMS main database is damaged."
      WriteLog "$1"" - Check $CPPL.db - FAIL ($SQLerror)"
      Damaged=1
    fi

    # Check blobs DB
    if CheckDB $CPPL.blobs.db ; then
      Output "Check complete.  PMS blobs database is OK."
      WriteLog "$1"" - Check $CPPL.blobs.db - PASS"
    else
      Output "Check complete.  PMS blobs database is damaged."
      WriteLog "$1"" - Check $CPPL.blobs.db - FAIL ($SQLerror)"
      Damaged=1
    fi
  fi

  [ $Damaged -eq 0 ] && CheckedDB=1

  # return status
  return $Damaged
}

# Return list of database backup dates for consideration in replace action
GetDates(){

  Dates=""
  Tempfile="/tmp/DBRepairTool.$$.tmp"
  touch "$Tempfile"

  for i in $(find . -name 'com.plexapp.plugins.library.db-????-??-??' | sort -r)
  do
    # echo Date - "${i//[^.]*db-/}"
    Date="$(echo $i | sed -e 's/.*.db-//')"

    # Only add if companion blobs DB exists
    [ -e $CPPL.blobs.db-$Date ] && echo $Date >> "$Tempfile"

  done

  # Reload dates in sorted order
  Dates="$(sort -r <$Tempfile)"

  # Remove tempfile
  rm -f "$Tempfile"

  # Give results
  echo $Dates
  return
}

# Non-fatal SQLite error code check
SQLiteOK() {

  # Global error variable
  SQLerror=0

  # Quick exit- known OK
  [ $1 -eq 0 ] && return 0

  # Put list of acceptable error codes here
  Codes="19 28"

  # By default assume the given code is an error
  CodeError=1

  for i in $Codes
  do
    if [ $i -eq $1 ]; then
      CodeError=0
      SQLerror=$i
      break
    fi
  done
  return $CodeError
}

# Perform the actual copying for MakeBackup()
DoBackup() {

  if [ -e $2 ]; then
    cp -p "$2" "$3"
    Result=$?
    if [ $Result -ne 0 ]; then
      Output "Error $Result while backing up '$2'.  Cannot continue."
      WriteLog "$1 - MakeBackup $2 - FAIL"

      # Remove partial copied file and return
      rm -f "$3"
      return 1
    else
      WriteLog "$1 - MakeBackup $2 - PASS"
      return 0
    fi
  fi
}

# Make a backup of the current database files and tag with TimeStamp
MakeBackups() {

  Output "Backup current databases with '-ORIG-$TimeStamp' timestamp."

  for i in "db" "db-wal" "db-shm" "blobs.db" "blobs.db-wal" "blobs.db-shm"
  do
    DoBackup "$1" "${CPPL}.${i}" "$DBTMP/${CPPL}.${i}-ORIG-$TimeStamp"
    Result=$?
  done

  return $Result

}

ConfirmYesNo() {

  Answer=""
  while [ "$Answer" = "" ]
  do
    printf "$1 (Y/N) ? "
    read Input

    # EOF = No
    [ "$Input" = ""  ] && Answer=N ; [ "$Input" = "n" ] && Answer=N ; [ "$Input" = "N" ] && Answer=N
    [ "$Input" = "y" ] && Answer=Y ; [ "$Input" = "Y" ] && Answer=Y

    # Unrecognized
    if [ "$Answer" != "Y" ] && [ "$Answer" != "N" ]; then
      echo "$Input" was not a valid reply.  Please try again.
      continue
    fi
  done

  # If no, done.
  if [ "$Answer" = "N" ]; then
    return 1
  fi

  # User said Yes.  Be 100% certain
  Answer=""
  while [ "$Answer" = "" ]
  do
    printf "Are you sure (Y/N) ? "
    read Input

    # EOF = No
    [ "$Input" = ""  ] && Answer=N ; [ "$Input" = "n" ] && Answer=N ; [ "$Input" = "N" ] && Answer=N
    [ "$Input" = "y" ] && Answer=Y ; [ "$Input" = "Y" ] && Answer=Y

    # Unrecognized
    if [ "$Answer" != "Y" ] && [ "$Answer" != "N" ]; then
      echo "$Input" was not a valid reply.  Please try again.
      continue
    fi
  done

  if [ "$Answer" = "Y" ]; then
    # Confirmed Yes
    return 0
  else
    return 1
  fi
}

# Restore previously saved DB from given TimeStamp
RestoreSaved() {

  T="$1"

  for i in "db" "db-wal" "db-shm" "blobs.db" "blobs.db-wal" "blobs.db-shm"
  do
    [ -e "${CPPL}.${i}" ] && rm -f "${CPPL}.${i}"
    [ -e "$DBTMP/${CPPL}.${i}-ORIG-$T" ] && mv "$DBTMP/${CPPL}.${i}-ORIG-$T" "${CPPL}.${i}"
  done
}

# Get the size of the given DB in MB
GetSize() {

  Size=$(stat $STATFMT $STATBYTES "$1")
  Size=$(expr $Size / 1048576)
  [ $Size -eq 0 ] && Size=1
  echo $Size
}

# Determine which host we are running on and set variables
HostConfig() {

  # On all hosts except Mac
  PIDOF="pidof"
  STATFMT="-c"
  STATBYTES="%s"

  # Synology (DSM 7)
  if [ -d /var/packages/PlexMediaServer ] && \
     [ -d "/var/packages/PlexMediaServer/shares/PlexMediaServer/AppData/Plex Media Server" ]; then

    # Where is the software
    PKGDIR="/var/packages/PlexMediaServer/target"
    PLEX_SQLITE="$PKGDIR/Plex SQLite"
    LOG_TOOL="logger"

    # Where is the data
    AppSuppDir="/var/packages/PlexMediaServer/shares/PlexMediaServer/AppData"
    DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
    PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
    LOGFILE="$DBDIR/DBRepair.log"

    # We are done
    HostType="Synology (DSM 7)"
    return 0

  # Synology (DSM 6)
  elif [ -d "/var/packages/Plex Media Server" ] && \
       [ -f "/usr/syno/sbin/synoshare" ]; then

    # Where is the software
    PKGDIR="/var/packages/Plex Media Server/target"
    PLEX_SQLITE="$PKGDIR/Plex SQLite"
    LOG_TOOL="logger"

    # Get shared folder path
    AppSuppDir="$(synoshare --get Plex | grep Path | awk -F\[ '{print $2}' | awk -F\] '{print $1}')"

    # Where is the data
    AppSuppDir="$AppSuppDir/Library/Application Support"
    if [ -d "$AppSuppDir/Plex Media Server" ]; then

      DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
      PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
      LOGFILE="$DBDIR/DBRepair.log"

      HostType="Synology (DSM 6)"
      return 0
    fi

  # QNAP (QTS & QuTS)
  elif [ -f /etc/config/qpkg.conf ]; then

    # Where is the software
    PKGDIR="$(getcfg -f /etc/config/qpkg.conf PlexMediaServer Install_path)"
    PLEX_SQLITE="$PKGDIR/Plex SQLite"
    LOG_TOOL="/sbin/log_tool -t 0 -a"

    # Where is the data
    AppSuppDir="$PKGDIR/Library"
    DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
    PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
    LOGFILE="$DBDIR/DBRepair.log"

    HostType="QNAP"
    return 0

  # Standard configuration Linux host
  elif [ -f /etc/os-release ]          && \
       [ -d /usr/lib/plexmediaserver ] && \
       [ -d /var/lib/plexmediaserver ]; then

    # Where is the software
    PKGDIR="/usr/lib/plexmediaserver"
    PLEX_SQLITE="$PKGDIR/Plex SQLite"
    LOG_TOOL="logger"

    # Where is the data
    AppSuppDir="/var/lib/plexmediaserver/Library/Application Support"
    DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
    PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"

    # Find the metadata dir if customized
    if [ -e /etc/systemd/system/plexmediaserver.service.d ]; then

      # Glob up all 'conf files' found
      NewSuppDir="$(cd /etc/systemd/system/plexmediaserver.service.d ; \
                    cat override.conf local.conf *.conf 2>/dev/null | grep "APPLICATION_SUPPORT_DIR" | head -1)"

      if [ "$NewSuppDir" != "" ]; then
        NewSuppDir="$(echo $NewSuppDir | sed -e 's/.*_DIR=//' | tr -d '"' | tr -d "'")"

        if [ -d "$NewSuppDir" ]; then
          AppSuppDir="$NewSuppDir"
        else
          echo "Given application support directory override specified does not exist: '$NewSuppDir'". Ignoring.
        fi
      fi
    fi

    DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
    PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
    LOGFILE="$DBDIR/DBRepair.log"

    HostType="$(grep ^PRETTY_NAME= /etc/os-release | sed -e 's/PRETTY_NAME=//' | sed -e 's/"//g')"
    return 0

  # Netgear ReadyNAS
  elif [ -e /etc/os-release ] && [ "$(cat /etc/os-release | grep ReadyNASOS)" != "" ]; then

    # Find PMS
    if [ "$(echo /apps/plexmediaserver*)" != "/apps/plexmediaserver*" ]; then

      PKGDIR="$(echo /apps/plexmediaserver*)"

      # Where is the code
      PLEX_SQLITE="$PKGDIR/Binaries/Plex SQLite"
      AppSuppDir="$PKGDIR/MediaLibrary"
      PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
      DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
      LOGFILE="$DBDIR/DBRepair.log"
      LOG_TOOL="logger"

      HostType="Netgear ReadyNAS"
      return 0
    fi

  # ASUSTOR
  elif [ -f /etc/nas.conf ] && grep ASUSTOR /etc/nas.conf >/dev/null && \
       [ -d "/volume1/Plex/Library/Plex Media Server" ];  then

    # Where are things
    PLEX_SQLITE="/volume1/.@plugins/AppCentral/plexmediaserver/Plex SQLite"
    AppSuppDir="/volume1/Plex/Library"
    PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
    DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
    LOGFILE="$DBDIR/DBRepair.log"
    LOG_TOOL="logger"

    HostType="ASUSTOR"
    return 0

  # Containers:
  # -  Docker cgroup v1 & v2
  # -  Podman (libpod)
  elif [ "$(grep docker /proc/1/cgroup | wc -l)" -gt 0 ] || [ "$(grep 0::/ /proc/1/cgroup)" = "0::/" ] ||
       [ "$(grep libpod /proc/1/cgroup | wc -l)" -gt 0 ]; then

    # HOTIO Plex image structure is non-standard (contains symlink which breaks detection)
    if  [ -d "/app/usr/lib/plexmediaserver" ] && [ -d "/config/Plug-in Support" ]; then
      PLEX_SQLITE="/app/usr/lib/plexmediaserver/Plex SQLite"
      AppSuppDir="/config"
      PID_FILE="$AppSuppDir/plexmediaserver.pid"
      DBDIR="$AppSuppDir/Plug-in Support/Databases"
      LOGFILE="$DBDIR/DBRepair.log"
      LOG_TOOL="logger"

      HostType="HOTIO"
      return 0

    # Docker (All main image variants except binhex and hotio)
    elif [ -d "/config/Library/Application Support" ]; then

      PLEX_SQLITE="/usr/lib/plexmediaserver/Plex SQLite"
      AppSuppDir="/config/Library/Application Support"
      PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
      DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
      LOGFILE="$DBDIR/DBRepair.log"
      LOG_TOOL="logger"

      HostType="Docker"
      return 0

    # BINHEX Plex image
    elif [ -d "/config/Plex Media Server" ]; then

      PLEX_SQLITE="/usr/lib/plexmediaserver/Plex SQLite"
      AppSuppDir="/config"
      PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
      DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
      LOGFILE="$DBDIR/DBRepair.log"
      LOG_TOOL="logger"

      HostType="BINHEX"
      return 0

    fi


  # Western Digital (OS5)
  elif [ -f /etc/system.conf ] && [ -d /mnt/HD/HD_a2/Nas_Prog/plexmediaserver ] && \
       grep "Western Digital Corp" /etc/system.conf >/dev/null; then

    # Where things are
    PLEX_SQLITE="/mnt/HD/HD_a2/Nas_Prog/plexmediaserver/binaries/Plex SQLite"
    AppSuppDir="$(echo /mnt/HD/HD*/Nas_Prog/plex_conf)"
    PID_FILE="$AppSuppDir/Plex Media Server/plexmediaserver.pid"
    DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
    LOGFILE="$DBDIR/DBRepair.log"
    LOG_TOOL="logger"

    HostType="Western Digital"
    return 0

  # Apple Mac
  elif [ -d "/Applications/Plex Media Server.app" ] && \
       [ -d "$HOME/Library/Application Support/Plex Media Server" ]; then

    # Where is the software
    PLEX_SQLITE="/Applications/Plex Media Server.app/Contents/MacOS/Plex SQLite"
    AppSuppDir="$HOME/Library/Application Support"
    DBDIR="$AppSuppDir/Plex Media Server/Plug-in Support/Databases"
    PID_FILE="$DBDIR/dbtmp/plexmediaserver.pid"
    LOGFILE="$DBDIR/DBRepair.log"
    LOG_TOOL="logger"

    # MacOS uses pgrep and uses different stat options
    PIDOF="pgrep"
    STATFMT="-f"
    STATBYTES="%z"

    # make the TMP directory in advance to store plexmediaserver.pid
    mkdir -p "$DBDIR/dbtmp"

    # Remove stale PID file if it exists
    [ -f "$PID_FILE" ] && rm "$PID_FILE"

    # If PMS is running create plexmediaserver.pid
    PIDVALUE=$($PIDOF "Plex Media Server")
    [ $PIDVALUE ] && echo $PIDVALUE > "$PID_FILE"

    HostType="Mac"
    return 0
  fi

  # Unknown / currently unsupported host
  return 1
}

# Simple function to set variables
SetLast() {

  LastName="$1"
  LastTimestamp="$2"
  return 0
}
#############################################################
#         Main utility begins here                          #
#############################################################

# Global variable - main database
CPPL=com.plexapp.plugins.library

# Initial timestamp
TimeStamp="$(date "+%Y-%m-%d_%H.%M.%S")"

# Initialize LastName LastTimestamp
SetLast "" ""

# Identify this host
HostType="" ; LOG_TOOL="echo"
if ! HostConfig; then
  Output 'Error: Unknown host. Currently supported hosts are: QNAP, Synology, Netgear, Mac, ASUSTOR, WD (OS5) and Linux Workstation/Server'
  exit 1
fi

# Is PMS already running?
if $PIDOF 'Plex Media Server' > /dev/null ; then
  Output "Plex Media Server is currently running, cannot continue."
  Output "Please stop Plex Media Server and restart this utility."
  WriteLog "PMS running. Could not continue."
  exit 1
fi

echo " "
# echo Detected Host:  $HostType
WriteLog "============================================================"
WriteLog "Session start: Host is $HostType"

# Make sure we have a logfile
touch "$LOGFILE"

# Basic checks;  PMS installed
if [ ! -f "$PLEX_SQLITE" ] ; then
  Output "PMS is not installed.  Cannot continue.  Exiting."
  WriteLog "Attempt to run utility without PMS installed."
  exit 1
fi

# Can I write to the Databases directory ?
if [ ! -w "$DBDIR" ]; then
  Output "ERROR: Cannot write to the Databases directory. Insufficient privilege or wrong UID. Exiting."
  exit 1
fi

# Databases exist or Backups exist to restore from
if [ ! -f "$DBDIR/$CPPL.db" ]       && \
   [ ! -f "$DBDIR/$CPPL.blobs.db" ] && \
   [ "$(echo com.plexapp.plugins.*-????-??-??)" = "com.plexapp.plugins.*-????-??-??" ]; then

  Output "Cannot locate databases. Cannot continue.  Exiting."
  WriteLog "No databases or backups found."
  exit 1
fi

# Set tmp dir so we don't use RAM when in DBDIR
DBTMP="./dbtmp"
mkdir -p "$DBDIR/$DBTMP"
export TMPDIR="$DBTMP"
export TMP="$DBTMP"

# Work in the Databases directory
cd "$DBDIR"

# Get the owning UID/GID before we proceed so we can restore
Owner="$(stat $STATFMT '%u:%g' $CPPL.db)"

# Run entire utility in a loop until all arguments used,  EOF on input, or commanded to exit
while true
do

  # Main menu loop
  Choice=0; Exit=0
  while [ $Choice -eq 0 ]
  do
    echo " "
    echo " "
    echo "      Plex Media Server Database Repair Utility ($HostType)"
    echo " "
    echo "Select"
    echo " "
    echo "  1. Check database"
    echo "  2. Vacuum database"
    echo "  3. Reindex database"
    echo "  4. Attempt database repair"
    echo "  5. Replace current database with newest usable backup copy"
    echo "  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)"
    echo "  7. Import Viewstate / Watch history from another PMS database"
    echo "  8. Show logfile"
    echo "  9. Exit"
    echo " "
    printf "Enter choice: "
    if [ "$1" != "" ]; then
      Input="$1"
      echo "$1"
      shift
    else
      read Input

      # Handle EOF/forced exit
      [ "$Input" = "" ] && Input=8 && Exit=1
    fi
    [ "$Input" = "1" ] && Choice=1
    [ "$Input" = "2" ] && Choice=2
    [ "$Input" = "3" ] && Choice=3
    [ "$Input" = "4" ] && Choice=4
    [ "$Input" = "5" ] && Choice=5
    [ "$Input" = "6" ] && Choice=6
    [ "$Input" = "7" ] && Choice=7
    [ "$Input" = "8" ] && Choice=8
    [ "$Input" = "9" ] && Choice=9

    [ "$Choice" -eq 0 ] && echo " " && echo "'$Input' - Is invalid. Try again"

    # Update timestamp
    TimeStamp="$(date "+%Y-%m-%d_%H.%M.%S")"
  done

  # Don't get caught; Is PMS already running?
  if $PIDOF 'Plex Media Server' > /dev/null ; then
    if [ $Choice -lt 8 ]; then
      Output "Plex Media Server is currently running, cannot continue."
      Output "Please stop Plex Media Server and restart this utility."
      WriteLog "PMS running. Could not continue."
      continue
    fi
  fi

  # Spacing for legibility
  echo ' '

  # 1. - Check database
  if [ $Choice -eq 1 ]; then

    # CHECK DBs
    if CheckDatabases "Check  " force ; then
      WriteLog "Check   - PASS"
      CheckedDB=1
    else
      WriteLog "Check   - FAIL"
      CheckedDB=0
    fi

  # 2. Vacuum DB
  elif [ $Choice -eq 2 ]; then

    # Clear flags
    Fail=0
    Damaged=0

    # Check databases before Indexing if not previously checked
    if ! CheckDatabases "Vacuum " ; then
      Damaged=1
      Fail=1
    fi

    # If damaged, exit
    if [ $Damaged -eq 1 ]; then
      Output "Databases are damaged. Vacuum operation not available.  Please repair or replace first."
      WriteLog "Vacuum  - Databases damaged."
      continue
    fi


    # Make a backup
    Output "Backing up databases"
    if ! MakeBackups "Vacuum "; then
      Output "Error making backups.  Cannot continue."
      WriteLog "Vacuum  - MakeBackups - FAIL"
      Fail=1
      continue
    else
      WriteLog "Vacuum  - MakeBackups - PASS"
    fi

    # Start vacuuming
    Output "Vacuuming main database"
    SizeStart=$(GetSize $CPPL.db)

    # Vacuum it
    "$PLEX_SQLITE" $CPPL.db 'VACUUM;'
    Result=$?

    if SQLiteOK $Result; then
      SizeFinish=$(GetSize $CPPL.db)
      Output "Vacuuming main database successful (Size: ${SizeStart}MB/${SizeFinish}MB)."
      WriteLog "Vacuum  - Vacuum main database - PASS (Size: ${SizeStart}MB/${SizeFinish}MB)."
    else
      Output "Vaccuming main database failed. Error code $Result from Plex SQLite"
      WriteLog "Vacuum  - Vacuum main database - FAIL ($Result)"
      Fail=1
    fi

    Output "Vacuuming blobs database"
    SizeStart=$(GetSize $CPPL.blobs.db)

    # Vacuum it
    "$PLEX_SQLITE" $CPPL.blobs.db 'VACUUM;'
    Result=$?

    if SQLiteOK $Result; then
      SizeFinish=$(GetSize $CPPL.blobs.db)
      Output "Vacuuming blobs database successful (Size: ${SizeStart}MB/${SizeFinish}MB)."
      WriteLog "Vacuum  - Vacuum blobs database - PASS (Size: ${SizeStart}MB/${SizeFinish}MB)."
    else
      Output "Vaccuming blobs database failed. Error code $Result from Plex SQLite"
      WriteLog "Vacuum  - Vacuum blobs database - FAIL ($Result)"
      Fail=1
    fi

    if [ $Fail -eq 0 ]; then
      Output "Vacuum complete."
      WriteLog "Vacuum  - PASS"
      SetLast "Vacuum" "$TimeStamp"
    else
      Output "Vacuum failed."
      WriteLog "Vacuum  - FAIL"
      RestoreSaved "$TimeStamp"
    fi
    continue

  # 3. Reindex DB
  elif [ $Choice -eq 3 ]; then

    # Clear flag
    Damaged=0
    Fail=0
    # Check databases before Indexing if not previously checked
    if ! CheckDatabases "Reindex" ; then
      Damaged=1
      Fail=1
    fi


    # If damaged, exit
    if [ $Damaged -eq 1 ]; then
      Output "Databases are damaged. Reindex operation not available.  Please repair or replace first."
      continue
    fi

    # Databases are OK,  Make a backup
    Output "Backing up of databases"
    MakeBackups "Reindex"
    Result=$?
    if [ $Result -eq 0 ]; then
      WriteLog "Reindex - MakeBackup - PASS"
    else
      Output "Error making backups.  Cannot continue."
      WriteLog "Reindex - MakeBackup - FAIL ($Result)"
      Fail=1
      continue
    fi

    # Databases are OK,  Start reindexing
    Output "Reindexing main database"
    "$PLEX_SQLITE" $CPPL.db 'REINDEX;'
    Result=$?
    if SQLiteOK $Result; then
      Output "Reindexing main database successful."
      WriteLog "Reindex - Reindex: $CPPL.db - PASS"
    else
      Output "Reindexing main database failed. Error code $Result from Plex SQLite"
      WriteLog "Reindex - Reindex: $CPPL.db - FAIL ($Result)"
      Fail=1
    fi

    Output "Reindexing blobs database"
    "$PLEX_SQLITE" $CPPL.blobs.db 'REINDEX;'
    Result=$?
    if SQLiteOK $Result; then
      Output "Reindexing blobs database successful."
      WriteLog "Reindex - Reindex: $CPPL.blobs.db - PASS"
    else
      Output "Reindexing blobs database failed. Error code $Result from Plex SQLite"
      WriteLog "Reindex - Reindex: $CPPL.blobs.db - FAIL ($Result)"
      Fail=1
    fi

    Output "Reindex complete."

    if [ $Fail -eq 0 ]; then
      SetLast "Reindex" "$TimeStamp"
      WriteLog "Reindex - PASS"
    else
      RestoreSaved "$TimeStamp"
      WriteLog "Reindex - FAIL"
    fi
    continue


  # 4. - Attempt DB repair
  elif [ $Choice -eq 4 ]; then

    Damaged=0
    Fail=0

    # Verify DBs are here
    if [ ! -e $CPPL.db ]; then
      Output "No main Plex database exists to repair. Exiting."
      WriteLog "Repair  - No main database - FAIL"
      Fail=1
      continue
    fi

    # Check size
    Size=$(stat $STATFMT $STATBYTES $CPPL.db)

    # Exit if not valid
    if [ $Size -lt 300000 ]; then
      Output "Main database is too small/truncated, repair is not possible.  Please try restoring a backup. "
      WriteLog "Repair  - Main databse too small - FAIL"
      Fail=1
      continue
    fi

    # Continue
    Output "Exporting current databases using timestamp: $TimeStamp"
    Fail=0

    # Get the owning UID/GID before we proceed so we can restore
    Owner="$(stat $STATFMT '%u:%g' $CPPL.db)"

    # Attempt to export main db to SQL file (Step 1)
    printf  'Export: (main)..'
    "$PLEX_SQLITE" $CPPL.db  ".output '$TMPDIR/library.plexapp.sql-$TimeStamp'" .dump
    Result=$?
    if ! SQLiteOK $Result; then

      # Cannot dump file
      Output "Error $Result from Plex SQLite while exporting $CPPL.db"
      Output "Could not successfully export the main database to repair it.  Please try restoring a backup."
      WriteLog "Repair  - Cannot recover main database to '$TMPDIR/library.plexapp.sql-$TimeStamp' - FAIL ($Result)"
      Fail=1
      continue
    fi

    # Attempt to export blobs db to SQL file
    printf '(blobs)..'
    "$PLEX_SQLITE" $CPPL.blobs.db  ".output '$TMPDIR/blobs.plexapp.sql-$TimeStamp'" .dump
    Result=$?
    if ! SQLiteOK $Result; then

      # Cannot dump file
      Output "Error $Result from Plex SQLite while exporting $CPPL.blobs.db"
      Output "Could not successfully export the blobs database to repair it.  Please try restoring a backup."
      WriteLog "Repair  - Cannot recover blobs database to '$TMPDIR/blobs.plexapp.sql-$TimeStamp' - FAIL ($Result)"
      Fail=1
      continue
    fi

    # Edit the .SQL files if all OK
    if [ $Fail -eq 0 ]; then

      # Edit
      sed -i -e 's/ROLLBACK;/COMMIT;/' "$TMPDIR/library.plexapp.sql-$TimeStamp"
      sed -i -e 's/ROLLBACK;/COMMIT;/' "$TMPDIR/blobs.plexapp.sql-$TimeStamp"
    fi

    # Inform user
    echo done.
    Output "Successfully exported the main and blobs databases.  Proceeding to import into new databases."
    WriteLog "Repair  - Export databases - PASS"

    # Library and blobs successfully exported, create new
    printf 'Import: (main)..'
    "$PLEX_SQLITE" $CPPL.db-$TimeStamp < "$TMPDIR/library.plexapp.sql-$TimeStamp"
    Result=$?
    if ! SQLiteOK $Result; then
      Output "Error $Result from Plex SQLite while importing from '$TMPDIR/library.plexapp.sql-$TimeStamp'"
      WriteLog "Repair  - Cannot import main database from '$TMPDIR/library.plexapp.sql-$TimeStamp' - FAIL ($Result)"
      Output "Cannot continue."
      Fail=1
      continue
    fi

    printf '(blobs)..'
    "$PLEX_SQLITE" $CPPL.blobs.db-$TimeStamp < "$TMPDIR/blobs.plexapp.sql-$TimeStamp"
    Result=$?
    if ! SQLiteOK $Result ; then
      Output "Error $Result from Plex SQLite while importing from '$TMPDIR/blobs.plexapp.sql-$TimeStamp'"
      WriteLog "Repair  - Cannot import blobs database from '$TMPDIR/blobs.plexapp.sql-$TimeStamp' - FAIL ($Result)"
      Output "Cannot continue."
      Fail=1
      continue
    fi

    # Made it to here, now verify
    echo done.
    Output "Successfully imported data from exported SQL files."
    WriteLog "Repair  - Import - PASS"

    # Verify databases are intact and pass testing
    Output "Verifying databases integrity after importing."

    # Check main DB
    if CheckDB $CPPL.db-$TimeStamp ; then
      SizeStart=$(GetSize $CPPL.db)
      SizeFinish=$(GetSize $CPPL.db-$TimeStamp)
      Output "Verification complete.  PMS main database is OK."
      WriteLog "Repair  - Verify main database - PASS (Size: ${SizeStart}MB/${SizeFinish}MB)."
    else
      Output "Verification complete.  PMS main database import failed."
      WriteLog "Repair  - Verify main database - FAIL ($SQLerror)"
      Fail=1
    fi

    # Check blobs DB
    if CheckDB $CPPL.blobs.db-$TimeStamp ; then
      SizeStart=$(GetSize $CPPL.blobs.db)
      SizeFinish=$(GetSize $CPPL.blobs.db-$TimeStamp)
      Output "Verification complete.  PMS blobs database is OK."
      WriteLog "Repair  - Verify blobs database - PASS (Size: ${SizeStart}MB/${SizeFinish}MB)."
    else
      Output "Verification complete.  PMS blobs database import failed."
      WriteLog "Repair  - Verify main database - FAIL ($SQLerror)"
      Fail=1
    fi

    # If not failed,  move files normally
    if [ $Fail -eq 0 ]; then

      Output "Saving current databases with '-ORIG-$TimeStamp'"
      [ -e $CPPL.db ]       && mv $CPPL.db       "$TMPDIR/$CPPL.db-ORIG-$TimeStamp"
      [ -e $CPPL.blobs.db ] && mv $CPPL.blobs.db "$TMPDIR/$CPPL.blobs.db-ORIG-$TimeStamp"

      Output "Making imported databases active"
      mv $CPPL.db-$TimeStamp       $CPPL.db
      mv $CPPL.blobs.db-$TimeStamp $CPPL.blobs.db

      Output "Import complete. Please check your library settings and contents for completeness."
      Output "Recommend:  Scan Files and Refresh all metadata for each library section."

      # Remove .sql temp files from $TMPDIR
      # rm -f "$TMPDIR"/*.sql-*

      # Ensure WAL and SHM are gone
      [ -e $CPPL.blobs.db-wal ] && rm -f $CPPL.blobs.db-wal
      [ -e $CPPL.blobs.db-shm ] && rm -f $CPPL.blobs.db-shm
      [ -e $CPPL.db-wal ]       && rm -f $CPPL.db-wal
      [ -e $CPPL.db-shm ]       && rm -f $CPPL.db-shm

      # Set ownership on new files
      chown $Owner $CPPL.db $CPPL.blobs.db

      # We didn't fail, set CheckedDB status true (passed above checks)
      CheckedDB=1

      WriteLog "Repair  - Move files - PASS"
      WriteLog "Repair  - PASS"

      SetLast "Repair" "$TimeStamp"
    else

      rm -f $CPPL.db-$TimeStamp
      rm -f $CPPL.blobs.db-$TimeStamp

      Output "Repair has failed.  No files changed"
      WriteLog "Repair - $TimeStamp - FAIL"
      Retain=1
    fi
    continue

  # 5. Replace database from backup copy
  elif [ $Choice -eq 5 ]; then

    # If Databases already checked, confirm the user really wants to do this
    Confirmed=0
    Fail=0
    if CheckDatabases "Replace"; then
      if ConfirmYesNo "Are you sure you want to restore a previous database backup"; then
        Confirmed=1
      fi
    fi

    if [ $Damaged -eq 1 ] || [ $Confirmed -eq 1 ]; then
      # Get list of dates to use
      Dates=$(GetDates)

      # If no backups, error and exit
      if [ "$Dates" = "" ]  && [ $Damaged -eq 1 ]; then
        Output "Database is damaged and no backups avaiable."
        Output "Only available option is Repair."
        WriteLog "Replace - Scan for usable candidates - FAIL"
        continue
      fi

      Output "Checking for a usable backup."
      Candidate=""

      Output "Database backups available are:  $Dates"
      for i in $Dates
      do

        # Check candidate
        if [ -e $CPPL.db-$i          ]   && \
           [ -e $CPPL.blobs.db-$i    ]   && \
           Output "Checking database $i" && \
           CheckDB $CPPL.db-$i           && \
           CheckDB $CPPL.blobs.db-$i     ; then

          Output "Found valid database backup date: $i"
          Candidate=$i

          UseThis=0
          if ConfirmYesNo "Use backup '$Candidate' ?"; then
            UseThis=1
          fi

          # OK, use this one
          if [ $UseThis -eq 1 ]; then

            # Move database, wal, and shm  (keep safe) with timestamp
            Output "Saving current databases with timestamp: '-ORIG-$TimeStamp'"

            for j in "db" "db-wal" "db-shm" "blobs.db" "blobs.db-wal" "blobs.db-shm"
            do
              [ -e $CPPL.$j ] && mv -f $CPPL.$j  "$TMPDIR/$CPPL.$j-ORIG-$TimeStamp"
            done
            WriteLog "Replace - Move Files - PASS"

            # Copy this backup into position as primary
            Output "Copying backup database $Candidate to use as new database."

            cp -p $CPPL.db-$Candidate $CPPL.db-$TimeStamp
            Result=$?

            if [ $Result -ne 0 ]; then
              Output "Error $Result while copying $CPPL.db"
              Output "Database file is incomplete.   Please resolve manually."
              WriteLog "Replace - Copy $CPPL.db-$Candidate - FAIL"
              Fail=1
            else
              WriteLog "Replace - Copy $CPPL.db-$i - PASS"
            fi

            cp -p $CPPL.blobs.db-$Candidate $CPPL.blobs.db-$TimeStamp
            Result=$?

            if [ $Result -ne 0 ]; then
              Output "Error $Result while copying $CPPL.blobs.db"
              Output "Database file is incomplete.   Please resolve manually."
              WriteLog "Replace - Copy $CPPL.blobs.db-$Candidate - FAIL"
              Fail=1
            else
              WriteLog "Replace - Copy $CPPL.blobs.db-$Candidate - PASS"
            fi

            # If no failure copying,  check and make active
            if [ $Fail -eq 0 ]; then
              # Final checks
              Output "Copy complete. Performing final check"

              if CheckDB $CPPL.db-$TimeStamp         && \
                 CheckDB $CPPL.blobs.db-$TimeStamp   ;  then

                # Move into position as active
                mv $CPPL.db-$TimeStamp       $CPPL.db
                mv $CPPL.blobs.db-$TimeStamp $CPPL.blobs.db

                # done
                Output "Database recovery and verification complete."
                WriteLog "Replace - Verify databases - PASS"

              else

                # DB did not verify after copy -- Something wrong

                rm -f $CPPL.db-$TimeStamp  $CPPL.blobs.db-$TimeStamp
                Output "Final check failed.  Keeping existing databases"
                WriteLog "Replace - Verify databases - FAIL"
                WriteLog "Replace - Failed Databses - REMOVED"
              fi
            else

              Output "Could not copy backup databases. Out of disk space?"
              Output "Restoring original databases"

              for k in "db" "db-wal" "db-shm" "blobs.db" "blobs.db-wal" "blobs.db-shm"
              do
                [ -e "$TMPDIR/$CPPL.$k-ORIG-$TimeStamp" ] && mv -f "$TMPDIR/$CPPL.$k-ORIG-$TimeStamp" $CPPL.$k
              done
              WriteLog "Replace - Verify databases - FAIL"
              Fail=1
            fi

            # If successful, save
            [ $Fail -eq 0 ] && SetLast "Replace" "$TimeStamp"
            break
          fi
        fi
      done

      # Error check if no Candidate found
      if [ "$Candidate" = "" ]; then
        Output "Error.  No valid matching main and blobs database pairs.  Cannot replace."
        WriteLog "Replace - Select candidate - FAIL"
      fi
    fi

  # 6.  - Undo last successful action
  elif [ $Choice -eq 6 ]; then


    # Confirm there is something to undo
    if [ "$LastTimestamp" != "" ]; then

      # Educate user
      echo " "
      echo "'Undo' restores the databases to the state prior to the last SUCCESSFUL action."
      echo "If any action fails before it completes,   that action is automatically undone for you."
      echo "Be advised:  Undo restores the databases to their state PRIOR TO the last action of 'Vacuum', 'Reindex', or 'Replace'"
      echo "WARNING:  Once Undo completes,  there will be nothing more to Undo untl another successful action is completed"
      echo " "

      if ConfirmYesNo "Undo '$LastName' performed at timestamp '$LastTimestamp' ? "; then

        Output "Undoing $LastName ($LastTimestamp)"
        for j in "db" "db-wal" "db-shm" "blobs.db" "blobs.db-wal" "blobs.db-shm"
        do
        [ -e "$TMPDIR/$CPPL.$j-ORIG-$LastTimestamp" ] && mv -f "$TMPDIR/$CPPL.$j-ORIG-$LastTimestamp" $CPPL.$j
        done

        Output "Undo complete."
        WriteLog "Undo    - Undo ${LastName}, TimeStamp $LastTimestamp"
        SetLast "Undo" ""
      fi

    else
      Output "Nothing to undo."
      WriteLog "Undo    - Nothing to Undo."
    fi

  # 7.  - Get Viewstate/Watch history from another DB and import
  elif [ $Choice -eq 7 ]; then

    printf "Pathname of database containing watch history to import: "
    read Input

    # Did we get something?
    [ "$Input" = "" ] && continue

    # Go see if it's a valid database
    if [ ! -f "$Input" ]; then
      Output "'$Input' does not exist."
      continue
    fi

    Output " "
    WriteLog "Import  - Attempting to import watch history from '$Input' "

    # Confirm our databases are intact
    if ! CheckDatabases "Import "; then
      Output "Error:  PMS databases are damaged.  Repair needed. Refusing to import."
      WriteLog "Import   - Verify main database - FAIL"
      continue
    fi

    # Check the given database
    Output "Checking database '$Input'"
    if ! CheckDB "$Input"; then
      Output "Error:  Given database '$Input' is damaged.  Repair needed. Database not trusted.  Refusing to import."
      WriteLog "Import  - Verify '$Input' - FAIL"
      continue
    fi
    WriteLog "Import  - Verify '$Input' - PASS"
    Output "Check complete.  '$Input' is OK."


    # Make a backup
    Output "Backing up PMS databases"
    if ! MakeBackups "Import "; then
      Output "Error making backups.  Cannot continue."
      WriteLog "Import  - MakeBackups - FAIL"
      Fail=1
      continue
    fi
    WriteLog "Import  - MakeBackups - PASS"


    # Export viewstate from DB
    Output "Exporting Viewstate & Watch history"
    echo ".dump metadata_item_settings metadata_item_views " | "$PLEX_SQLITE" "$Input" | grep -v TABLE | grep -v INDEX > "$TMPDIR/Viewstate.sql-$TimeStamp"

    # Make certain we got something usable
    if [ $(wc -l "$TMPDIR/Viewstate.sql-$TimeStamp" | awk '{print $1}') -lt 1 ]; then
      Output "No viewstates or history found to import."
      WriteLog "Import  - Nothing to import - FAIL"
      continue
    fi

    # Make a working copy to import into
    Output "Preparing to import Viewstate and History data"
    cp -p $CPPL.db $CPPL.db-$TimeStamp
    Result=$?

    if [ $Result -ne 0 ]; then
      Output "Error $Result while making a working copy of the PMS main database."
      Output "      File permissions?  Disk full?"
      WriteLog "Import  - Prepare: Make working copy - FAIL"
      continue
    fi

    # Import viewstates into working copy
    printf 'Importing Viewstate & History data...'
    "$PLEX_SQLITE" $CPPL.db-$TimeStamp < "$TMPDIR/Viewstate.sql-$TimeStamp" 2> /dev/null

    # Make certain the resultant DB is OK
    Output " done."
    Output "Checking database following import"

    if ! CheckDB $CPPL.db-$TimeStamp ; then

      # Import failed discard
      Output "Error: Error code $Result during import.  Import corrupted database."
      Output "       Discarding import attempt."

      rm -f $CPPL.db-$TimeStamp

      WriteLog "Import  - Import: $Input - FAIL"
      continue
    fi

    # Import successful; switch to new DB
    Output "PMS main database is OK.  Making imported database active"
    WriteLog "Import  - Import: Making imported database active"

    # Move from tmp to active
    mv $CPPL.db-$TimeStamp $CPPL.db

    # We were successful
    Output "Viewstate import successful."
    WriteLog "Import  - Import: $Input - PASS"

    # We were successful
    SetLast "Import" "$TimeStamp"
    continue

  # 8.  - Show Logfile
  elif [ $Choice -eq 8 ]; then

    echo ==================================================================================
    cat "$LOGFILE"
    echo ==================================================================================

  # 9.  - Exit
  elif [ $Choice -eq 9 ]; then

    # Ask questions on graceful exit
    if [ $Exit -eq 0 ]; then
      # Ask if the user wants to remove the DBTMP directory and all backups thus far
      if ConfirmYesNo "Ok to remove temporary databases/workfiles for this session?" ; then

        # Here it goes
        Output "Deleting all temporary work files."
        WriteLog "Exit    - Delete temp files."
        rm -rf "$TMPDIR"
      else
        Output "Retaining all temporary work files."
        WriteLog "Exit    - Retain temp files."
      fi
    else
      Output "Unexpected exit command.  Keeping all temporary work files."
      WriteLog "EOFExit - Retain temp files."
    fi

    WriteLog "Session end."
    WriteLog "============================================================"
    exit 0
  fi
done
exit 0
