USE LabNanomateriales;
GO

--PROCEDIMIENTOS
--------------------------------------
--   sp_registrar_orden_sintesis    --


DECLARE @NuevaOrdenID INT;
EXEC sp_Registrar_Orden_Sintesis
    @ID_Nanomaterial = 1,              -- Nanopartículas de Oro
    @ID_Empleado_Responsable = 3,      -- Luis García
    @ID_Equipo_Principal = 1,          -- Reactor Hidrotermal
    @Cantidad_Objetivo = 25.0,
    @Unidad_Cantidad = 'g',
    @Prioridad = 'Alta',
    @Observaciones = 'Orden de prueba desde testing',
    @ID_Orden_Creada = @NuevaOrdenID;

PRINT 'Nueva orden creada con ID: ' + CAST(@NuevaOrdenID AS NVARCHAR(10));


--------------------------------------
--   sp_consumir_reactivo_inventario    --

EXEC sp_Consumir_Reactivo_Inventario
    @ID_Orden = 1,                     
    @ID_Reactivo = 11,                  
    @Cantidad_Consumir = 1.5,
    @ID_Empleado_Operacion = 3;


--------------------------------------
--   sp_Calcular_Costo_Total_Orden   --

EXEC sp_Calcular_Costo_Total_Orden 
    @ID_Orden = 1,
    @ActualizarCosto = 'A';


--------------------------------------
--   sp_Listar_Reactivos_Por_Vencer   --

PRINT 'Ejemplo 1: Todos en 365 días + vencidos';
EXEC sp_Listar_Reactivos_Por_Vencer 
    @DiasAdvertencia = 365,
    @FiltrarStockBajo = 'N',
    @IncluirVencidos = 'S';

PRINT 'Ejemplo 2: Todos los que vencen en 60 días (sin filtrar por stock)';
EXEC sp_Listar_Reactivos_Por_Vencer 
    @DiasAdvertencia = 60,
    @FiltrarStockBajo = 'N',
    @IncluirVencidos = 'N';


PRINT 'Ejemplo 3: Todos en 365 días + vencidos';
EXEC sp_Listar_Reactivos_Por_Vencer 
    @DiasAdvertencia = 365,
    @FiltrarStockBajo = 'N',
    @IncluirVencidos = 'S';

PRINT 'Ejemplo 4: Stock bajo en 180 días';
EXEC sp_Listar_Reactivos_Por_Vencer 
    @DiasAdvertencia = 180,
    @FiltrarStockBajo = 'S',
    @IncluirVencidos = 'N';


---------------------------------
-- INDICES

-- IX_Ordenes_Sintesis_Estado_Fecha
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Consulta 1.1: Órdenes activas en el último mes';
SELECT 
    Codigo_Orden,
    Estado_Orden,
    Fecha_Inicio,
    ID_Nanomaterial,
    ID_Empleado_Responsable
FROM Ordenes_Sintesis WITH (INDEX(IX_Ordenes_Sintesis_Estado_Fecha))
WHERE Estado_Orden IN ('En Proceso', 'Planificada')
    AND Fecha_Inicio >= DATEADD(MONTH, -1, GETDATE())
ORDER BY Fecha_Inicio DESC;

PRINT '';
PRINT 'Consulta 1.2: Órdenes completadas en 2023';
SELECT 
    Estado_Orden,
    COUNT(*) AS Total_Ordenes,
    AVG(DATEDIFF(DAY, Fecha_Inicio, Fecha_Fin_Real)) AS Dias_Promedio
FROM Ordenes_Sintesis WITH (INDEX(IX_Ordenes_Sintesis_Estado_Fecha))
WHERE Estado_Orden = 'Completada'
    AND YEAR(Fecha_Inicio) = 2023
GROUP BY Estado_Orden;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- IX_Ordenes_Sintesis_Nanomaterial
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Consulta 2.1: Historial de producción por nanomaterial';
SELECT 
    n.Nombre_Nanomaterial,
    os.Estado_Orden,
    COUNT(*) AS Numero_Ordenes,
    SUM(os.Cantidad_Objetivo) AS Cantidad_Total_Objetivo
FROM Ordenes_Sintesis os WITH (INDEX(IX_Ordenes_Sintesis_Nanomaterial))
INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
WHERE os.ID_Nanomaterial IN (1, 2, 3, 5)
GROUP BY n.Nombre_Nanomaterial, os.Estado_Orden
ORDER BY n.Nombre_Nanomaterial, os.Estado_Orden;

