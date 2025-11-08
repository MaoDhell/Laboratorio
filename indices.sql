USE LabNanomateriales;
GO

------------------------------------
--           INDICES              --
------------------------------------
-- 1. ORDENES_SINTESIS - Consultas por estado y fecha
CREATE NONCLUSTERED INDEX IX_Ordenes_Sintesis_Estado_Fecha 
ON Ordenes_Sintesis (Estado_Orden, Fecha_Inicio)
INCLUDE (ID_Nanomaterial, ID_Empleado_Responsable, Codigo_Orden);

-- 2. ORDENES_SINTESIS - Consultas por nanomaterial
CREATE NONCLUSTERED INDEX IX_Ordenes_Sintesis_Nanomaterial 
ON Ordenes_Sintesis (ID_Nanomaterial, Estado_Orden);

-- 3. INVENTARIO_REACTIVOS - Alertas de vencimiento y disponibilidad
CREATE NONCLUSTERED INDEX IX_Inventario_Reactivos_Estado_Vencimiento 
ON Inventario_Reactivos (Estado_Reactivo, Fecha_Vencimiento)
INCLUDE (ID_Reactivo, Cantidad_Disponible, Lote);

-- 4. INVENTARIO_REACTIVOS - Búsquedas por reactivo específico
CREATE NONCLUSTERED INDEX IX_Inventario_Reactivos_Reactivo 
ON Inventario_Reactivos (ID_Reactivo, Estado_Reactivo);

-- 5. ORDEN_REACTIVOS - Cálculos de costos y consumo
CREATE NONCLUSTERED INDEX IX_Orden_Reactivos_Orden 
ON Orden_Reactivos (ID_Orden)
INCLUDE (ID_Reactivo, Cantidad_Consumida, Costo_Parcial);

-- 6. REACTIVOS - Búsquedas en catálogo
CREATE NONCLUSTERED INDEX IX_Reactivos_Nombre_Categoria 
ON Reactivos (Nombre_Reactivo, ID_Categoria)
INCLUDE (Costo_Unitario, Unidad_Medida);
