USE msdb;
GO
 
DECLARE @ErrorMessage NVARCHAR(2048);
DECLARE @JobsFalhados NVARCHAR(MAX);
 
;WITH UltimaExecucaoPorStep AS (
    SELECT 
        j.name AS job_name,
        h.step_id,
        h.run_status,
        ROW_NUMBER() OVER (PARTITION BY j.job_id, h.step_id ORDER BY h.instance_id DESC) AS rn
    FROM sysjobs j
    INNER JOIN sysjobsteps s ON j.job_id = s.job_id
    INNER JOIN sysjobhistory h ON j.job_id = h.job_id AND s.step_id = h.step_id
    WHERE j.enabled = 1
)
 
SELECT @JobsFalhados = COALESCE(@JobsFalhados + CHAR(13) + CHAR(10), '') + 
       'Job: ' + job_name + ' | Step: ' + CAST(step_id AS VARCHAR(5)) + ' | Status: ' + 
       CASE run_status 
            WHEN 0 THEN 'Failed' 
            WHEN 2 THEN 'Retry' 
       END
FROM UltimaExecucaoPorStep
WHERE rn = 1 
  AND run_status IN (0);
 
IF (@JobsFalhados IS NOT NULL)
BEGIN
    SET @JobsFalhados = LEFT(@JobsFalhados, 1800);
    SET @ErrorMessage = 'Falha detectada nos jobs:' + CHAR(13) + @JobsFalhados;
    RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT;
	THROW 51000, @ErrorMessage, 1;
END
ELSE
BEGIN
    PRINT 'Sucesso: Todos os steps de todos os jobs finalizaram com sucesso na última tentativa.';
END
GO