PRINT '';
PRINT 'Consulta 2.2: Órdenes activas de Nanopartículas de Oro';
SELECT 
    os.Codigo_Orden,
    os.Estado_Orden,
    os.Fecha_Inicio,
    os.Cantidad_Objetivo,
    e.PrimerNombre + ' ' + e.PrimerApellido AS Responsable
FROM Ordenes_Sintesis os WITH (INDEX(IX_Ordenes_Sintesis_Nanomaterial))
INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
INNER JOIN Empleados e ON os.ID_Empleado_Responsable = e.ID_Empleado
WHERE os.ID_Nanomaterial = 1
    AND os.Estado_Orden IN ('En Proceso', 'Planificada');

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- IX_Inventario_Reactivos_Estado_Vencimiento
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Consulta 3.1: Reactivos disponibles que vencen pronto';
SELECT 
    r.Nombre_Reactivo,
    ir.Lote,
    ir.Cantidad_Disponible,
    ir.Fecha_Vencimiento,
    DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) AS Dias_Para_Vencer
FROM Inventario_Reactivos ir WITH (INDEX(IX_Inventario_Reactivos_Estado_Vencimiento))
INNER JOIN Reactivos r ON ir.ID_Reactivo = r.ID_Reactivo
WHERE ir.Estado_Reactivo = 'Disponible'
    AND ir.Fecha_Vencimiento IS NOT NULL
    AND ir.Fecha_Vencimiento BETWEEN GETDATE() AND DATEADD(DAY, 90, GETDATE())
ORDER BY ir.Fecha_Vencimiento;

PRINT '';
PRINT 'Consulta 3.2: Resumen por estado de reactivo';
SELECT 
    ir.Estado_Reactivo,
    COUNT(*) AS Total_Lotes,
    SUM(ir.Cantidad_Disponible) AS Cantidad_Total,
    COUNT(CASE WHEN ir.Fecha_Vencimiento < GETDATE() THEN 1 END) AS Lotes_Vencidos
FROM Inventario_Reactivos ir WITH (INDEX(IX_Inventario_Reactivos_Estado_Vencimiento))
GROUP BY ir.Estado_Reactivo;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- IX_Inventario_Reactivos_Reactivo
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Consulta 4.1: Disponibilidad de un reactivo específico';
SELECT 
    r.Nombre_Reactivo,
    r.Formula_Quimica,
    ir.Lote,
    ir.Cantidad_Disponible,
    ir.Ubicacion_Almacen,
    ir.Fecha_Vencimiento,
    ir.Estado_Reactivo
FROM Inventario_Reactivos ir WITH (INDEX(IX_Inventario_Reactivos_Reactivo))
INNER JOIN Reactivos r ON ir.ID_Reactivo = r.ID_Reactivo
WHERE ir.ID_Reactivo = 1  -- Cloruro de Oro(III)
ORDER BY ir.Fecha_Ingreso;

PRINT '';
PRINT 'Consulta 4.2: Stock total por reactivo';
SELECT 
    r.Nombre_Reactivo,
    COUNT(ir.ID_Inventario) AS Num_Lotes,
    SUM(CASE WHEN ir.Estado_Reactivo = 'Disponible' THEN ir.Cantidad_Disponible ELSE 0 END) AS Stock_Disponible,
    r.Unidad_Medida,
    r.Punto_Reorden,
    CASE 
        WHEN SUM(CASE WHEN ir.Estado_Reactivo = 'Disponible' THEN ir.Cantidad_Disponible ELSE 0 END) <= r.Punto_Reorden 
        THEN 'CRÍTICO ' 
        ELSE 'OK ' 
    END AS Estado_Stock
FROM Inventario_Reactivos ir WITH (INDEX(IX_Inventario_Reactivos_Reactivo))
INNER JOIN Reactivos r ON ir.ID_Reactivo = r.ID_Reactivo
WHERE ir.ID_Reactivo IN (1, 5, 6, 18, 20)  -- Reactivos costosos
GROUP BY r.Nombre_Reactivo, r.Unidad_Medida, r.Punto_Reorden
ORDER BY Stock_Disponible DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- IX_Orden_Reactivos_Orden
PRINT 'Consulta 5.1: Detalle de reactivos consumidos en una orden';
SELECT 
    os.Codigo_Orden,
    r.Nombre_Reactivo,
    orr.Cantidad_Consumida,
    r.Unidad_Medida,
    orr.Costo_Unitario_Momento,
    orr.Costo_Parcial,
    orr.Fecha_Consumo
