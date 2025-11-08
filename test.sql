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
    @ID_Orden_Creada = @NuevaOrdenID OUTPUT;

PRINT 'Nueva orden creada con ID: ' + CAST(@NuevaOrdenID AS NVARCHAR(10));


--------------------------------------
--   sp_registrar_orden_sintesis    --

-- Probar consumo automático (sistema elige lote)
EXEC sp_Consumir_Reactivo_Inventario
    @ID_Orden = 1,                     -- Orden existente
    @ID_Reactivo = 4,                  -- Etanol Absoluto
    @Cantidad_Consumir = 1.5,
    @ID_Empleado_Operacion = 3;        -- Luis García

-- Probar consumo manual (lote específico)
EXEC sp_Consumir_Reactivo_Inventario
    @ID_Orden = 1,
    @ID_Reactivo = 1,                  -- Cloruro de Oro
    @ID_Inventario = 1,                -- Lote específico
    @Cantidad_Consumir = 0.5,
    @ID_Empleado_Operacion = 1;        -- Carlos Martínez

