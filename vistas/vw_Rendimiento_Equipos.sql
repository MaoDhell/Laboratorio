USE LabNanomateriales;
GO

CREATE OR ALTER VIEW vw_Rendimiento_Equipos
AS
SELECT 
    eq.Nombre_Equipo,
    eq.Tipo_Equipo,
    COUNT(os.ID_Orden) AS Ordenes_Procesadas,
    AVG(DATEDIFF(HOUR, os.Fecha_Inicio, os.Fecha_Fin_Real)) AS Tiempo_Promedio_Horas,
    AVG(cc.Rendimiento_Porcentaje) AS Rendimiento_Promedio,
    SUM(me.Costo_Mantenimiento) AS Costo_Mantenimiento_Total,
    eq.Estado_Equipo,
    DATEDIFF(DAY, me.Fecha_Mantenimiento, GETDATE()) AS Dias_Desde_Ultimo_Mantenimiento
FROM Equipamiento eq
LEFT JOIN Ordenes_Sintesis os ON eq.ID_Equipo = os.ID_Equipo_Principal
LEFT JOIN Control_Calidad cc ON os.ID_Orden = cc.ID_Orden
LEFT JOIN Mantenimiento_Equipos me ON eq.ID_Equipo = me.ID_Equipo
GROUP BY 
    eq.ID_Equipo, eq.Nombre_Equipo, eq.Tipo_Equipo, eq.Estado_Equipo, 
    me.Fecha_Mantenimiento;
GO