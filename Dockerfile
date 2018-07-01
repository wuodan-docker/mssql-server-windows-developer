# escape=`

FROM microsoft/mssql-server-windows-developer

ENV restore_dbs=

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

CMD .\start -sa_password $env:sa_password -ACCEPT_EULA $env:ACCEPT_EULA -attach_dbs \"$env:attach_dbs\" -Verbose -restore_dbs \"$env:restore_dbs\"

RUN New-Item C:\db_data\data -ItemType Directory; `
	New-Item C:\db_data\backup -ItemType Directory;

COPY start.ps1 C:\

VOLUME C:\db_data\backup C:\db_data\data