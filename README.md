# Disable-LoanerCrOSDevice

Purpose

- Query Aeries (SIS/MSSQL) for Chromebooks flagged as loaners and disable those devices in Google Workspace using gam.exe.

Prerequisites

- Access to Aeries database (MSSQL) with read permissions for the Chromebooks table or view used by the query.
- gam.exe installed on the machine that will run the script and configured with a service account that has device management privileges.
- PowerShell (or the script runtime used by the repository).
- A secure place to store service account credentials (not checked into source control).

Files (overview)

- ...existing code...
- README.md — this file (usage and configuration).
- Script(s) to query Aeries and call gam.exe — see script header comments for runtime flags/options.

Configuration

1. Database connection

   - Provide a connection string or separate parameters (server, database, user, password) used by the script to query Aeries.
   - Use Windows Authentication when possible, or a dedicated SQL account with least privilege.

2. Query

   - Identify or confirm the SQL query used to select loaner Chromebooks (e.g., devices with a loaner flag).
   - Example (adapt to your schema):
     SELECT deviceid, serialnumber, asset_tag, student_id FROM Chromebooks WHERE loaner = 1;

3. GAM
   - Ensure gam.exe is on PATH or set GAM path in script configuration.
   - Service account must be delegated with Chrome device management scope.

Usage

- Dry run (safe): run the script in dry-run mode to see which devices would be disabled without calling gam.exe.
  Example:
  .\Disable-LoanerCrOSDevice.ps1 -SISServer SISServer -SISDatabase SISDB -SISCred SISCred -WhatIf

- Live run: run the script without DryRun to perform actions.
  Example:
  .\Disable-LoanerCrOSDevice.ps1 -SISServer SISServer -SISDatabase SISDB -SISCred SISCred

- Logging: enable or review logs produced by the script. The script should write:
  - Query results
  - Actions attempted
  - gam.exe stdout/stderr
  - Timestamps

Scheduling

- Use Task Scheduler or an automation server to run the script on a schedule (e.g., nightly).
- Run under a service account with appropriate permissions and a profile that can access gam.exe and network resources.

Security and Best Practices

- Do not store service account credentials in plaintext in the repo.
- Restrict SQL and Google admin accounts to least privilege.
- Test changes in a staging environment before running in production.
- Use dry-run mode when modifying query logic.

Troubleshooting

- No devices found: verify your SQL query and DB connection.
- gam.exe failures: run gam.exe manually with the same arguments to inspect errors and ensure the service account is valid.
- Permission errors: confirm the SQL account and GAM service account have required access.

Change Log

- Initial README created.

Contact

- Add internal contact info or ticket procedure for escalations.
