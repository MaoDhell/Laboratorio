USE LabNanomateriales;
GO

CREATE OR ALTER VIEW vw_Costos_Proyectos
AS
SELECT 
    os.ID_Orden,
    os.Codigo_Orden,
    n.Nombre_Nanomaterial,
    n.Aplicacion,
    os.Fecha_Inicio,
    os.Fecha_Fin_Real,
    os.Costo_Total AS Costo_Total_Orden,
    (SELECT SUM(Costo_Parcial) FROM Orden_Reactivos WHERE ID_Orden = os.ID_Orden) AS Costo_Reactivos,
    (SELECT SUM(Costo_Mantenimiento) FROM Mantenimiento_Equipos WHERE ID_Equipo = os.ID_Equipo_Principal 
        AND Fecha_Mantenimiento BETWEEN os.Fecha_Inicio AND ISNULL(os.Fecha_Fin_Real, GETDATE())) AS Costo_Mantenimiento,
    cc.Rendimiento_Porcentaje,
    cc.Pureza_Porcentaje,
    CASE 
        WHEN cc.Rendimiento_Porcentaje > 90 THEN 'ALTA EFICIENCIA'
        WHEN cc.Rendimiento_Porcentaje > 75 THEN 'EFICIENCIA MEDIA'
        ELSE 'BAJA EFICIENCIA'
    END AS Evaluacion_Eficiencia
FROM Ordenes_Sintesis os
INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
LEFT JOIN Control_Calidad cc ON os.ID_Orden = cc.ID_Orden
WHERE os.Estado_Orden = 'Completada';
GO