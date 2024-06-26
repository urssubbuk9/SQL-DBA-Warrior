USE ReadingDBLog
GO
WITH CTE
as
       (SELECT [Transaction ID], count(*) as DeletedRows
       FROM fn_dump_dblog (NULL, NULL, N'DISK', 1, N'D:\ReadingDBLog_201503022236.trn',
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)
       WHERE Operation = ('LOP_DELETE_ROWS')
       AND [PartitionId] = (SELECT sp.partition_id
                            FROM sys.objects so
                            INNER JOIN sys.partitions sp on so.object_id = sp.object_id
                            WHERE name = 'Location')
       GROUP BY [Transaction ID]
       )
SELECT [Current LSN], a.[Transaction ID], [Transaction Name], [Operation], [Begin Time], SUSER_SNAME([TRANSACTION SID]) as LoginName, DeletedRows
FROM fn_dump_dblog (NULL, NULL, N'DISK', 1, N'D:\ReadingDBLog_201503022236.trn',
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT) as a
INNER JOIN cte on a.[Transaction ID] = cte.[Transaction ID]
WHERE Operation = ('LOP_BEGIN_XACT')

--https://www.mssqltips.com/sqlservertip/3555/read-sql-server-transaction-log-backups-to-find-when-transactions-occurred/
