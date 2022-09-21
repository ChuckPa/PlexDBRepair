# PlexDBRepair

## Introduction

DBRepair provides database repair and maintenance for the most common  Plex Media Server database problems.

It is a simple,  command line oriented,  menu-driven utility.
## Situations and errors commonly seen include:

        1. Database is malformed
        2. Corruption
        3. Damaged indexes
        4. Database bloat after optimization

## Functions provided

        1.  Check the databases
        2.  Vacuum the databases
        3.  Reindex the databases
        4.  Repair damaged databases
        5.  Restore databases from most recent backup
        6.  Undo (undo last operation)
        7.  Show logfile of past actions and status

## Hosts currently supported

        1. ASUSTOR
        2. Netgear (OS5 Linux-based systems)
        3. Linux workstation & server
        4. QNAP (QTS & QuTS)
        5. Synology (DSM 6 & DSM 7)

 ## The menu

  Plex Media Server Database Repair Utility


    Select

      1. Check database
      2. Vacuum database
      3. Reindex database
      4. Attempt database repair
      5. Replace current database with newest usable backup copy
      6. Undo last successful action (Vacuum, Reindex, Repair, or Replace)
      7. Show logfile
      8. Exit

Enter choice:

## Exiting

  When exiting,  you will be asked whether to keep the interim temp files created during this session.
  If you've encountered any difficulties or aren't sure what to do,  don't delete them.
  You'll be able to ask in the Plex forums about what to do.  Be prepared to present the log file to them.


