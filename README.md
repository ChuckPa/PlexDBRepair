# PlexDBRepair

[![GitHub issues](https://img.shields.io/github/issues/ChuckPa/PlexDBRepair.svg?style=flat)](https://github.com/ChuckPa/PlexDBRepair/issues)
[![Release](https://img.shields.io/github/release/ChuckPa/PlexDBRepair.svg?style=flat)](https://github.com/ChuckPa/PlexDBRepair/releases/latest)
[![Download latest release](https://img.shields.io/github/downloads/ChuckPa/PlexDBRepair/latest/total.svg)](https://github.com/ChuckPa/PlexDBRepair/releases/latest)
[![Download total](https://img.shields.io/github/downloads/ChuckPa/PlexDBRepair/total.svg)](https://github.com/ChuckPa/PlexDBRepair/releases)
[![master](https://img.shields.io/badge/master-stable-green.svg?maxAge=2592000)]('')
![Maintenance](https://img.shields.io/badge/Maintained-Yes-green.svg)

# Introduction

DBRepair provides database repair and maintenance for the most common  Plex Media Server database problems.
It is a simple menu-driven utility with a command line backend.
## Situations and errors commonly seen include:

        1. Searching is sluggish
        2. Database is malformed / damaged / corrupted
        3. Database has bloated from media addition or changes
        4. Damaged indexes damaged

## Functions provided

 The utility accepts command names.
 Command names may be upper/lower case and may also be abbreviated (4 character minimum).

 The following commands (or their number), listed in alphabetical order,  are accepted as input.

   AUTO(matic)  - Automatically check, repair/optimize, and reindex the databases in one step.
   CHEC(k)      - Check the main and blob databases integrity
   EXIT         - Exit the utility
   IMPO(rt)     - Import viewstate / watch history from another database
   REIN(dex)    - Rebuild the database indexes
   REPL(ace)    - Replace the existing databases with a PMS-generated backup
   SHOW         - Show the log file
   STAR(t)      - Start PMS (not available on all platforms)
   STOP         - Stop PMS  (not available on all platforms)
   UNDO         - UNDO the last operation
   VACU(um)     - Vacuum the databases


### The menu

  The menu gives you the option to enter either a 'command number' or the 'command name/abbreviation'.
  For clarity, each command's name is 'quoted'.


      Plex Media Server Database Repair Utility (_host_configuration_name_)
                       Version v1.0.0

  Select

      1 - 'stop' PMS (if available)
      2 - 'automatic' database check, repair/optimize, and reindex in one step.
      3 - 'check' database
      4 - 'vacuum' database
      5 - 'repair' / 'optimize' database
      6 - 'reindex' database
      7 - 'start' PMS (if available)
      8 - 'import' viewstate (Watch history) from another PMS database
      9 - 'replace' current database with newest usable backup copy (interactive)
     10 - 'show' logfile
     11 - 'status' of PMS (Stop/Run and databases)
     12 - 'undo' - Undo last successful command

     99 -  exit

  Enter command # -or- command name (4 char min) :



## Hosts currently supported

        1. Apple (MacOS)
        2. ASUSTOR
        3. Docker containers via 'docker exec' command (inside the running container environment)
           - Plex,inc.
           - Linuxserver.io
           - BINHEX
           - HOTIO
           - Podman (libgpod)
        4. Linux workstation & server
        5. Netgear (OS5 Linux-based systems)
        6. QNAP (QTS & QuTS)
        7. Synology (DSM 6 & DSM 7)
        8. Western Digital (OS5)

 # Installation

    Where to place the utility varies from host to host.
    Please use this table as a reference.

```
    Vendor             | Shared folder name  |  directory
    -------------------+---------------------+------------------------------------------
    Apple              | Downloads           |  ~/Downloads
    ASUSTOR            | Public              |  /volume1/Public
    binhex             | N/A                 |  Container root (adjacent /config)
    Docker             | N/A                 |  Container root (adjacent /config)
    Hotio              | N/A                 |  Container root (adjacent /config)
    Linux (wkstn/svr)  | N/A                 |  Anywhere
    Netgear (ReadyNAS) | "your_choice"       |  "/data/your_choice"
    QNAP (QTS/QuTS)    | Public              |  /share/Public
    Synology (DSM 6)   | Plex                |  /volume1/Plex             (change volume as required)
    Synology (DSM 7)   | PlexMediaServer     |  /volume1/PlexMediaServer  (change volume as required)
    Western Digital    | Public              |  /mnt/HD/HD_a2/Public      (Does not support 'MyCloudHome' series)


### General installation and usage instructions
```
        1. Open your browser to https://github.com/ChuckPa/PlexDBRepair/releases/latest
        2. Download the source code (tar.gz or ZIP) file

        3. Knowing the file name will always be of the form 'PlexDBRepair-X.Y.Z.tar.gz'
           --  where X.Y.Z is the release number.  Use the real values in place of X, Y, and Z.
        4. Place the tar.gz file in the appropriate directory on the system you'll use it.
        5. Open a command line session (usually Terminal or SSH)
        6. Elevate privilege level to root (sudo) if needed.
        7. Extract the utility from the tar or zip file
        8. 'cd' into the extraction directory
        9. Give DBRepair.sh 'execute' permission  (chmod +x)
       10. Invoke ./DBRepair.sh

```


###   EXAMPLE:  To install & launch on Synology DSM 6
```
        cd /volume1/Plex
        sudo bash
        tar xf PlexDBRepair-x.y.z.tar.gz
        cd PlexDBRepair-x.y.z
        chmod +x DBRepair.sh
        ./DBRepair.sh
```

###    EXAMPLE: Using DBRepair inside containers (manual start/stop included)

#### (Select containers allow stopping/starting PMS from the menu.  See menu for details)
```
        sudo docker exec -it plex /bin/bash

        # Stop Plex manually when using official Plex,inc image
        /plex_service.sh -d
--or--
        # Stop Plex manually when using Linuxserver.io Plex image
        s6-svc -d /var/run/service/svc-plex
--or--
        # Stop Plex manually in binhex containers
        kill -15 $(pidof 'Plex Media Server')
--or--
        # Stop Plex manually in HOTIO containers
        s6-svc -d /run/service/plex


        # extract from downloaded version file name then cd into directory
        tar xf PlexDBRepair-0.6.4.tar.gz
        cd PlexDBRepair-0.6.4
        chmod +x DBRepair.sh
        ./DBRepair.sh
```
###    EXAMPLE:  Using DBRepair on regular Linux native host (Workstation/Server)
```
        sudo bash
        systemctl stop plexmediaserver
        cd /path/to/DBRepair.tar
        tar xf PlexDBRepair-0.6.1.tar.gz
        cd PlexDBRepair-0.6.1
        chmod +x DBRepair.sh
        ./DBRepair.sh
```

###    EXAMPLE: Using DBRepair from the command line on MacOS (on the administrator account)
```
        osascript -e 'quit app "Plex Media Server"'
        cd ~/Downloads
        tar xvf PlexDBRepai PlexDBRepair-0.6.1.tar.gz
        cd PlexDBRepai PlexDBRepair-0.6.1

        chmod +x DBRepair.sh
        ./DBRepair.sh
```


## Typical usage
```
This utility can only operate on PMS when PMS is in the stopped state.
If PMS is running when you startup the utility,  it will tell you.

These examples

  A.  The most common usage will be the "Automatic" function.

    Automatic mode is where DBRepair determines which steps are needed to make your database run optimally.
    For most users, Automatic is equivalent to 'Check, Repair, Reindex'.
    This repairs minor damage, vacuums out all the unused records, and rebuilds search indexes in one step.

  B. Database is malformed  (Backups of  com.plexapp.plugins.library.db and com.plexap.plugins.library.blobs.db available)
     Note: You may attempt "Repair" sequence

    1. (3)  Check   - Confirm either main or blobs database is damaged
    2. (9)  Replace - Use the most recent valid backup -- OR -- (5) Repair.  Check date/time stamps for best action.
                    -- If Replace fails, use Repair (5)
                    -- (Replace can fail if the database has been damaged for a long time.)
    3. (6)  Reindex - Generate new indexes so PMS doesn't need to at startup
    4. (99) Exit

  C. Database is malformed - No Backups
    1. (3)  Check   - Confirm either main or blobs database is damaged
    2. (5)  Repair  - Salavage as much as possible from the databases and rebuild them into a usable database.
    3. (6)  Reindex - Generate new indexes so PMS doesn't need to at startup
    4. (99) Exit

  C. Database sizes excessively large when compared to amount of media indexed (item count)
    1. (3)  Check   - Make certain both databases are fully intact  (repair if needed)
    2. (4)  Vacuum  - Instruct SQLite to rebuild its tables and recover unused space.
    3. (6)  Reindex - Rebuild Indexes.
    4. (99) Exit

  D. User interface has become 'sluggish' as more media was added
    1. (3)  Check   - Confirm there is no database damage
    2. (5)  Repair  - You are not really repairing.  You are rebuilding the DB in perfect sorted order.
    3. (6)  Reindex - Rebuild Indexes.
    4. Exit    - (Option 9)

  E. Undo
    Undo is a special case where you need the utility to backup ONE step.
    This is rarely needed.  The only time you might want/need to backup one step is if Replace leaves you worse off
    than you were before. In this case, UNDO then Repair.  Undo can only undo the single most-recent action.
    (Note: In a future release, you will be able to 'undo' every action taken until the DBs are in their original state)

Special considerations:

    1. As stated above, this utilty requires PMS to be stopped in order to do what it does.
    2. - This utility CAN sit at the menu prompt with PMS running.
       - You did a few things and want to check BEFORE exiting the utility
       - If you don't like how it worked out,
        -- STOP PMS
        -- UNDO the last action and do something else
        -- OR do more things to the databases
    3. When satisfied,  Exit the utility.
       - There is no harm in keeping the database temp files (except for space used)
       - ALL database temps are named with date-time stamps in the name to avoid confusion.
    4. The Logfile ('show' command) shows all actions performed WITH timestamp so you can locate intermediate databases
       if desired for special / manual recovery cases.
```

## Scripting support

  Certain platforms don't provide for each command line access.
  To support those products,  this utility can be operated by adding command line arguments.

  Another use of this feature is to automate Plex Database maintenance
  ( Stop Plex,  Run this sequence,  Start Plex ) at a time when the server isn't busy


  The command line arguments are the same as if typing at the menu.

  Example:   ./DBRepair.sh  stop auto start exit

  This executes:   Stop PMS,  Automatic (Check, Repair, Reindex), Start PMS, and Exit commands


## Exiting

  When exiting,  you will be asked whether to keep the interim temp files created during this session.
  If you've encountered any difficulties or aren't sure what to do,  don't delete them.
  You'll be able to ask in the Plex forums about what to do.  Be prepared to present the log file to them.


## Sample session



  This sample session shows all the features present.  You won't use :
   1.  PMS exclusive access to the databases interlock protecting your data
   2.  Basic checks, vacuum, and reindex
   3.  Full export/import (repair) which also reloads the database in perfect order
   4.  Importing viewstate (watch history) data from another database (an older backup)
   5.  What the log file details for you.


```
bash-4.4# pwd
/volume1/Plex
bash-4.4# ./DBRepair.sh
Plex Media Server is currently running, cannot continue.
Please stop Plex Media Server and restart this utility.
bash-4.4# ./DBRepair.sh
Plex Media Server is currently running, cannot continue.
Please stop Plex Media Server and restart this utility.
bash-4.4# ./DBRepair.sh





=======================================================================================================
bash-4.4# ./DBRepair.sh



      Plex Media Server Database Repair Utility (Synology (DSM 7))
                       Version v1.0.0


Select

  1 - 'stop' PMS
  2 - 'automatic' database check, repair/optimize, and reindex in one step.
  3 - 'check' database
  4 - 'vacuum' database
  5 - 'repair' / 'optimize' database
  6 - 'reindex' database
  7 - 'start' PMS
  8 - 'import' viewstate (Watch history) from another PMS database
  9 - 'replace' current database with newest usable backup copy (interactive)
 10 - 'show' logfile
 11 - 'status' of PMS (Stop/Run and databases)
 12 - 'undo' - Undo last successful command
 99 -  exit

Enter command # -or- command name (4 char min) : 1

Stopping PMS.
Stopped PMS.

Select

  1 - 'stop' PMS
  2 - 'automatic' database check, repair/optimize, and reindex in one step.
  3 - 'check' database
  4 - 'vacuum' database
  5 - 'repair' / 'optimize' database
  6 - 'reindex' database
  7 - 'start' PMS
  8 - 'import' viewstate (Watch history) from another PMS database
  9 - 'replace' current database with newest usable backup copy (interactive)
 10 - 'show' logfile
 11 - 'status' of PMS (Stop/Run and databases)
 12 - 'undo' - Undo last successful command
 99 -  exit

Enter command # -or- command name (4 char min) : auto


Checking the PMS databases
Check complete.  PMS main database is OK.
Check complete.  PMS blobs database is OK.

Exporting current databases using timestamp: 2023-02-25_16.15.11
Exporting Main DB
Exporting Blobs DB
Successfully exported the main and blobs databases.  Proceeding to import into new databases.
Importing Main DB.
Importing Blobs DB.
Successfully imported data from SQL files.
Verifying databases integrity after importing.
Verification complete.  PMS main database is OK.
Verification complete.  PMS blobs database is OK.
Saving current databases with '-BKUP-2023-02-25_16.15.11'
Making imported databases active
Import complete. Please check your library settings and contents for completeness.
Recommend:  Scan Files and Refresh all metadata for each library section.

Backing up of databases
Backup current databases with '-BKUP-2023-02-25_16.20.41' timestamp.
Reindexing main database
Reindexing main database successful.
Reindexing blobs database
Reindexing blobs database successful.
Reindex complete.
Automatic Check,Repair/optimize,Index successful.

Select

  1 - 'stop' PMS
  2 - 'automatic' database check, repair/optimize, and reindex in one step.
  3 - 'check' database
  4 - 'vacuum' database
  5 - 'repair' / 'optimize' database
  6 - 'reindex' database
  7 - 'start' PMS
  8 - 'import' viewstate (Watch history) from another PMS database
  9 - 'replace' current database with newest usable backup copy (interactive)
 10 - 'show' logfile
 11 - 'status' of PMS (Stop/Run and databases)
 12 - 'undo' - Undo last successful command
 99 -  exit

Enter command # -or- command name (4 char min) : start

Starting PMS.
Started PMS

Select

  1 - 'stop' PMS
  2 - 'automatic' database check, repair/optimize, and reindex in one step.
  3 - 'check' database
  4 - 'vacuum' database
  5 - 'repair' / 'optimize' database
  6 - 'reindex' database
  7 - 'start' PMS
  8 - 'import' viewstate (Watch history) from another PMS database
  9 - 'replace' current database with newest usable backup copy (interactive)
 10 - 'show' logfile
 11 - 'status' of PMS (Stop/Run and databases)
 12 - 'undo' - Undo last successful command
 99 -  exit

Enter command # -or- command name (4 char min) : stat


Status report: Sat Feb 25 04:38:50 PM EST 2023
  PMS is running.
  Databases are OK.


Select

  1 - 'stop' PMS
  2 - 'automatic' database check, repair/optimize, and reindex in one step.
  3 - 'check' database
  4 - 'vacuum' database
  5 - 'repair' / 'optimize' database
  6 - 'reindex' database
  7 - 'start' PMS
  8 - 'import' viewstate (Watch history) from another PMS database
  9 - 'replace' current database with newest usable backup copy (interactive)
 10 - 'show' logfile
 11 - 'status' of PMS (Stop/Run and databases)
 12 - 'undo' - Undo last successful command
 99 -  exit

Enter command # -or- command name (4 char min) : exit

Ok to remove temporary databases/workfiles for this session? (Y/N) ? y
Are you sure (Y/N) ? y
Deleting all temporary work files.
bash-4.4#

======================
V0.7 = Command line session
bash-4.4# ./DBRepair.sh status stop auto status start status exit



      Plex Media Server Database Repair Utility (Synology (DSM 7))
                       Version v1.0.0 - development


[16.40.11]
[16.40.11] Status report: Sat Feb 25 04:40:11 PM EST 2023
[16.40.11]   PMS is running.
[16.40.11]   Databases are not checked,  Status unknown.
[16.40.11]

[16.40.11] Stopping PMS.
[16.40.27] Stopped PMS.

[16.40.27]
[16.40.27] Checking the PMS databases
[16.42.23] Check complete.  PMS main database is OK.
[16.42.24] Check complete.  PMS blobs database is OK.
[16.42.24]
[16.42.24] Exporting current databases using timestamp: 2023-02-25_16.40.27
[16.42.24] Exporting Main DB
[16.43.13] Exporting Blobs DB
[16.43.39] Successfully exported the main and blobs databases.  Proceeding to import into new databases.
[16.43.39] Importing Main DB.
[16.46.09] Importing Blobs DB.
[16.46.10] Successfully imported data from SQL files.
[16.46.10] Verifying databases integrity after importing.
[16.46.58] Verification complete.  PMS main database is OK.
[16.46.58] Verification complete.  PMS blobs database is OK.
[16.46.58] Saving current databases with '-BKUP-2023-02-25_16.40.27'
[16.46.59] Making imported databases active
[16.46.59] Import complete. Please check your library settings and contents for completeness.
[16.46.59] Recommend:  Scan Files and Refresh all metadata for each library section.
[16.46.59]
[16.46.59] Backing up of databases
[16.46.59] Backup current databases with '-BKUP-2023-02-25_16.46.59' timestamp.
[16.47.03] Reindexing main database
[16.47.52] Reindexing main database successful.
[16.47.52] Reindexing blobs database
[16.47.52] Reindexing blobs database successful.
[16.47.52] Reindex complete.
[16.47.52] Automatic Check,Repair/optimize,Index successful.

[16.47.52]
[16.47.52] Status report: Sat Feb 25 04:47:52 PM EST 2023
[16.47.52]   PMS is stopped.
[16.47.52]   Databases are OK.
[16.47.52]

[16.47.52] Starting PMS.
[16.48.04] Started PMS

[16.48.04]
[16.48.04] Status report: Sat Feb 25 04:48:04 PM EST 2023
[16.48.05]   PMS is running.
[16.48.05]   Databases are OK.
[16.48.05]

bash-4.4#



======================
V0.7 = LOGFILE

2023-02-25 16.14.39 - ============================================================
2023-02-25 16.14.39 - Session start: Host is Synology (DSM 7)
2023-02-25 16.14.56 - StopPMS  - PASS
2023-02-25 16.16.06 - Check   - Check com.plexapp.plugins.library.db - PASS
2023-02-25 16.16.06 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.16.06 - Check   - PASS
2023-02-25 16.17.20 - Repair  - Export databases - PASS
2023-02-25 16.19.52 - Repair  - Import - PASS
2023-02-25 16.20.41 - Repair  - Verify main database - PASS (Size: 399MB/399MB).
2023-02-25 16.20.41 - Repair  - Verify blobs database - PASS (Size: 1MB/1MB).
2023-02-25 16.20.41 - Repair  - Move files - PASS
2023-02-25 16.20.41 - Repair  - PASS
2023-02-25 16.20.41 - Repair  - PASS
2023-02-25 16.20.46 - Reindex - MakeBackup com.plexapp.plugins.library.db - PASS
2023-02-25 16.20.46 - Reindex - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.20.46 - Reindex - MakeBackup - PASS
2023-02-25 16.21.34 - Reindex - Reindex: com.plexapp.plugins.library.db - PASS
2023-02-25 16.21.35 - Reindex - Reindex: com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.21.35 - Reindex - PASS
2023-02-25 16.21.35 - Reindex - PASS
2023-02-25 16.21.35 - Auto    - PASS
2023-02-25 16.38.35 - StartPMS  - PASS
2023-02-25 16.38.57 - Exit    - Delete temp files.
2023-02-25 16.38.58 - Session end.
2023-02-25 16.38.58 - ============================================================
2023-02-25 16.40.10 - ============================================================
2023-02-25 16.40.10 - Session start: Host is Synology (DSM 7)
2023-02-25 16.40.27 - StopPMS  - PASS
2023-02-25 16.42.23 - Check   - Check com.plexapp.plugins.library.db - PASS
2023-02-25 16.42.24 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.42.24 - Check   - PASS
2023-02-25 16.43.39 - Repair  - Export databases - PASS
2023-02-25 16.46.10 - Repair  - Import - PASS
2023-02-25 16.46.58 - Repair  - Verify main database - PASS (Size: 399MB/399MB).
2023-02-25 16.46.58 - Repair  - Verify blobs database - PASS (Size: 1MB/1MB).
2023-02-25 16.46.59 - Repair  - Move files - PASS
2023-02-25 16.46.59 - Repair  - PASS
2023-02-25 16.46.59 - Repair  - PASS
2023-02-25 16.47.03 - Reindex - MakeBackup com.plexapp.plugins.library.db - PASS
2023-02-25 16.47.03 - Reindex - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.47.03 - Reindex - MakeBackup - PASS
2023-02-25 16.47.52 - Reindex - Reindex: com.plexapp.plugins.library.db - PASS
2023-02-25 16.47.52 - Reindex - Reindex: com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.47.52 - Reindex - PASS
2023-02-25 16.47.52 - Reindex - PASS
2023-02-25 16.47.52 - Auto    - PASS
2023-02-25 16.48.04 - StartPMS  - PASS
2023-02-25 16.48.05 - Exit    - Delete temp files.
2023-02-25 16.48.05 - Session end.
