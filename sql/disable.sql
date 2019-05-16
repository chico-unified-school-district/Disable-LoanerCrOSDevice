SELECT [DRI].[SR] AS SerialNumber
FROM (SELECT [STU].* FROM STU WHERE DEL = 0)
 STU RIGHT JOIN ((SELECT [DRA].* FROM DRA WHERE DEL = 0)
 DRA LEFT JOIN (SELECT [DRI].* FROM DRI WHERE DEL = 0)
 DRI ON [DRI].[RID] = [DRA].[RID] AND [DRI].[RIN] = [DRA].[RIN]) ON [STU].[ID] = [DRA].[ID]
WHERE
 DRA.RID = 2
 AND (NOT STU.TG > ' ') AND STU.SC IN ( 1,2,3,5,6,7,8,10,11,12,13,16,17,18,19,20,21,23,24,25,26,27,28 )
 AND DRA.RD IS NULL