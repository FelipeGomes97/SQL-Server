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
    INNER JOIN sysjobhistory h ON j.job_id = h.job_id
    WHERE j.name IN ('NomeDoJob1', 'NomeDoJob2'...)
    AND h.step_id IN (1, 2) 
)
 
SELECT @JobsFalhados = COALESCE(@JobsFalhados + ' | ', '') + 'Job: ' + job_name + ' (Step: ' + CAST(step_id AS VARCHAR) + ')'
FROM UltimaExecucaoPorStep
WHERE rn = 1 
  AND run_status IN (0, 2);
 
IF (@JobsFalhados IS NOT NULL)
BEGIN
    SET @ErrorMessage = FORMATMESSAGE('ERRO: Falha detectada nos itens: %s.', @JobsFalhados);
    RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT;
    THROW 51000, @ErrorMessage, 1;
END
ELSE
BEGIN
    PRINT 'Sucesso: Todos os steps monitorados terminaram com sucesso na última tentativa.';
END