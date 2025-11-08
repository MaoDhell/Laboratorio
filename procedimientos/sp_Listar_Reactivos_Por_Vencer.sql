USE LabNanomateriales;
GO

CREATE OR ALTER PROCEDURE sp_Listar_Reactivos_Por_Vencer
	@DiasAdvertencia INT = 30,			 -- dias de advertencia antes del vencimiento
	@FiltrarStockBajo CHAR(1) = 'N',	 -- 'S' Solo stock bajo, 'N' todos
	@IncluirVencidos CHAR(1) = 'N'		 -- 'S' incluir vencidos, 'N' solo por vencer

AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- VALIDAR PARÁMETROS
        IF @FiltrarStockBajo NOT IN ('S', 'N')
        BEGIN
            RAISERROR('El parámetro @FiltrarStockBajo debe ser ''S'' (Sí) o ''N'' (No).', 16, 1);
            RETURN;
        END

        IF @IncluirVencidos NOT IN ('S', 'N')
        BEGIN
            RAISERROR('El parámetro @IncluirVencidos debe ser ''S'' (Sí) o ''N'' (No).', 16, 1);
            RETURN;
        END

        -- LISTAR REACTIVOS QUE VENCEN EN LOS PRÓXIMOS @DiasAdvertencia DÍAS
        SELECT 
            r.ID_Reactivo,
            r.Nombre_Reactivo,
            r.Formula_Quimica,
            cr.Nombre_Categoria,
            cr.Nivel_Peligrosidad,
            ir.Lote,
            ir.Cantidad_Disponible,
            r.Unidad_Medida,
            ir.Fecha_Vencimiento,
            DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) AS Dias_Para_Vencer,
            ir.Ubicacion_Almacen,
            p.Nombre_Empresa AS Proveedor,
            r.Punto_Reorden,
            CASE 
                WHEN ir.Cantidad_Disponible <= r.Punto_Reorden THEN 'STOCK BAJO'
                ELSE 'STOCK OK'
            END AS Estado_Stock,
            CASE 
                WHEN DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) <= 0 THEN 'VENCIDO'
                WHEN DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) <= 7 THEN 'PRÓXIMO (≤7 días)'
                WHEN DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) <= 30 THEN 'PRÓXIMO (≤30 días)'
                ELSE 'VIGENTE'
            END AS Alerta_Vencimiento,
            CASE 
                WHEN cr.Requiere_Almacenamiento_Especial = 1 THEN 'ESPECIAL'
                ELSE 'NORMAL'
            END AS Tipo_Almacenamiento
        FROM Inventario_Reactivos ir
        INNER JOIN Reactivos r ON ir.ID_Reactivo = r.ID_Reactivo
        INNER JOIN Categorias_Reactivos cr ON r.ID_Categoria = cr.ID_Categoria
        INNER JOIN Proveedores p ON r.ID_Proveedor = p.ID_Proveedor
        WHERE ir.Estado_Reactivo = 'Disponible'
            AND ir.Fecha_Vencimiento IS NOT NULL
            AND (
                (@IncluirVencidos = 'S' AND ir.Fecha_Vencimiento <= DATEADD(DAY, @DiasAdvertencia, GETDATE()))
                OR 
                (@IncluirVencidos = 'N' AND ir.Fecha_Vencimiento BETWEEN GETDATE() AND DATEADD(DAY, @DiasAdvertencia, GETDATE()))
            )
            AND (@FiltrarStockBajo = 'N' OR ir.Cantidad_Disponible <= r.Punto_Reorden)
        ORDER BY 
            ir.Fecha_Vencimiento ASC,
            Estado_Stock DESC,
            cr.Nivel_Peligrosidad DESC,
            r.Nombre_Reactivo;

        --  RESUMEN
        SELECT 
            COUNT(*) AS Total_Reactivos,
            SUM(CASE WHEN DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) <= 0 THEN 1 ELSE 0 END) AS Reactivos_Vencidos,
            SUM(CASE WHEN DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) BETWEEN 1 AND 7 THEN 1 ELSE 0 END) AS Reactivos_Vencen_7_Dias,
            SUM(CASE WHEN DATEDIFF(DAY, GETDATE(), ir.Fecha_Vencimiento) BETWEEN 8 AND 30 THEN 1 ELSE 0 END) AS Reactivos_Vencen_30_Dias,
            SUM(CASE WHEN ir.Cantidad_Disponible <= r.Punto_Reorden THEN 1 ELSE 0 END) AS Reactivos_Stock_Bajo,
            SUM(CASE WHEN cr.Nivel_Peligrosidad IN ('Alto', 'Crítico') THEN 1 ELSE 0 END) AS Reactivos_Peligrosos
        FROM Inventario_Reactivos ir
        INNER JOIN Reactivos r ON ir.ID_Reactivo = r.ID_Reactivo
        INNER JOIN Categorias_Reactivos cr ON r.ID_Categoria = cr.ID_Categoria
        WHERE ir.Estado_Reactivo = 'Disponible'
            AND ir.Fecha_Vencimiento IS NOT NULL
            AND (
                (@IncluirVencidos = 'S' AND ir.Fecha_Vencimiento <= DATEADD(DAY, @DiasAdvertencia, GETDATE()))
                OR 
                (@IncluirVencidos = 'N' AND ir.Fecha_Vencimiento BETWEEN GETDATE() AND DATEADD(DAY, @DiasAdvertencia, GETDATE()))
            );

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO