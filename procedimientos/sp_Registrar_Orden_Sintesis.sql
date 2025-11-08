USE LabNanomateriales;
GO

-- REGISTRAR NUEVA ORDEN DE SÍNTESIS

CREATE OR ALTER PROCEDURE sp_Registrar_Orden_Sintesis
    @ID_Nanomaterial INT,
    @ID_Empleado_Responsable INT,
    @ID_Equipo_Principal INT,
    @Fecha_Inicio DATETIME = NULL,
    @Fecha_Fin_Estimada DATETIME = NULL,
    @Cantidad_Objetivo DECIMAL(10,3),
    @Unidad_Cantidad NVARCHAR(20),
    @Prioridad NVARCHAR(20) = 'Normal',
    @Observaciones NVARCHAR(500) = NULL,
    @ID_Orden_Creada INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- VALIDACIONES --
        -- Validar que el nanomaterial existe
        IF NOT EXISTS (SELECT 1 FROM Nanomateriales WHERE ID_Nanomaterial = @ID_Nanomaterial)
        BEGIN
            RAISERROR('El nanomaterial especificado no existe.', 16, 1);
            RETURN;
        END
        
        -- Validar que el empleado existe y está activo
        IF NOT EXISTS (SELECT 1 FROM Empleados WHERE ID_Empleado = @ID_Empleado_Responsable AND Estado = 'Activo')
        BEGIN
            RAISERROR('El empleado especificado no existe o no está activo.', 16, 1);
            RETURN;
        END
        
        -- Validar que el equipo existe y está operativo
        IF NOT EXISTS (SELECT 1 FROM Equipamiento WHERE ID_Equipo = @ID_Equipo_Principal AND Estado_Equipo = 'Operativo')
        BEGIN
            RAISERROR('El equipo especificado no existe o no está operativo.', 16, 1);
            RETURN;
        END

        -- Validar que la unidad de cantidad sea valida
        IF @Unidad_Cantidad NOT IN ('g', 'kg', 'mg', 'unidades')
        BEGIN
            RAISERROR('La unidad de cantidad especificada no es válida.', 16, 1);
            RETURN;
        END
        
        -- Establecer fecha de inicio si no se proporciona
        IF @Fecha_Inicio IS NULL
            SET @Fecha_Inicio = GETDATE();
        
        -- Calcular fecha fin estimada si no se proporciona (3 días por defecto)
        IF @Fecha_Fin_Estimada IS NULL
            SET @Fecha_Fin_Estimada = DATEADD(DAY, 3, @Fecha_Inicio);

        -- NUEVA ORDEN --
        -- Insertar la nueva orden
        INSERT INTO Ordenes_Sintesis (
            ID_Nanomaterial,
            ID_Empleado_Responsable,
            ID_Equipo_Principal,
            Fecha_Inicio,
            Fecha_Fin_Estimada,
            Cantidad_Objetivo,
            Unidad_Cantidad,
            Prioridad,
            Estado_Orden,
            Observaciones
        )
        VALUES (
            @ID_Nanomaterial,
            @ID_Empleado_Responsable,
            @ID_Equipo_Principal,
            @Fecha_Inicio,
            @Fecha_Fin_Estimada,
            @Cantidad_Objetivo,
            @Unidad_Cantidad,
            @Prioridad,
            'Planificada',
            @Observaciones
        );
        
        -- Obtener el ID de la orden creada
        SET @ID_Orden_Creada = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
       
        -- Retornar información de la orden creada
        SELECT 
            o.ID_Orden,
            o.Codigo_Orden,
            n.Nombre_Nanomaterial,
            e.PrimerNombre + ' ' + e.PrimerApellido AS Empleado_Responsable,
            eq.Nombre_Equipo,
            o.Fecha_Inicio,
            o.Fecha_Fin_Estimada,
            o.Cantidad_Objetivo,
            o.Unidad_Cantidad,
            o.Prioridad,
            o.Estado_Orden
        FROM Ordenes_Sintesis o
        INNER JOIN Nanomateriales n ON o.ID_Nanomaterial = n.ID_Nanomaterial
        INNER JOIN Empleados e ON o.ID_Empleado_Responsable = e.ID_Empleado
        INNER JOIN Equipamiento eq ON o.ID_Equipo_Principal = eq.ID_Equipo
        WHERE o.ID_Orden = @ID_Orden_Creada;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Mensaje de error (texto)
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        -- El nivel de gravedad (urgencia) del error (numerico) 
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        -- Origen del error
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO