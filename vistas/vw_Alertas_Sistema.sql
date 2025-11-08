USE LabNanomateriales;
GO

CREATE OR ALTER VIEW vw_Alertas_Sistema
AS
SELECT 
    'Reactivo por vencer' AS Tipo_Alerta,
    r.Nombre_Reactivo + ' - Lote: ' + ir.Lote AS Descripcion,
    ir.Fecha_Vencimiento AS Fecha_Referencia,
    DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) AS Dias_Restantes,
    'ALTA' AS Prioridad
FROM Inventario_Reactivos ir
INNER JOIN Reactivos r ON ir.ID_Reactivo = r.ID_Reactivo
WHERE ir.Estado_Reactivo = 'Disponible' 
    AND ir.Fecha_Vencimiento <= DATEADD(DAY, 15, GETDATE())

UNION ALL

SELECT 
    'Stock bajo' AS Tipo_Alerta,
    r.Nombre_Reactivo + ' - Stock: ' + CAST(ir.Cantidad_Disponible AS NVARCHAR) + ' ' + r.Unidad_Medida AS Descripcion,
    NULL AS Fecha_Referencia,
    NULL AS Dias_Restantes,
    'MEDIA' AS Prioridad
FROM Inventario_Reactivos ir
INNER JOIN Reactivos r ON ir.ID_Reactivo = r.ID_Reactivo
WHERE ir.Estado_Reactivo = 'Disponible' 
    AND ir.Cantidad_Disponible <= r.Punto_Reorden

UNION ALL

SELECT 
    'Mantenimiento pendiente' AS Tipo_Alerta,
    eq.Nombre_Equipo + ' - Próximo: ' + CONVERT(NVARCHAR, me.Proximo_Mantenimiento, 103) AS Descripcion,
    me.Proximo_Mantenimiento AS Fecha_Referencia,
    DATEDIFF(DAY, GETDATE(), me.Proximo_Mantenimiento) AS Dias_Restantes,
    'ALTA' AS Prioridad
FROM Equipamiento eq
INNER JOIN Mantenimiento_Equipos me ON eq.ID_Equipo = me.ID_Equipo
WHERE me.Proximo_Mantenimiento <= DATEADD(DAY, 7, GETDATE())

UNION ALL

SELECT 
    'Orden atrasada' AS Tipo_Alerta,
    'Orden ' + os.Codigo_Orden + ' - ' + n.Nombre_Nanomaterial AS Descripcion,
    os.Fecha_Fin_Estimada AS Fecha_Referencia,
    DATEDIFF(DAY, os.Fecha_Fin_Estimada, GETDATE()) AS Dias_Retraso,
    'MEDIA' AS Prioridad
FROM Ordenes_Sintesis os
INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
WHERE os.Estado_Orden = 'En Proceso' 
    AND os.Fecha_Fin_Estimada < GETDATE();
GO