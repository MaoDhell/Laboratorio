

USE LabNanomateriales;
GO

-- Obtener órdenes con rendimiento inferior al 75%

SELECT
    os.ID_Orden,
    os.Codigo_Orden,
    n.Nombre_Nanomaterial,
    n.Tipo_Nanomaterial,
    e.PrimerNombre + ' ' + e.PrimerApellido AS Responsable,
    os.Fecha_Inicio,
    os.Fecha_Fin_Real,
    DATEDIFF(HOUR, os.Fecha_Inicio, os.Fecha_Fin_Real) AS Duracion_Horas,
    cc.Rendimiento_Porcentaje,
    cc.Pureza_Porcentaje,
    cc.Resultado_Evaluacion,
    cc.Observaciones_Calidad,
    pp.Temperatura_Celsius,
    pp.Presion_Atmosferas,
    pp.pH_Solucion,
    pp.Duracion_Minutos,
    os.Estado_Orden
FROM Ordenes_Sintesis os
INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
INNER JOIN Empleados e ON os.ID_Empleado_Responsable = e.ID_Empleado
INNER JOIN Control_Calidad cc ON os.ID_Orden = cc.ID_Orden
LEFT JOIN Parametros_Proceso pp ON os.ID_Orden = pp.ID_Orden
WHERE cc.Rendimiento_Porcentaje < 75
    OR cc.Resultado_Evaluacion IN ('Rechazado', 'Requiere Re-análisis')
ORDER BY cc.Rendimiento_Porcentaje ASC;