FROM Orden_Reactivos orr WITH (INDEX(IX_Orden_Reactivos_Orden))
INNER JOIN Ordenes_Sintesis os ON orr.ID_Orden = os.ID_Orden
INNER JOIN Reactivos r ON orr.ID_Reactivo = r.ID_Reactivo
WHERE orr.ID_Orden = 1
ORDER BY orr.Costo_Parcial DESC;

PRINT '';
PRINT 'Consulta 5.2: Resumen de costos por orden';
SELECT 
    os.Codigo_Orden,
    n.Nombre_Nanomaterial,
    COUNT(orr.ID_Reactivo) AS Num_Reactivos_Usados,
    SUM(orr.Cantidad_Consumida) AS Cantidad_Total,
    SUM(orr.Costo_Parcial) AS Costo_Total_Reactivos,
    os.Estado_Orden
FROM Orden_Reactivos orr WITH (INDEX(IX_Orden_Reactivos_Orden))
INNER JOIN Ordenes_Sintesis os ON orr.ID_Orden = os.ID_Orden
INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
WHERE orr.ID_Orden IN (1, 2, 3, 4, 5)
GROUP BY os.Codigo_Orden, n.Nombre_Nanomaterial, os.Estado_Orden
ORDER BY Costo_Total_Reactivos DESC;

PRINT '';
PRINT 'Consulta 5.3: Reactivo más consumido por orden';
SELECT TOP 5
    r.Nombre_Reactivo,
    COUNT(DISTINCT orr.ID_Orden) AS Ordenes_Que_Lo_Usan,
    SUM(orr.Cantidad_Consumida) AS Cantidad_Total_Consumida,
    r.Unidad_Medida,
    AVG(orr.Costo_Parcial) AS Costo_Promedio_Por_Uso
FROM Orden_Reactivos orr WITH (INDEX(IX_Orden_Reactivos_Orden))
INNER JOIN Reactivos r ON orr.ID_Reactivo = r.ID_Reactivo
GROUP BY r.Nombre_Reactivo, r.Unidad_Medida
ORDER BY Cantidad_Total_Consumida DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- IX_Reactivos_Nombre_Categoria
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Consulta 6.1: Búsqueda de reactivos por nombre parcial';
SELECT 
    r.Nombre_Reactivo,
    c.Nombre_Categoria,
    r.Formula_Quimica,
    r.Costo_Unitario,
    r.Unidad_Medida,
    r.Pureza
FROM Reactivos r WITH (INDEX(IX_Reactivos_Nombre_Categoria))
INNER JOIN Categorias_Reactivos c ON r.ID_Categoria = c.ID_Categoria
WHERE r.Nombre_Reactivo LIKE '%Oro%'
    OR r.Nombre_Reactivo LIKE '%Plata%'
ORDER BY r.Nombre_Reactivo;

PRINT '';
PRINT 'Consulta 6.2: Catálogo por categoría con costos';
SELECT 
    c.Nombre_Categoria,
    COUNT(r.ID_Reactivo) AS Num_Reactivos,
    AVG(r.Costo_Unitario) AS Costo_Promedio,
    MIN(r.Costo_Unitario) AS Costo_Minimo,
    MAX(r.Costo_Unitario) AS Costo_Maximo
FROM Reactivos r WITH (INDEX(IX_Reactivos_Nombre_Categoria))
INNER JOIN Categorias_Reactivos c ON r.ID_Categoria = c.ID_Categoria
GROUP BY c.Nombre_Categoria, r.ID_Categoria
ORDER BY Costo_Promedio DESC;

PRINT '';
PRINT 'Consulta 6.3: Reactivos de alta pureza por categoría';
SELECT 
    r.Nombre_Reactivo,
    c.Nombre_Categoria,
    r.Pureza,
    r.Costo_Unitario,
    r.Unidad_Medida
FROM Reactivos r WITH (INDEX(IX_Reactivos_Nombre_Categoria))
INNER JOIN Categorias_Reactivos c ON r.ID_Categoria = c.ID_Categoria
WHERE r.Pureza >= 99.00
    AND r.ID_Categoria IN (1, 5, 19)  -- Metales nobles, Precursores, Organometálicos
ORDER BY r.Pureza DESC, r.Costo_Unitario DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;


------------------------------------
-- VISTAS

