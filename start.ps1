# The script sets the sa password and start the SQL Service
# Also it attaches additional database from the disk
# The format for attach_dbs

param(
[Parameter(Mandatory=$false)]
[string]$sa_password,

[Parameter(Mandatory=$false)]
[string]$ACCEPT_EULA,

[Parameter(Mandatory=$false)]
[string]$attach_dbs,

[Parameter(Mandatory=$false)]
[string]$restore_dbs
)


if($ACCEPT_EULA -ne "Y" -And $ACCEPT_EULA -ne "y")
{
        Write-Verbose "ERROR: You must accept the End User License Agreement before this container can start."
        Write-Verbose "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."

    exit 1
}

# start the service
Write-Verbose "Starting SQL Server"
start-service MSSQLSERVER

if($sa_password -eq "_") {
    if (Test-Path $env:sa_password_path) {
        $sa_password = Get-Content -Raw $secretPath
    }
    else {
        Write-Verbose "WARN: Using default SA password, secret file not found at: $secretPath"
    }
}

if($sa_password -ne "_")
{
    Write-Verbose "Changing SA login credentials"
    $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $sa_password + "'" + ";ALTER LOGIN sa ENABLE;"
    & sqlcmd -Q $sqlcmd
}

$attach_dbs_cleaned = $attach_dbs.TrimStart('\\').TrimEnd('\\')

$dbs = $attach_dbs_cleaned | ConvertFrom-Json

if ($null -ne $dbs -And $dbs.Length -gt 0)
{
    Write-Verbose "Attaching $($dbs.Length) database(s)"

    Foreach($db in $dbs)
    {
        $files = @();
        Foreach($file in $db.dbFiles)
        {
            $files += "(FILENAME = N'$($file)')";
        }

        $files = $files -join ","
        $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '" + $($db.dbName) + "') BEGIN EXEC sp_detach_db [$($db.dbName)] END;CREATE DATABASE [$($db.dbName)] ON $($files) FOR ATTACH;"

        Write-Verbose "Invoke-Sqlcmd -Query $($sqlcmd)"
        & sqlcmd -Q $sqlcmd
        }
}

$restore_dbs_cleaned = $restore_dbs.TrimStart('\\').TrimEnd('\\')

$dbs = $restore_dbs_cleaned | ConvertFrom-Json

if ($null -ne $dbs -And $dbs.Length -gt 0)
{
    Write-Verbose "Restoring $($dbs.Length) database(s)"

    Foreach($db in $dbs)
    {
        $files = @();
        Foreach($file in $db.dbFiles)
        {
            $files += "MOVE '$($file.name)' TO 'C:\db_data\data\$($file.fileName)'";
        }

        $files = $files -join ","
        $sqlcmd = "IF NOT EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '" + $($db.dbName) + "') BEGIN RESTORE DATABASE [$($db.dbName)] FROM DISK = 'C:\db_data\backup\" + $($db.dbBakFile) + "' WITH REPLACE,$($files) END;"
		
        Write-Verbose "Invoke-Sqlcmd -Query $($sqlcmd)"
        & sqlcmd -Q $sqlcmd
		
        $logins = @();
        Foreach($login in $db.dbLogins)
        {
            $logins += "if not exists(select * from sys.server_principals where name = '" + $($login.dbLogin) + "') begin; CREATE LOGIN $($login.dbLogin) WITH PASSWORD=N'" + $($login.dbLoginPw) + "', DEFAULT_DATABASE=[$($db.dbName)], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF; end";
        }

        $logins = $logins -join ";"
		$sqlcmd = "USE [$($db.dbName)];$($logins)"
		
        Write-Verbose "Invoke-Sqlcmd -Query $($sqlcmd)"
        & sqlcmd -Q $sqlcmd
		
        $logins = @();
        Foreach($login in $db.dbLogins)
        {
            $logins += "alter user $($login.dbUser) with login = $($login.dbLogin)";
        }
		
        $logins = $logins -join ";"
		$sqlcmd = "USE [$($db.dbName)];$($logins)"
		
        Write-Verbose "Invoke-Sqlcmd -Query $($sqlcmd)"
        & sqlcmd -Q $sqlcmd
        }
}

Write-Verbose "Started SQL Server."

$lastCheck = (Get-Date).AddSeconds(-2)
while ($true)
{
    Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message
    $lastCheck = Get-Date
    Start-Sleep -Seconds 2
}