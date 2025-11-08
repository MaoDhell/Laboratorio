USE LabNanomateriales;
GO

CREATE OR ALTER PROCEDURE sp_Consumir_Reactivo_Inventario
	@ID_Orden INT,
	@ID_Reactivo INT,
	@Cantidad_Consumir DECIMAL(10,3),
	@ID_Inventario INT = NULL,
	@ID_Empleado_Operacion INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- DEPURACIÓN: Ver qué estamos recibiendo
		PRINT 'Parámetros recibidos:';
		PRINT 'ID_Orden: ' + CAST(@ID_Orden AS NVARCHAR(10));
		PRINT 'ID_Reactivo: ' + CAST(@ID_Reactivo AS NVARCHAR(10));
		PRINT 'ID_Empleado: ' + CAST(@ID_Empleado_Operacion AS NVARCHAR(10));

		DECLARE @EstadoActual NVARCHAR(30);
		SELECT @EstadoActual = Estado_Orden 
		FROM Ordenes_Sintesis 
		WHERE ID_Orden = @ID_Orden;
		
		PRINT 'Estado actual de la orden: ' + ISNULL(@EstadoActual, 'NO ENCONTRADA');

		-- VALIDACIONES --
		-- Validar que la orden existe y está en proceso
		IF NOT EXISTS (SELECT 1 FROM Ordenes_Sintesis WHERE ID_Orden = @ID_Orden AND Estado_Orden IN ('Planificada','En Proceso'))
		BEGIN	
			PRINT 'FALLA VALIDACIÓN: Orden no existe o estado no válido';
			RAISERROR('La orden no existe o no está en estado valido',16,1);	
			RETURN;
		END

		

		-- Validar si el reactivo existe
		IF NOT EXISTS (SELECT 1 FROM Reactivos WHERE ID_Reactivo = @ID_Reactivo)
		BEGIN
			RAISERROR('El reactivo no existe',16,1);
			RETURN;
		END
		PRINT 'Validación de reactivo PASADA';

		-- Validar si el empleado existe y esta activo
		IF NOT EXISTS (SELECT 1 FROM Empleados WHERE ID_Empleado = @ID_Empleado_Operacion AND Estado='Activo')
		BEGIN
			RAISERROR('El empleado no esxiste o no está activo',16,1);
			RETURN;
		END
		PRINT 'Validación de empleado PASADA';

		-- Si no se especifica inventario, buscar el lote más antiguo disponible (FIFO)
		IF @ID_Inventario IS NULL
		BEGIN
		SELECT TOP 1 @ID_Inventario = ir.ID_Inventario
		FROM Inventario_Reactivos ir
		WHERE ir.ID_Reactivo = @ID_Reactivo
		AND ir.Estado_Reactivo = 'Disponible'
		AND ir.Cantidad_Disponible >= @Cantidad_Consumir
		AND (ir.Fecha_Vencimiento IS NULL OR ir.Fecha_Vencimiento > GETDATE())
		 	ORDER BY 
				Fecha_Vencimiento ASC,
				Fecha_Ingreso ASC;

			IF @ID_Inventario IS NULL
				RAISERROR('No hay lotes disponibles con suficiente cantidad del reactivo especificado',16,1);
		END

		PRINT 'Búsqueda de inventario PASADA';

		-- verificamos disponibilidad del reactivo
		DECLARE @CantidadActual DECIMAL(10,4);
		DECLARE @CostoUnitario DECIMAL(10,2);

		SELECT @CantidadActual= ir.Cantidad_Disponible, @CostoUnitario = r.Costo_Unitario
		FROM Inventario_Reactivos ir
		INNER JOIN Reactivos r ON ir.ID_Reactivo = r.ID_Reactivo
		WHERE ir.ID_Inventario = @ID_Inventario
			AND ir.Estado_Reactivo = 'Disponible'
			AND (ir.Fecha_Vencimiento IS NULL OR ir.Fecha_Vencimiento > GETDATE())

		-- validamos si la cantidad del reactivo que se solicita esta
		IF @CantidadActual IS NULL
			RAISERROR('Lote no disponible o vencido',16,1);

		IF @CantidadActual < @Cantidad_Consumir
			RAISERROR('Cantidad insuficiente',16,1);

		-- Se registra la orden
		INSERT INTO Orden_Reactivos (ID_Orden, ID_Reactivo, ID_Inventario, Cantidad_Consumida, Costo_Unitario_Momento)
		VALUES (@ID_Orden, @ID_Reactivo, @ID_Inventario, @Cantidad_Consumir, @CostoUnitario);

		-- Actualizamos inventario
		UPDATE Inventario_Reactivos 
		SET Cantidad_Disponible = Cantidad_Disponible - @Cantidad_Consumir
		WHERE ID_Inventario = @ID_Inventario;

		-- Registro de modificacion de inventario (Auditoria_Inventario)
		INSERT INTO Auditoria_Inventario (ID_Inventario, ID_Reactivo, Operacion, Cantidad_Anterior, Cantidad_Nueva, Usuario)
		VALUES (@ID_Inventario, @ID_Reactivo, 'UPDATE', @CantidadActual, @CantidadActual - @Cantidad_Consumir, SYSTEM_USER);

		COMMIT TRANSACTION;
		
		PRINT 'Consumo registrado exitosamente';

		-- Retornar información del consumo
        SELECT 
            'Consumo registrado exitosamente' AS Estado,
            orr.ID_Orden_Reactivo,
            o.Codigo_Orden,
            r.Nombre_Reactivo,
            ir.Lote,
            orr.Cantidad_Consumida,
            r.Unidad_Medida,
            orr.Costo_Parcial,
            ir.Cantidad_Disponible AS Nuevo_Saldo
        FROM Orden_Reactivos orr
        INNER JOIN Reactivos r ON orr.ID_Reactivo = r.ID_Reactivo
        INNER JOIN Inventario_Reactivos ir ON orr.ID_Inventario = ir.ID_Inventario
        INNER JOIN Ordenes_Sintesis o ON orr.ID_Orden = o.ID_Orden
        WHERE orr.ID_Orden_Reactivo = SCOPE_IDENTITY();

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END;
