USE LabNanomateriales;
GO

CREATE OR ALTER VIEW vw_Produccion_Mensual
AS
SELECT 
    n.Tipo_Nanomaterial,
    COUNT(os.ID_Orden) AS Ordenes_Completadas,
    SUM(ln.Cantidad_Producida) AS Cantidad_Producida,
    AVG(cc.Rendimiento_Porcentaje) AS Rendimiento_Promedio,
    AVG(cc.Pureza_Porcentaje) AS Pureza_Promedio,
    SUM(os.Costo_Total) AS Costo_Total,
    CASE 
        WHEN SUM(ln.Cantidad_Producida) > 0 
        THEN SUM(os.Costo_Total) / SUM(ln.Cantidad_Producida)
        ELSE 0 
    END AS Costo_Por_Gramo
FROM Ordenes_Sintesis os
INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
INNER JOIN Lotes_Nanomateriales ln ON os.ID_Orden = ln.ID_Orden
INNER JOIN Control_Calidad cc ON os.ID_Orden = cc.ID_Orden
WHERE os.Estado_Orden = 'Completada'
    AND MONTH(os.Fecha_Fin_Real) = MONTH(GETDATE())
    AND YEAR(os.Fecha_Fin_Real) = YEAR(GETDATE())
GROUP BY n.Tipo_Nanomaterial;
GO
