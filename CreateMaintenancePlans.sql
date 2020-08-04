/*
	Данный T-SQL сценарий предназанчен для создания планов обслуживания
	по заданной в параметрах базе данных, размещаемой на текущем сервере
	или с реплицируемыми таблицами на нескольких.

	После выполнения будут созданы планы обслуживания:
		- обновления статистики таблиц;
		- дефрагментации индексов;
		- реиндексации таблиц.

	Разработчик: Александр Гелета <mycatshoegazer@outlook.com>
*/

USE [msdb];		-- не трогать!
GO

/*
	Перед созданием планов обслуживания необходимо
	разрешить из выполнение, что мы и делаем. Активируем
	расширенные возможности хранение процедур и включаем
	агент XPs.
*/
DECLARE @_advanced_ops AS sql_variant;
SELECT @_advanced_ops = value FROM sys.configurations WHERE name = 'show advanced options'
IF (@_advanced_ops <> 1)
BEGIN
	EXEC sp_configure 'show advanced options', 1
	RECONFIGURE
END

DECLARE @_xps_enable AS sql_variant;
SELECT @_xps_enable = value FROM sys.configurations WHERE name = 'Agent XPs'
IF (@_xps_enable <> 1)
BEGIN
	EXEC sp_configure 'Agent XPs', 1
	RECONFIGURE
END
/*===========================================================================*/

/*
	Ввиду того, что далее будет вызываться большое количество
	блоков кода, будет удобным использовать временную таблицу
	для хранения значений параметров планов обслуживания.
*/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '_variables' and xtype = 'U')
	DROP TABLE _variables
GO

CREATE TABLE _variables (
	variable VARCHAR(40) PRIMARY KEY,
	value VARCHAR(255)
)
GO

INSERT INTO _variables (variable, value) VALUES
	('dbName', 'AdventureWorks2014')	-- имя базы данных
GO
/*===========================================================================*/

/*
	Создание плана обслуживания для обновления статистики
	таблиц по выбранной базе данных.
	Внимание: следующий блок кода не рекоммендуется изменять во избежании
	возникновения непредвиденных ошибок в работе СУБД, что может повлечь за
	собой нарушение целостности или утрату данных.
*/

DECLARE @_dbName AS VARCHAR(40) = (SELECT value FROM _variables WHERE variable = 'dbName')
DECLARE @_job_name AS VARCHAR(40) = @_dbName + '_stats_update';

DECLARE @_job_id BINARY(16);
SELECT @_job_id = job_id FROM msdb.dbo.sysjobs WHERE name = @_job_name
IF (@_job_id IS NOT NULL)
BEGIN
	EXEC dbo.sp_delete_job
		@job_id = @_job_id;
END

EXEC dbo.sp_add_job
	@job_name = @_job_name,
	@enabled = 1,
	@description = N'Updates all table statistics.';

EXEC dbo.sp_add_jobserver
	@job_name = @_job_name;

DECLARE @_command AS NVARCHAR(MAX) =
	N'USE [' + @_dbName + '];' +
	'EXEC sp_msforeachtable N''UPDATE STATISTICS ? WITH FULLSCAN'';' +
	'DBCC FREEPROCCACHE'

EXEC dbo.sp_add_jobstep
	@job_name = @_job_name,
	@step_name = N'Update all stats for each table in associated database.',
	@subsystem = N'TSQL',
	@command = @_command,
	@database_name = @_dbName,
	@retry_attempts = 5,
	@retry_interval = 5;

DECLARE @_schedule_name AS VARCHAR(80) = @_job_name + '_schedule';
DECLARE @_schedule_id AS INT;
SELECT @_schedule_id = schedule_id FROM sysschedules WHERE name = @_schedule_name
IF (@_schedule_id IS NOT NULL)
BEGIN
	EXEC dbo.sp_delete_schedule
		@schedule_id = @_schedule_id;
END

EXEC dbo.sp_add_schedule
	@schedule_name = @_schedule_name,
	@freq_type = 4,
	@freq_interval = 1,
	@active_start_time = 233000;

EXEC sp_attach_schedule
	@job_name = @_job_name,
	@schedule_name = @_schedule_name;

GO
/*===========================================================================*/

/*
	Создание плана обслуживания для дефрагментации
	таблиц по выбранной базе данных.
	Внимание: следующий блок кода не рекоммендуется изменять во избежании
	возникновения непредвиденных ошибок в работе СУБД, что может повлечь за
	собой нарушение целостности или утрату данных.
*/
DECLARE @_dbName AS VARCHAR(40) = (SELECT value FROM _variables WHERE variable = 'dbName')
DECLARE @_job_name AS VARCHAR(40) = @_dbName + '_index_defrag';

