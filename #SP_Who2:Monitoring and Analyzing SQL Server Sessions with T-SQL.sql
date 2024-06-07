SELECT
    ss.session_id AS SessionID, -- Session ID
    original_login_name AS OriginalLoginName, -- Original login name
    sp.status AS Status, -- Session status
    blocking_session_id AS BlockedBySessionID, -- Blocking session ID
    command AS Command, -- Command being executed
    DB_NAME(sp.database_id) AS DatabaseName, -- Database name
    [objectid] AS ObjectID, -- Object ID
    sp.cpu_time AS CPUTime, -- CPU time consumed
    percent_complete AS PercentageComplete, -- Percentage of completion
    CASE
        WHEN DATEDIFF(mi, start_time, GETDATE()) > 60 THEN CONVERT(VARCHAR(4), (DATEDIFF(mi, start_time, GETDATE()) / 60)) + ' hr ' -- Calculating duration in hours if more than 60 minutes
        ELSE ''
    END +
    CASE
        WHEN DATEDIFF(ss, start_time, GETDATE()) > 60 THEN CONVERT(VARCHAR(4), (DATEDIFF(mi, start_time, GETDATE()) % 60)) + ' min ' -- Calculating duration in minutes if more than 60 seconds
        ELSE ''
    END +
    CONVERT(VARCHAR(4), (DATEDIFF(ss, start_time, GETDATE()) % 60)) + ' sec' AS Duration, -- Duration of the session
    estimated_completion_time / 60000 AS EstimatedCompletionTimeMin, -- Estimated completion time in minutes
    [text] AS InputStreamText, -- Input stream or text
    (SUBSTRING(
        [text],
        statement_start_offset / 2 + 1,
        (
            (CASE WHEN statement_end_offset < 0 THEN (LEN(CONVERT(nvarchar(max), [text])) * 2) ELSE statement_end_offset END) - statement_start_offset
        ) / 2 + 1
    )) AS ExecutingSQLStatement, -- Executing SQL statement
    wait_resource AS WaitResource, -- Resource being waited upon
    wait_time / 1000 AS WaitTimeSec, -- Wait time in seconds
    last_wait_type AS LastWaitType, -- Last wait type
    login_time AS LoginTime, -- Login time
    last_request_start_time AS LastRequestStartTime, -- Start time of the last request
    last_request_end_time AS LastRequestEndTime, -- End time of the last request
    host_name AS HostName, -- Host name
    CASE
        WHEN program_name LIKE 'SQLAgent%Job%' THEN (
            SELECT TOP 1 '(SQLAgent Job - ' + name + ' - ' + RIGHT(program_name, LEN(program_name) - CHARINDEX(':', program_name))
            FROM msdb.dbo.sysjobs SJ
            WHERE UPPER(master.dbo.fn_varbintohexstr(SJ.job_id)) = UPPER(SUBSTRING([program_name], 30, 34))
        )
        ELSE program_name
    END AS ProgramName, -- Program name, including SQL Agent job information
    sp.open_transaction_count AS OpenTransactionCount, -- Open transaction count
    CASE sp.transaction_isolation_level
        WHEN 0 THEN 'Unspecified'
        WHEN 1 THEN 'ReadUncommitted'
        WHEN 2 THEN 'ReadCommitted'
        WHEN 3 THEN 'Repeatable'
        WHEN 4 THEN 'Serializable'
        WHEN 5 THEN 'Snapshot'
    END AS TransactionIsolationLevel, -- Transaction isolation level
    sp.reads AS Reads, -- Number of reads
    sp.writes AS Writes, -- Number of writes
    sp.logical_reads AS LogicalReads, -- Number of logical reads
    sp.lock_timeout AS LockTimeout, -- Lock timeout
    sp.row_count AS TotalRows -- Total number of rows affected
FROM sys.dm_exec_requests AS sp
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS esql
RIGHT OUTER JOIN sys.dm_exec_sessions ss ON ss.session_id = sp.session_id
WHERE ss.status <> 'sleeping'
