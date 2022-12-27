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

        1. Database is malformed
        2. Corruption
        3. Damaged indexes
        4. Database bloat after optimization
        5. Searching gets sluggish

## Functions provided

        1.  Check the databases
        2.  Vacuum the databases
        3.  Reindex the databases
        4.  Repair damaged databases
        5.  Restore databases from most recent backup
        6.  Import Viewstate / Watch history from another PMS database
        7.  Undo (undo last operation)
        8.  Show logfile of past actions and status

## Hosts currently supported

        1. Apple (MacOS)
        2. ASUSTOR
        3. Docker (Plex,inc, Linuxserver.io, & BinHex via 'docker exec')
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
    Linux (wkstn/svr)  | N/A                 |  Anywhere
    Netgear (ReadyNAS) | "your_choice"       |  "/data/your_choice"
    QNAP (QTS/QuTS)    | Public              |  /share/Public
    Synology (DSM 6)   | Plex                |  /volume1/Plex             (change volume as required)
    Synology (DSM 7)   | PlexMediaServer     |  /volume1/PlexMediaServer  (change volume as required)
    Western Digital    | Public              |  /mnt/HD/HD_a2/Public      (Does not support 'MyCloudHome' series)


```
###    To install & launch on general Linux or most Linux NAS platforms:  (Showing with v0.6.1)
        1. Open your browser to https://github.com/ChuckPa/PlexDBRepair/releases/latest
        2. Download the source code (tar.gz) file
        3. Place the tar.gz file in the appropriate directory on the system you'll use it.
        4. Open a command line session (usually Terminal or SSH)
        5. Elevate privilege level to root (sudo)
        6. Extract the utility from the tar or zip file
        7. 'cd' into the extraction directory
        8. Give the utility 'execute' permission
        9. Invoke the utility


###   To install & launch on Synology DSM 6 (Showing with v0.6.1)
```
        cd /volume1/Plex
        sudo bash
        tar xf PlexDBRepair-0.6.1.tar.gz
        cd PlexDBRepair-0.6.1
        chmod +x DBRepair.sh
        ./DBRepair.sh
```

###    To launch in a Docker container:
```
        sudo docker exec -it plex /bin/bash

        # Stop Plex when using official Plex,inc image
        /plex_service.sh -d
--or--
        # Stop Plex when using Linuxserver.io Plex image
        s6-svc -d /var/run/service/svc-plex
--or--
        # Stop Plex in binhex containers
        kill -15 $(pidof 'Plex Media Server')



        tar xf PlexDBRepair-0.6.1.tar.gz
        cd PlexDBRepair-0.6.1
        chmod +x DBRepair.sh
        ./DBRepair.sh
```
###    To launch from the command line
```
        sudo bash
        systemctl stop plexmediaserver
        cd /path/to/DBRepair.tar
        tar xf PlexDBRepair-0.6.1.tar.gz
        cd PlexDBRepair-0.6.1
        chmod +x DBRepair.sh
        ./DBRepair.sh
```

###    To launch in MacOS (on the administrator account)
```
        osascript -e 'quit app "Plex Media Server"'
        cd ~/Downloads
        tar xvf PlexDBRepai PlexDBRepair-0.6.1.tar.gz
        cd PlexDBRepai PlexDBRepair-0.6.1

        chmod +x DBRepair.sh
        ./DBRepair.sh
```


## The menu
  Plex Media Server Database Repair Utility

    Select

      1. Check database
      2. Vacuum database
      3. Reindex database
      4. Attempt database repair
      5. Replace current database with newest usable backup copy
      6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
      7. Import Viewstate / Watch history from another PMS database
      8. Show logfile
      9. Exit

Enter choice:

## Typical usage
```
This utility can only operate on PMS when PMS is in the stopped state.
If PMS is running when you startup the utility,  it will tell you.

 A. Database is malformed  (Backups of  com.plexapp.plugins.library.db and com.plexap.plugins.library.blobs.db  available)
    1. Check   - (Option 1) - Confirm either main or blobs database is damaged
    2. Replace - (Option 5) - Use the most recent valid backup -- OR -- Option 4 (Repair).  Check date/time for best action.
       -- If Replace fails, use Repair (Option 4)
       -- Replace can fail if the database has been damaged for a long time.
    3. Reindex - (Option 3) - Generate new indexes so PMS doesn't need to at startup
    4. Exit    - (Option 8)

 B. Database is malformed - No Backups
    1. Check   - (Option 1) - Confirm either main or blobs database is damaged
    2. Repair  - (Option 4) - Salavage as much as possible from the databases and rebuild them into a usable database.
    3. Reindex - (Option 3) - Generate new indexes so PMS doesn't need to at startup
    4. Exit    - (Option 8)

 C. Database sizes excessively large when compared to amount of media indexed (item count)
    1. Check   - (Option 1) - Make certain both databases are fully intact  (repair if needed)
    2. Vacuum  - (Option 2) - Instruct SQLite to rebuild its tables and recover unused space.
    3. Reinex  - (Option 3) - Rebuild Indexes.
    4. Exit    - (Option 8)

 D. User interface has become 'sluggish' as more media was added
    1. Check   - (Option 1) - Confirm there is no database damage
    2. Repair  - (Option 4) - You are not really repairing.  You are rebuilding the DB in perfect sorted order.
    3. Reindex - (Option 3) - Rebuild Indexes.
    4. Exit    - (Option 8)

 E. Undo
    Undo is a special case where you need the utility to backup ONE step.
    This is rarely needed.  The only time you might want/need to backup one step is if Replace leaves you worse off
    than you were before. In this case, UNDO then Repair.  Undo can only undo the single most-recent action.

