/*
Problem
One of the junior SQL Server Database Administrators in my company approached me yesterday with a dilemma. He was restoring a large database on a Failover Cluster Production Server and while the
restore was in progress, due to network failure, the restore failed. Once the SQL Server came up on the other node all the databases came up, except for the database which he was restoring prior 
to the failover. In this tip we will take a look at the command RESTORE DATABASE...WITH RESTART to see how this command can be helpful during such scenarios.
*/
-- get backup information from backup file
RESTORE FILELISTONLY
FROM DISK ='C:\DBBackups\ProductDB.bak'
GO
-- restore the database
RESTORE DATABASE ProductDB
FROM DISK ='C:\DBBackups\ProductDB.bak'
WITH RESTART
GO