--vw_Trazabilidad_Completa
SELECT 
    Codigo_Orden,
    Nombre_Nanomaterial,
    Codigo_Lote,
    Nombre_Reactivo,
    Lote_Reactivo,
    Cantidad_Consumida,
    Responsable,
    CONVERT(VARCHAR, Fecha_Inicio, 103) AS Fecha_Inicio,
    CONVERT(VARCHAR, Fecha_Fin_Real, 103) AS Fecha_Fin_Real,
    Resultado_Evaluacion
FROM vw_Trazabilidad_Completa
WHERE Codigo_Orden IN ('ORD-0001', 'ORD-0002', 'ORD-0003')
ORDER BY Codigo_Orden, Nombre_Reactivo;

-- vw_Rendimiento_Equipos
SELECT TOP 10
    Nombre_Equipo,
    Tipo_Equipo,
    Ordenes_Procesadas,
    CAST(Tiempo_Promedio_Horas AS DECIMAL(10,2)) AS Tiempo_Promedio_Horas,
    CAST(Rendimiento_Promedio AS DECIMAL(5,2)) AS Rendimiento_Promedio_Porc,
    CAST(Costo_Mantenimiento_Total AS DECIMAL(12,2)) AS Costo_Mantenimiento_Total,
    Estado_Equipo,
    Dias_Desde_Ultimo_Mantenimiento,
    CASE 
        WHEN Dias_Desde_Ultimo_Mantenimiento > 180 THEN 'REVISAR'
        WHEN Dias_Desde_Ultimo_Mantenimiento > 90 THEN 'PRÓXIMO'
        ELSE 'OK'
    END AS Estado_Mantenimiento
FROM vw_Rendimiento_Equipos
WHERE Ordenes_Procesadas > 0
ORDER BY Ordenes_Procesadas DESC, Rendimiento_Promedio DESC;

-- vw_Produccion_Mensual
SELECT 
    Tipo_Nanomaterial,
    Ordenes_Completadas,
    CAST(Cantidad_Producida AS DECIMAL(10,2)) AS Cantidad_Producida_g,
    CAST(Rendimiento_Promedio AS DECIMAL(5,2)) AS Rendimiento_Promedio_Porc,
    CAST(Pureza_Promedio AS DECIMAL(5,2)) AS Pureza_Promedio_Porc,
    CAST(Costo_Total AS DECIMAL(12,2)) AS Costo_Total_COP,
    CAST(Costo_Por_Gramo AS DECIMAL(12,2)) AS Costo_Por_Gramo_COP,
    CASE 
        WHEN Rendimiento_Promedio >= 85 AND Pureza_Promedio >= 98 THEN ' EXCELENTE'
        WHEN Rendimiento_Promedio >= 75 AND Pureza_Promedio >= 95 THEN ' BUENO'
        ELSE 'MEJORAR'
    END AS Evaluacion_Calidad
FROM vw_Produccion_Mensual
ORDER BY Cantidad_Producida DESC;

-- Verificar si hay datos del mes actual
IF NOT EXISTS (SELECT 1 FROM vw_Produccion_Mensual)
BEGIN
    PRINT '';
    PRINT 'NOTA: No hay órdenes completadas en el mes actual';
    PRINT 'Mostrando datos de órdenes completadas históricas:';
    PRINT '';
    
    -- Alternativa: Mostrar último mes con datos
    SELECT 
        n.Tipo_Nanomaterial,
        COUNT(os.ID_Orden) AS Ordenes_Completadas,
        SUM(ln.Cantidad_Producida) AS Cantidad_Producida,
        AVG(cc.Rendimiento_Porcentaje) AS Rendimiento_Promedio,
        AVG(cc.Pureza_Porcentaje) AS Pureza_Promedio,
        FORMAT(os.Fecha_Fin_Real, 'yyyy-MM') AS Periodo
    FROM Ordenes_Sintesis os
    INNER JOIN Nanomateriales n ON os.ID_Nanomaterial = n.ID_Nanomaterial
    INNER JOIN Lotes_Nanomateriales ln ON os.ID_Orden = ln.ID_Orden
    INNER JOIN Control_Calidad cc ON os.ID_Orden = cc.ID_Orden
    WHERE os.Estado_Orden = 'Completada'
    GROUP BY n.Tipo_Nanomaterial, FORMAT(os.Fecha_Fin_Real, 'yyyy-MM')
    ORDER BY Periodo DESC, Cantidad_Producida DESC;
END

