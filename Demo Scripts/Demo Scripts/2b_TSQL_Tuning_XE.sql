/*
-- RESET PATH PER LOCAL MACHINE
-- IF NEW MACHINE, MUST ALSO CHOOSE COLUMNS ON EVENT_FILE OUTPUT
-- Set XE Event File to Display:
-- Name, Timestamp, SQL_Text, Statement, Duration, Logical Reads
-----
-- 
-- SELECT * FROM sys.configurations ORDER BY name
-- EXEC sp_configure 'show advanced options', 1
-- EXEC sp_configure 'xp_cmdshell', 1
-- RECONFIGURE
-----
-- Clean-up
-- EXEC master.dbo.xp_cmdshell 'DIR F:\ && DEL F:\TSQL_*.xel && DIR F:\';
-----
-- ROGUE
-- sudo ls -al /var/opt/mssql/XE/
-- sudo rm -f /var/opt/mssql/XE/TSQL_*.xel
*/
USE master;
GO

DROP EVENT SESSION [TSQL_Batch_StartStop] ON SERVER 
GO

CREATE EVENT SESSION [TSQL_Batch_StartStop] ON SERVER 
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.database_name,sqlserver.sql_text)
    WHERE ([sqlserver].[database_name]=N'AutoDealershipDemo')),
ADD EVENT sqlserver.sql_batch_starting(
    ACTION(sqlserver.database_name,sqlserver.sql_text)
    WHERE ([sqlserver].[database_name]=N'AutoDealershipDemo'))
ADD TARGET package0.event_file(SET filename=N'/var/opt/mssql/XE/TSQL_Batch_StartStop',max_file_size=(250))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=3 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO



DROP EVENT SESSION [TSQL_Statement_Completed] ON SERVER 
GO

CREATE EVENT SESSION [TSQL_Statement_Completed] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(SET collect_statement=(1)
    ACTION(sqlserver.database_name,sqlserver.sql_text)
    WHERE ([sqlserver].[database_name]=N'AutoDealershipDemo'))
ADD TARGET package0.event_file(SET filename=N'/var/opt/mssql/XE/TSQL_Statement_Completed',max_file_size=(250))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=3 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

