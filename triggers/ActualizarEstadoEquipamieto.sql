USE LabNanomateriales;
GO

CREATE TRIGGER trg_actualizarEstadoEquipamiento
ON Mantenimiento_Equipos
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE e
    SET e.Estado_Equipo = 
        CASE 
            WHEN i.Estado_Resultado = 'Exitoso' THEN 'Operativo'
            WHEN i.Estado_Resultado = 'Requiere Seguimiento' THEN 'Mantenimiento'
            WHEN i.Estado_Resultado = 'Requiere Reparación' THEN 'Averiado'
            ELSE e.Estado_Equipo
        END
    FROM Equipamiento e
    INNER JOIN inserted i ON e.ID_Equipo = i.ID_Equipo;
END;
GO


----------------------------------------------------------------------------------------------------------------
