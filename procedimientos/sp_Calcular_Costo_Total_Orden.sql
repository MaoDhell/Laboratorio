USE LabNanomateriales;
GO

CREATE OR ALTER PROCEDURE sp_Calcular_Costo_Total_Orden
    @ID_Orden INT,
    @ActualizarCosto CHAR(1) = 'N'  -- Si es A, actualiza el campo Costo_Total en la orden - Si es N no actualiza el campo
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- VALIDAR QUE LA ORDEN EXISTE
        IF NOT EXISTS (SELECT 1 FROM Ordenes_Sintesis WHERE ID_Orden = @ID_Orden)
        BEGIN
            RAISERROR('La orden especificada no existe.', 16, 1);
            RETURN;
        END

        -- CALCULAR COSTOS
        DECLARE @CostoReactivos DECIMAL(12,2);
        DECLARE @CostoManoObra DECIMAL(12,2);
        DECLARE @CostoEquipos DECIMAL(12,2);
        DECLARE @CostoTotal DECIMAL(12,2);
        DECLARE @DuracionHoras DECIMAL(10,2);

        -- 1. COSTO DE REACTIVOS (suma de Costo_Parcial de Orden_Reactivos)
        SELECT @CostoReactivos = ISNULL(SUM(Costo_Parcial), 0)
        FROM Orden_Reactivos
        WHERE ID_Orden = @ID_Orden;

        -- 2. CALCULAR DURACIÓN Y COSTO DE MANO DE OBRA
        SELECT 
            @DuracionHoras = CASE 
                WHEN Fecha_Fin_Real IS NOT NULL THEN
                    DATEDIFF(MINUTE, Fecha_Inicio, Fecha_Fin_Real) / 60.0
                WHEN Fecha_Fin_Estimada IS NOT NULL THEN
                    DATEDIFF(MINUTE, Fecha_Inicio, Fecha_Fin_Estimada) / 60.0
                ELSE 8.0 
            END
        FROM Ordenes_Sintesis
        WHERE ID_Orden = @ID_Orden;

        -- Costo de mano de obra (salario por hora * duración)
        SELECT @CostoManoObra = ISNULL(SUM(e.Salario / 176 * @DuracionHoras), 0) -- 176 horas/mes
        FROM Ordenes_Sintesis os
        INNER JOIN Empleados e ON os.ID_Empleado_Responsable = e.ID_Empleado
        WHERE os.ID_Orden = @ID_Orden;

        -- 3. COSTO DE EQUIPOS (depreciación por hora)
        SELECT @CostoEquipos = ISNULL(SUM(
            eq.Costo_Adquisicion / (5 * 2000) * @DuracionHoras -- 5 años, 2000 horas/año
        ), 0)
        FROM Ordenes_Sintesis os
        INNER JOIN Equipamiento eq ON os.ID_Equipo_Principal = eq.ID_Equipo
        WHERE os.ID_Orden = @ID_Orden;

        -- 4. CALCULAR COSTO TOTAL
        SET @CostoTotal = @CostoReactivos + @CostoManoObra + @CostoEquipos;

        -- 5. ACTUALIZAR LA ORDEN SI SE SOLICITA
        IF @ActualizarCosto = 'A'
        BEGIN
            UPDATE Ordenes_Sintesis
            SET Costo_Total = @CostoTotal
            WHERE ID_Orden = @ID_Orden;
        END

        -- 6. RETORNAR EL DESGLOSE DE COSTOS
        SELECT 
            @ID_Orden AS ID_Orden,
            (SELECT Codigo_Orden FROM Ordenes_Sintesis WHERE ID_Orden = @ID_Orden) AS Codigo_Orden,
            (SELECT Nombre_Nanomaterial FROM Nanomateriales n 
             INNER JOIN Ordenes_Sintesis os ON n.ID_Nanomaterial = os.ID_Nanomaterial 
             WHERE os.ID_Orden = @ID_Orden) AS Nanomaterial,
            @CostoReactivos AS Costo_Reactivos,
            @CostoManoObra AS Costo_Mano_Obra,
            @CostoEquipos AS Costo_Equipos,
            @CostoTotal AS Costo_Total,
            @DuracionHoras AS Duracion_Estimada_Horas,
            (SELECT COUNT(*) FROM Orden_Reactivos WHERE ID_Orden = @ID_Orden) AS Reactivos_Utilizados,
            CASE WHEN @ActualizarCosto = 'A' THEN 'Sí' ELSE 'No' END AS Costo_Actualizado;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO