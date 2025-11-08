USE LabNanomateriales;
GO

CREATE OR ALTER PROCEDURE sp_Consumir_Reactivo_Inventario
	@ID_orden INT,
	@ID_Reactivo INT,
	@Cantidad_Consumir DECIMAL(10,3),
	@ID_Inventario INT = NULL,
	@ID_Empleado_Operacion INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- VALIDACIONES --
		-- Validar que la orden existe y está en proceso
		IF NOT EXISTS (SELECT 1 FROM Ordenes_Sintesis WHERE ID_Orden = @ID_orden AND Estado_Orden IN ('Planificada','En proceso'))
		BEGIN	
			RAISERROR('La orden no existe o no está en estado valido',16,1);	
			RETURN;
		END

		-- Validar si el reactivo existe
		IF NOT EXISTS (SELECT 1 FROM Reactivos WHERE ID_Reactivo = @ID_Reactivo)
		BEGIN
			RAISERROR('El reactivo no existe',16,1)
			RETURN;
		END

		-- Validar si el empleado existe y esta activo
		IF NOT EXISTS (SELECT 1 FROM Empleados WHERE ID_Empleado = @ID_Empleado_Operacion AND Estado='Activo')
		BEGIN
			RAISERROR('El empleado no esxiste o no está activo',16,1)
			RETURN;
		END

		-- Si no se especifica inventario, buscar el lote más antiguo disponible (FIFO)
		IF @ID_Inventario IS NULL
		BEGIN
		SELECT TOP 1 @ID_Inventario = @ID_Inventario
		FROM Inventario_Reactivos ir
		WHERE ir.ID_Reactivo = @ID_Reactivo
		AND ir.Estado_Reactivo = 'Disponible'
		AND ir.Cantidad_Disponible >= @Cantidad_Consumir
		AND (ir.Fecha_Vencimiento IS NULL OR ir.Fecha_Vencimiento > GETDATE())
		 	ORDER BY 
				Fecha_Vencimiento ASC,
				Fecha_Ingreso ASC;

			IF @ID_Inventario IS NULL
				RAISERROR('No hay lotes disponibles con suficiente cantidad del reactivo especificado',16,1)
		END

		-- verificamos disponibilidad del reactivo
		DECLARE @CantidadActual DECIMAL(10,4);
		DECLARE @CostoUnitario DECIMAL(10,2);

		SELECT @CantidadActual= irc.Cantidad_Disponible, @CostoUnitario = r.Costo_Unitario
		FROM Inventario_Reactivos irc
		INNER JOIN Reactivos r ON irc.ID_Reactivo = r.ID_Reactivo
		WHERE irc.ID_Inventario = @ID_Inventario
			AND irc.Estado_Reactivo = 'Disponible'
			AND (irc.Fecha_Vencimiento IS NULL OR irc.Fecha_Vencimiento > GETDATE())

		-- validamos si la cantidad del reactivo que se solicita esta
		IF @CantidadActual IS NULL
			RAISERROR('Lote no disponible o vencido',16,1)

		IF @CantidadActual < @Cantidad_Consumir
			RAISERROR('Cantidad insuficiente',16,1)

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
		
		PRINT'Consumo registrado exitosamente';

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END;
