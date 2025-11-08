USE LabNanomateriales;
GO


CREATE OR ALTER VIEW vw_Trazabilidad_Completa
AS
SELECT 
    os.Codigo_Orden,
    n.Nombre_Nanomaterial,
    ln.Codigo_Lote,
    r.Nombre_Reactivo,
    ir.Lote AS Lote_Reactivo,
    orr.Cantidad_Consumida,
    e.PrimerNombre + ' ' + e.PrimerApellido AS Responsable,
    os.Fecha_Inicio,
    os.Fecha_Fin_Real,
    cc.Resultado_Evaluacion
FROM Ordenes_Sintesis os
INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
INNER JOIN Lotes_Nanomateriales ln ON os.ID_Orden = ln.ID_Orden
INNER JOIN Orden_Reactivos orr ON os.ID_Orden = orr.ID_Orden
INNER JOIN Reactivos r ON orr.ID_Reactivo = r.ID_Reactivo
INNER JOIN Inventario_Reactivos ir ON orr.ID_Inventario = ir.ID_Inventario
INNER JOIN Empleados e ON os.ID_Empleado_Responsable = e.ID_Empleado
LEFT JOIN Control_Calidad cc ON os.ID_Orden = cc.ID_Orden;
GO