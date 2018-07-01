# mssql-server-windows-developer
microsoft/mssql-server-windows-developer customized

see https://hub.docker.com/r/microsoft/mssql-server-windows-developer/

## Changes to upstream
* start.ps1: new JSON parameter restore_dbs like existing attach_dbs.
* Dockerfile: new ENV variable restore_dbs plus 2 volumes.

### Usage
* **restore_dbs** (optional parameter): The JSON-configuration for restoring custom DBs from DB backups. The following example shows an example:
```
[{
	'dbName': 'sample',
	'dbBakFile': 'sample_2018-06-28_14_32_27.910.bak',
	'dbLogins': [{
		'dbUser': 'sample',
		'dbLogin': 'sample',
		'dbLoginPw': 'sample'
	}],
	'dbFiles': [{
		'name': 'sample',
		'fileName': 'sample.mdf'
	},
	{
		'name': 'sample_log',
		'fileName': 'sample_log.mdf'
	}]
}]
```
The following example shows the parameter in action:
```
docker run -d -p 1433:1433 -e sa_password=<SA_PASSWORD> -e ACCEPT_EULA=Y -v C:/temp/:C:/temp/ -e restore_dbs="[{'dbName':'sample','dbBakFile':'sample_2018-06-28_14_32_27.910.bak','dbLogins':[{'dbUser':'sample','dbLogin':'sample','dbLoginPw':'sample'}],'dbFiles':[{'name':'sample','fileName':'sample.mdf'},{'name':'sample_log','fileName':'sample_log.mdf'}]}]"
```
**Info**:
* Overwrittes existing target files (.mdf and .ldf)!
* Does not overwritte existing DBs.
* Server logins are created if they don't exist and mapped to a DB-User.