Special considerations:

    1. As stated above, this utilty requires PMS to be stopped in order to do what it does.
    2. *TRICK* - This utility CAN sit at the menu prompt with PMS running.
       - You did a few things and want to check BEFORE exiting the utility
       - If you don't like how it worked out,
        -- STOP PMS
        -- UNDO the last action and do something else
        -- OR do more things to the databases
    3. When satisfied,  Exit the utility.
       - There is no harm in keeping the database temp files (except for space used)
       - ALL database temps are named with date-time stamps in the name to avoid confusion.
    4.The Logfile (Option 7) shows all actions performed WITH the timestamp so you can locate intermediate databases
      if desired for special / manual recovery cases.
```

## Scripting support

  Certain platforms don't provide for each command line access.
  To support those products,  this utility can be operated by adding command line arguments.

  Another use of this feature is to automate Plex Database maintenance
  ( Stop Plex,  Run this sequence,  Start Plex ) at a time when the server isn't busy


  The command line arguments are the same as if typing at the menu.

  Example:   ./DBRepair.sh  1 4 3 9

  This executes:   Check, Repair, Reindex, and Exit commands


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



      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 1

Checking the PMS databases
Check complete.  PMS main database is OK.
Check complete.  PMS blobs database is OK.


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 4

Exporting current databases using timestamp: 2022-11-16_15.56.06
Export: (main)..(blobs)..done.
Successfully exported the main and blobs databases.  Proceeding to import into new databases.
Import: (main)..(blobs)..done.
Successfully imported data from exported SQL files.
Verifying databases integrity after importing.
Verification complete.  PMS main database is OK.
Verification complete.  PMS blobs database is OK.
Saving current databases with '-ORIG-2022-11-16_15.56.06'
Making imported databases active
Import complete. Please check your library settings and contents for completeness.
Recommend:  Scan Files and Refresh all metadata for each library section.


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 3

Backing up of databases
Backup current databases with '-ORIG-2022-11-16_15.56.45'
Reindexing main database
Reindexing main database successful.
Reindexing blobs database
Reindexing blobs database successful.
Reindex complete.


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 8

==================================================================================
2022-11-16 12.32.00 - ============================================================
2022-11-16 12.32.00 - Session start: Host is Synology (DSM 7)
2022-11-16 13.27.03 - ============================================================
2022-11-16 13.27.03 - Session start: Host is Synology (DSM 7)
2022-11-16 13.27.03 - PMS running. Could not continue.
2022-11-16 13.28.16 - ============================================================
2022-11-16 13.28.16 - Session start: Host is Synology (DSM 7)
2022-11-16 13.29.15 - Repair  - Export databases - PASS
2022-11-16 13.29.16 - Repair  - Import - PASS
2022-11-16 13.29.16 - Repair  - Verify main database - PASS (Size: 1MB/1MB).
2022-11-16 13.29.16 - Repair  - Verify blobs database - PASS (Size: 1MB/1MB).
2022-11-16 13.29.16 - Repair  - Move files - PASS
2022-11-16 13.29.16 - Repair  - PASS
2022-11-16 13.32.45 - ============================================================
2022-11-16 13.32.45 - Session start: Host is Synology (DSM 7)
2022-11-16 13.33.26 - PMS running. Could not continue.
2022-11-16 13.36.34 - ============================================================
2022-11-16 13.36.34 - Session start: Host is Synology (DSM 7)
2022-11-16 13.36.34 - PMS running. Could not continue.
2022-11-16 13.36.55 - ============================================================
2022-11-16 13.36.55 - Session start: Host is Synology (DSM 7)
2022-11-16 13.37.10 - PMS running. Could not continue.
2022-11-16 13.41.34 - ============================================================
2022-11-16 13.41.34 - Session start: Host is Synology (DSM 7)
2022-11-16 13.41.34 - PMS running. Could not continue.
2022-11-16 13.41.57 - ============================================================
2022-11-16 13.41.57 - Session start: Host is Synology (DSM 7)
2022-11-16 13.42.06 - Check   - Check com.plexapp.plugins.library.db - PASS
2022-11-16 13.42.06 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 13.42.06 - Check   - PASS
2022-11-16 13.42.41 - PMS running. Could not continue.
2022-11-16 13.42.41 - PMS running. Could not continue.
2022-11-16 13.46.36 - PMS running. Could not continue.
2022-11-16 13.47.01 - ============================================================
2022-11-16 13.47.01 - Session start: Host is Synology (DSM 7)
2022-11-16 13.47.32 - PMS running. Could not continue.
2022-11-16 13.47.49 - PMS running. Could not continue.
2022-11-16 13.48.00 - Exit    - Delete temp files.
2022-11-16 13.48.00 - Session end.
2022-11-16 13.48.00 - ============================================================
2022-11-16 15.52.09 - PMS running. Could not continue.
2022-11-16 15.55.02 - PMS running. Could not continue.
2022-11-16 15.55.29 - ============================================================
2022-11-16 15.55.29 - Session start: Host is Synology (DSM 7)
2022-11-16 15.55.49 - Check   - Check com.plexapp.plugins.library.db - PASS
2022-11-16 15.55.50 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 15.55.50 - Check   - PASS
2022-11-16 15.56.11 - Repair  - Export databases - PASS
2022-11-16 15.56.20 - Repair  - Import - PASS
2022-11-16 15.56.22 - Repair  - Verify main database - PASS (Size: 23MB/22MB).
2022-11-16 15.56.22 - Repair  - Verify blobs database - PASS (Size: 1MB/1MB).
2022-11-16 15.56.22 - Repair  - Move files - PASS
2022-11-16 15.56.22 - Repair  - PASS
2022-11-16 15.56.45 - Reindex - MakeBackup com.plexapp.plugins.library.db - PASS
2022-11-16 15.56.45 - Reindex - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 15.56.45 - Reindex - MakeBackup - PASS
2022-11-16 15.56.47 - Reindex - Reindex: com.plexapp.plugins.library.db - PASS
2022-11-16 15.56.47 - Reindex - Reindex: com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 15.56.47 - Reindex - PASS
==================================================================================


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 7

Pathname of database containing watch history to import: /volume1/Plex/backup/com.plexapp.plugins.library.db
Backing up databases
Backup current databases with '-ORIG-2022-11-16_16.02.55'
Exporting Viewstate / Watch history
Making backup copy of main database
Importing Viewstate data
Checking database following import
Viewstate import successful.


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 1

Checking the PMS databases
Check complete.  PMS main database is OK.
Check complete.  PMS blobs database is OK.


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 2

Backing up databases
Backup current databases with '-ORIG-2022-11-16_16.05.37'
Vacuuming main database
Vacuuming main database successful (Size: 22MB/22MB).
Vacuuming blobs database
Vacuuming blobs database successful (Size: 1MB/1MB).
Vacuum complete.


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 3

Backing up of databases
Backup current databases with '-ORIG-2022-11-16_16.05.44'
Reindexing main database
Reindexing main database successful.
Reindexing blobs database
Reindexing blobs database successful.
Reindex complete.


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 8

==================================================================================
2022-11-16 12.32.00 - ============================================================
2022-11-16 12.32.00 - Session start: Host is Synology (DSM 7)
2022-11-16 13.27.03 - ============================================================
2022-11-16 13.27.03 - Session start: Host is Synology (DSM 7)
2022-11-16 13.27.03 - PMS running. Could not continue.
2022-11-16 13.28.16 - ============================================================
2022-11-16 13.28.16 - Session start: Host is Synology (DSM 7)
2022-11-16 13.29.15 - Repair  - Export databases - PASS
2022-11-16 13.29.16 - Repair  - Import - PASS
2022-11-16 13.29.16 - Repair  - Verify main database - PASS (Size: 1MB/1MB).
2022-11-16 13.29.16 - Repair  - Verify blobs database - PASS (Size: 1MB/1MB).
2022-11-16 13.29.16 - Repair  - Move files - PASS
2022-11-16 13.29.16 - Repair  - PASS
2022-11-16 13.32.45 - ============================================================
2022-11-16 13.32.45 - Session start: Host is Synology (DSM 7)
2022-11-16 13.33.26 - PMS running. Could not continue.
2022-11-16 13.36.34 - ============================================================
2022-11-16 13.36.34 - Session start: Host is Synology (DSM 7)
2022-11-16 13.36.34 - PMS running. Could not continue.
2022-11-16 13.36.55 - ============================================================
2022-11-16 13.36.55 - Session start: Host is Synology (DSM 7)
2022-11-16 13.37.10 - PMS running. Could not continue.
2022-11-16 13.41.34 - ============================================================
2022-11-16 13.41.34 - Session start: Host is Synology (DSM 7)
2022-11-16 13.41.34 - PMS running. Could not continue.
2022-11-16 13.41.57 - ============================================================
2022-11-16 13.41.57 - Session start: Host is Synology (DSM 7)
2022-11-16 13.42.06 - Check   - Check com.plexapp.plugins.library.db - PASS
2022-11-16 13.42.06 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 13.42.06 - Check   - PASS
2022-11-16 13.42.41 - PMS running. Could not continue.
2022-11-16 13.42.41 - PMS running. Could not continue.
2022-11-16 13.46.36 - PMS running. Could not continue.
2022-11-16 13.47.01 - ============================================================
2022-11-16 13.47.01 - Session start: Host is Synology (DSM 7)
2022-11-16 13.47.32 - PMS running. Could not continue.
2022-11-16 13.47.49 - PMS running. Could not continue.
2022-11-16 13.48.00 - Exit    - Delete temp files.
2022-11-16 13.48.00 - Session end.
2022-11-16 13.48.00 - ============================================================
2022-11-16 15.52.09 - PMS running. Could not continue.
2022-11-16 15.55.02 - PMS running. Could not continue.
2022-11-16 15.55.29 - ============================================================
2022-11-16 15.55.29 - Session start: Host is Synology (DSM 7)
2022-11-16 15.55.49 - Check   - Check com.plexapp.plugins.library.db - PASS
2022-11-16 15.55.50 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 15.55.50 - Check   - PASS
2022-11-16 15.56.11 - Repair  - Export databases - PASS
2022-11-16 15.56.20 - Repair  - Import - PASS
2022-11-16 15.56.22 - Repair  - Verify main database - PASS (Size: 23MB/22MB).
2022-11-16 15.56.22 - Repair  - Verify blobs database - PASS (Size: 1MB/1MB).
2022-11-16 15.56.22 - Repair  - Move files - PASS
2022-11-16 15.56.22 - Repair  - PASS
2022-11-16 15.56.45 - Reindex - MakeBackup com.plexapp.plugins.library.db - PASS
2022-11-16 15.56.45 - Reindex - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 15.56.45 - Reindex - MakeBackup - PASS
2022-11-16 15.56.47 - Reindex - Reindex: com.plexapp.plugins.library.db - PASS
2022-11-16 15.56.47 - Reindex - Reindex: com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 15.56.47 - Reindex - PASS
2022-11-16 16.03.16 - Import  - Attempting to import watch history from '/volume1/Plex/backup/com.plexapp.plugins.library.db'
2022-11-16 16.04.56 - Import  - MakeBackup com.plexapp.plugins.library.db - PASS
2022-11-16 16.04.56 - Import  - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 16.04.56 - Import  - MakeBackups - PASS
2022-11-16 16.04.59 - Import  - Import: /volume1/Plex/backup/com.plexapp.plugins.library.db - PASS
2022-11-16 16.05.34 - Check   - Check com.plexapp.plugins.library.db - PASS
2022-11-16 16.05.34 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 16.05.34 - Check   - PASS
2022-11-16 16.05.37 - Vacuum  - MakeBackup com.plexapp.plugins.library.db - PASS
2022-11-16 16.05.38 - Vacuum  - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 16.05.38 - Vacuum  - MakeBackups - PASS
2022-11-16 16.05.40 - Vacuum  - Vacuum main database - PASS (Size: 22MB/22MB).
2022-11-16 16.05.41 - Vacuum  - Vacuum blobs database - PASS (Size: 1MB/1MB).
2022-11-16 16.05.41 - Vacuum  - PASS
2022-11-16 16.05.44 - Reindex - MakeBackup com.plexapp.plugins.library.db - PASS
2022-11-16 16.05.44 - Reindex - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 16.05.44 - Reindex - MakeBackup - PASS
2022-11-16 16.05.46 - Reindex - Reindex: com.plexapp.plugins.library.db - PASS
2022-11-16 16.05.46 - Reindex - Reindex: com.plexapp.plugins.library.blobs.db - PASS
2022-11-16 16.05.46 - Reindex - PASS
==================================================================================


      Plex Media Server Database Repair Utility (Synology (DSM 7))

Select

  1. Check database
  2. Vacuum database
  3. Reindex database
  4. Attempt database repair
  5. Replace current database with newest usable backup copy
  6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
  7. Import Viewstate / Watch history from another PMS database
  8. Show logfile
  9. Exit

Enter choice: 9

Ok to remove temporary databases/workfiles for this session? (Y/N) ? y
Are you sure (Y/N) ? y
Deleting all temporary work files.
bash-4.4#
```
