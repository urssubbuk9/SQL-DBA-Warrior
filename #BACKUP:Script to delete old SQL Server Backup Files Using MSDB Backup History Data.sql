Problem
The requirement is to delete old SQL Server backup files that may still exist on disk. This will be done by reading the backup history data from the msdb SQL Server database so we don't need to search multiple directories, but use the history data to determine where the backups were created.

Solution
My solution involves creating a stored procedure in the SQL Server master database called dbo.usp_DeleteOldBackupFiles.

The procedure takes two parameters:

@DaysOld: An integer number used to calculate the date used to decide from when to delete the backup files. All backup files created before (current Date - @DaysOld) are selected for deletion.
@mode: The procedure's action modes are 'R' – for reporting files names and 'D' for reporting and deleting the files.
The procedure joins the msdb.dbo.backupmediafamily and msdb.dbo.backupset tables and lists only the files where the backup starting date is earlier than (current Date - @DaysOld).

The procedure loops over all the found files and checks if the file actually exists by executing master.dbo.xp_fileexist.  If the file exists, the procedure checks the @mode parameter: if @mode=R it only reports the file and if the @mode=D it also deletes the file by using the Ole Automation Procedure sp_OAMethod in a 'DeleteFile' mode.

Preliminary Requirement
The 'Ole Automation Procedures' should be set in order to successfully delete the old backup files by using this procedure.  Use the following script to set this option (sysadmin role required). The script ensures that the 'Ole Automation procedures' option is enabled by using the sp_configure system stored procedure.

USE master
GO
-- enable show advanced options
exec sp_configure 'show advanced options', 1
go
RECONFIGURE
GO
-- enable Ole Automation Procedures
exec sp_configure 'Ole Automation Procedures', 1
GO
RECONFIGURE
GO
SQL Server Stored Procedure to Delete Old Backup Files
Create the stored procedure in the master database.

USE master
GO

-- =================================================================================
-- Author:         Eli Leiba
-- Create date:    2018-09
-- Procedure Name: dbo.usp_DeleteOldBackupFiles
-- Description:
--   The procedure looks over the backup history table in the MSDB database:
--   And searches for backup files older than @DaysOld days before 
--   The current procedure Execution date. 
--   If the @mode parameter = R, it only reports the file names and
--   If the @mode parameter = D it reports and deletes the files. 
-- ==================================================================================
CREATE PROCEDURE dbo.usp_DeleteOldBackupFiles (@DaysOld INT, @mode CHAR (1))
AS
BEGIN
   DECLARE @dbName SYSNAME
   DECLARE @SD DATETIME
   DECLARE @FD DATETIME
   DECLARE @filename VARCHAR (255)
   DECLARE @msg VARCHAR (300)
   DECLARE @fileExists INT
   DECLARE @Filehandle INT

   SET NOCOUNT ON

   DECLARE c_fileList CURSOR
   FOR
   SELECT b.database_name,
      b.backup_start_date,
      b.backup_finish_date,
      a.physical_device_name
   FROM msdb.dbo.backupmediafamily a,
      msdb.dbo.backupset b
   WHERE a.media_set_id = b.media_set_id AND 
      (CONVERT (DATETIME, b.backup_start_date, 102) < GETDATE () - @DaysOld) 
   ORDER BY b.database_name, b.backup_finish_date;
				
   -- create a file system object
   EXEC sp_OACreate 'Scripting.FileSystemObject', @Filehandle OUTPUT
   
   -- open working cursor and loop over all rows.
   OPEN c_fileList;
				
   FETCH NEXT  FROM c_fileList INTO @dbName, @SD, @FD, @filename
   WHILE @@FETCH_STATUS = 0
   BEGIN
      EXEC Master.dbo.xp_fileexist @filename, @fileExists OUT
      IF @fileExists = 1
      BEGIN
         SET @msg = CONCAT (
            'Delete backup file: '
            @filename,
            'For Database: '
            @dbName,
            'Started on: '
            Convert (VARCHAR (12), @sd, 103),
            'Finished on: '
            Convert (VARCHAR (12), @fd, 103)
            )
				
            IF (UPPER (@mode) IN ('R','D'))
            BEGIN
               PRINT @msg
            END
				
            -- If mode = D then delete the file 
            IF (UPPER (@mode) = 'D')
	   BEGIN
	      EXEC sp_OAMethod @Filehandle, 'DeleteFile', NULL, @filename
	   END
      END

      FETCH NEXT FROM c_fileList INTO @dbName, @sd, @fd, @filename
   END
   CLOSE c_fileList;
   DEALLOCATE c_fileList;
				
   -- Memory cleanup
   EXEC sp_OADestroy @Filehandle
   SET NOCOUNT OFF
END
GO			
Sample Execution
Report all backup files 700 or more days older than the present day.

USE master
GO
EXEC dbo.usp_DeleteOldBackupFiles @DaysOld=700, @mode = 'R'
GO
And the results are (on my server):

backup file report
Delete backup files 700 or more days older than the present day.

USE master
GO
EXEC dbo.usp_DeleteOldBackupFiles @DaysOld=700, @mode = 'D'
GO
The result is same report as the report above and the files are deleted as well.
