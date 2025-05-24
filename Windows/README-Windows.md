# DBRepair-Windows

DBRepair-Windows.ps1 (and DBRepair-Windows.bat) are scripts run from the command line, which have
sufficient privilege to read/write the Plex databases in the
[Plex data directory](https://support.plex.tv/articles/202915258-where-is-the-plex-media-server-data-directory-located/).

## DBRepair-Windows.ps1 vs. DBRepair-Windows.bat

Currently, there are two separate Windows scripts, a batch script (.bat) and a PowerShell script
(.ps1). The batch script is a one-shot, zero-input script that attempts automatic database
maintenance (repair/rebuild, check, and reindex). The PowerShell script is intended to align with
DBRepair.sh, offering command-name-based functionality that can either be scripted or
interactive.

In the future, DBRepair-Windows.bat will be removed in favor of DBRepair-Windows.ps1. The batch
file is currently kept as a backup while the PowerShell script continues to be expanded and
tested. If any unexpected issues arise with the PowerShell script, please open an
[issue](https://github.com/ChuckPa/DBRepair/issues) so it can be investigated.

## Functions provided

The Windows utility aims to provide a similar interface to DBRepair.sh as outlined in the main
[README file](README.md), but currently only offers a subset of its functionality. For a full
description of the features below, consult that main README file.

The following commands (or their number) are currently supported on Windows.

```
AUTO(matic)
EXIT
PRUN(e)
STAR(t)
STOP
```

Run `.\DBRepair-Windows.ps1 -Help` for more complete documentation.

# Installation and usage instructions

DBRepair-Windows can be downloaded to any location. However, the PowerShell script might require
some prerequisite work in order to run as expected. By default, PowerShell scripts are blocked on
Windows machines, so in order to run DBRepair-Windows.ps1, you may need to do one of the following:

1. From an administrator PowerShell prompt, run `Set-ExecutionPolicy RemoteSigned`, then run the
  script from a normal PowerShell prompt. If PowerShell still will not run the script, you can do
  one of the following:
    * In Windows Explorer, right-click DBRepair-Windows.ps1, select Properties, and check 'Unblock'
      at the bottom of the dialog.
    * In PowerShell, run `Unblock-File <path\to\DBRepair-Windows.ps1>`
    * Run `Set-ExecutionPolicy Unrestricted` - this may result in an "are you sure" prompt before
      running the script. `Set-ExecutionPolicy Bypass` will get around this, but is not recommended,
      as it allows _any_ downloaded script to run without notification, not just DBRepair.
2. Explicitly set the `ExecutionPolicy` when running the script, e.g.:
   ```powershell
   powershell -ExecutionPolicy Bypass ".\DBRepair-Windows.ps1 stop auto start"
   ```
   Note that this method may not work if your machine is managed with Group Policy, which
   can block manual `ExecutionPolicy` overrides.

3. Similar to 2, but make it a batch script (e.g. `DBRepair.bat`) that lives alongside
   the powershell script:
    ```batch
    @echo off
    powershell -ExecutionPolicy Bypass -Command ".\DBRepair-Windows.ps1 %*"
    ```
    Then run that script directly:
    ```batch
    .\DBRepair.bat stop auto start
    ```

Also note that the PowerShell script cannot be run directly from a Command Prompt window.
If you are running this from Command Prompt, you must launch it via PowerShell:

```cmd
powershell .\DBRepair-Windows.ps1 [args]
```
