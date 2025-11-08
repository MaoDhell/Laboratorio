USE LabNanomateriales;
GO

CREATE OR ALTER VIEW vw_Inventario_Critico
AS
SELECT 
    r.Nombre_Reactivo,
    r.Formula_Quimica,
    cr.Nivel_Peligrosidad,
    ir.Lote,
    ir.Cantidad_Disponible,
    r.Unidad_Medida,
    r.Punto_Reorden,
    ir.Fecha_Vencimiento,
    DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) AS Dias_Para_Vencer,
    CASE 
        WHEN ir.Cantidad_Disponible <= r.Punto_Reorden THEN 'STOCK BAJO'
        WHEN ir.Fecha_Vencimiento <= DATEADD(DAY, 7, GETDATE()) THEN 'VENCE PRONTO'
        ELSE 'NORMAL'
    END AS Estado_Critico
FROM Reactivos r
INNER JOIN Categorias_Reactivos cr ON r.ID_Categoria = cr.ID_Categoria
INNER JOIN Inventario_Reactivos ir ON r.ID_Reactivo = ir.ID_Reactivo
WHERE ir.Estado_Reactivo = 'Disponible'
    AND (
        ir.Cantidad_Disponible <= r.Punto_Reorden 
        OR ir.Fecha_Vencimiento <= DATEADD(DAY, 30, GETDATE())
        OR cr.Nivel_Peligrosidad IN ('Alto', 'Crítico')
    );
GO
