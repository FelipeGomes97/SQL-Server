USE msdb;

GO
 
DECLARE @ErrorMessage NVARCHAR(MAX);
 
;WITH UltimaExecucaoPorStep AS (

    SELECT 

        j.name AS NomeDoJob,

        h.step_id,

        h.run_status,

        ROW_NUMBER() OVER (PARTITION BY j.job_id, h.step_id ORDER BY h.instance_id DESC) AS rn

    FROM sysjobs j

    INNER JOIN sysjobhistory h ON j.job_id = h.job_id

    WHERE j.name IN ('Job 1', 'Job 2', 'Job 3') 

      AND h.step_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10) 

)
 
SELECT @ErrorMessage = STRING_AGG(

    CAST('-> Job: ' + NomeDoJob + ' | Step: ' + CAST(step_id AS VARCHAR) AS NVARCHAR(MAX)), 

    CHAR(13) + CHAR(10)

)

FROM UltimaExecucaoPorStep

WHERE rn = 1 

  AND run_status IN (0, 2);
 
IF (@ErrorMessage IS NOT NULL)

BEGIN

    SET @ErrorMessage = 'ERRO CRÍTICO: Falhas detectadas nas últimas execuções:' + CHAR(13) + CHAR(10) + @ErrorMessage;

    RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT;

END

ELSE

BEGIN

    PRINT 'Sucesso: Todos os steps monitorados terminaram com sucesso na última tentativa.';

END
 