DECLARE @_job_id BINARY(16);
SELECT @_job_id = job_id FROM msdb.dbo.sysjobs WHERE name = @_job_name
IF (@_job_id IS NOT NULL)
BEGIN
	EXEC dbo.sp_delete_job
		@job_id = @_job_id;
END

EXEC dbo.sp_add_job
	@job_name = @_job_name,
	@enabled = 1,
	@description = N'Permorms defragmentation of all indexes in target database.';

EXEC dbo.sp_add_jobserver
	@job_name = @_job_name;

DECLARE @_command AS NVARCHAR(MAX) =
	N'USE [' + @_dbName + '];' +
	FORMATMESSAGE('EXEC sp_msforeachtable N''DBCC INDEXDEFRAG (%s, ''''?'''')''', @_dbName)

EXEC dbo.sp_add_jobstep
	@job_name = @_job_name,
	@step_name = N'Perform defragmentation of all indexes in target database for each table.',
	@subsystem = N'TSQL',
	@command = @_command,
	@database_name = @_dbName,
	@retry_attempts = 5,
	@retry_interval = 5;

DECLARE @_schedule_name AS VARCHAR(80) = @_job_name + '_schedule';
DECLARE @_schedule_id AS INT;
SELECT @_schedule_id = schedule_id FROM sysschedules WHERE name = @_schedule_name
IF (@_schedule_id IS NOT NULL)
BEGIN
	EXEC dbo.sp_delete_schedule
		@schedule_id = @_schedule_id;
END

EXEC dbo.sp_add_schedule
	@schedule_name = @_schedule_name,
	@freq_type = 4,
	@freq_interval = 1,
	@active_start_time = 210000;

EXEC sp_attach_schedule
	@job_name = @_job_name,
	@schedule_name = @_schedule_name;

GO
/*===========================================================================*/

/*
	Создание плана обслуживания для реиндексации
	таблиц по выбранной базе данных.
	Внимание: следующий блок кода не рекоммендуется изменять во избежании
	возникновения непредвиденных ошибок в работе СУБД, что может повлечь за
	собой нарушение целостности или утрату данных.
*/
DECLARE @_dbName AS VARCHAR(40) = (SELECT value FROM _variables WHERE variable = 'dbName')
DECLARE @_job_name AS VARCHAR(40) = @_dbName + '_table_reindex';

DECLARE @_job_id BINARY(16);
SELECT @_job_id = job_id FROM msdb.dbo.sysjobs WHERE name = @_job_name
IF (@_job_id IS NOT NULL)
BEGIN
	EXEC dbo.sp_delete_job
		@job_id = @_job_id;
END

EXEC dbo.sp_add_job
	@job_name = @_job_name,
	@enabled = 1,
	@description = N'Recreates all indexes in target database.';

EXEC dbo.sp_add_jobserver
	@job_name = @_job_name;

DECLARE @_command AS NVARCHAR(MAX) =
	N'USE [' + @_dbName + '];' +
	'EXEC sp_msforeachtable N''DBCC DBREINDEX (''''?'''')'''

EXEC dbo.sp_add_jobstep
	@job_name = @_job_name,
	@step_name = N'Perform reindexing of all tables in target database.',
	@subsystem = N'TSQL',
	@command = @_command,
	@database_name = @_dbName,
	@retry_attempts = 5,
	@retry_interval = 5;

DECLARE @_schedule_name AS VARCHAR(80) = @_job_name + '_schedule';
DECLARE @_schedule_id AS INT;
SELECT @_schedule_id = schedule_id FROM sysschedules WHERE name = @_schedule_name
IF (@_schedule_id IS NOT NULL)
BEGIN
	EXEC dbo.sp_delete_schedule
		@schedule_id = @_schedule_id;
END

EXEC dbo.sp_add_schedule
	@schedule_name = @_schedule_name,
	@freq_type = 4,
	@freq_interval = 1,
	@active_start_time = 224500;

EXEC sp_attach_schedule
	@job_name = @_job_name,
	@schedule_name = @_schedule_name;

GO
/*===========================================================================*/

/*
	Удаляем временную таблицу с переменными по причине того,
	что его содержимое нужно только в контексте выполнения
	данного сценария.
*/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '_variables' and xtype = 'U')
	DROP TABLE _variables
GO