/*
-- Clean-up
EXEC master.dbo.xp_cmdshell 'DIR F:\ && DEL F:\TSQL_*.xel && DIR F:\';
*/
USE master;
GO

DROP EVENT SESSION TSQL_Batch_StartCmplt ON SERVER; 
GO
CREATE EVENT SESSION TSQL_Batch_StartCmplt ON SERVER
ADD EVENT sqlserver.sql_batch_completed (
	ACTION (sqlserver.database_id, sqlserver.database_name, sqlserver.sql_text)
	WHERE (sqlserver.database_name = N'AutoDealershipDemo')) ,
ADD EVENT sqlserver.sql_batch_starting (
	ACTION (sqlserver.database_id, sqlserver.database_name, sqlserver.sql_text)
	WHERE (sqlserver.database_name = N'AutoDealershipDemo'))
ADD TARGET package0.event_file (SET filename = N'F:\TSQL_Batch_StartCmplt',
								max_file_size = (250))
WITH (MAX_MEMORY = 4096 KB,
	  EVENT_RETENTION_MODE = NO_EVENT_LOSS,
	  MAX_DISPATCH_LATENCY = 2 SECONDS,
	  MAX_EVENT_SIZE = 0 KB,
	  MEMORY_PARTITION_MODE = NONE,
	  TRACK_CAUSALITY = OFF,
	  STARTUP_STATE = OFF);
GO

DROP EVENT SESSION TSQL_Stmt_Completed ON SERVER; 
GO
CREATE EVENT SESSION TSQL_Stmt_Completed ON SERVER
ADD EVENT sqlserver.sp_statement_completed (SET collect_statement = (1)
	ACTION (sqlserver.sql_text)
	WHERE (sqlserver.database_name = N'AutoDealershipDemo'))
ADD TARGET package0.event_file (SET filename = N'F:\TSQL_Stmt_Completed',
								max_file_size = (250))
WITH (MAX_MEMORY = 4096 KB,
	  EVENT_RETENTION_MODE = NO_EVENT_LOSS,
	  MAX_DISPATCH_LATENCY = 2 SECONDS,
	  MAX_EVENT_SIZE = 0 KB,
	  MEMORY_PARTITION_MODE = NONE,
	  TRACK_CAUSALITY = OFF,
	  STARTUP_STATE = OFF);
GO

