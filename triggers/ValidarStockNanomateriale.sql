-- trigger 2 validar stock antes del consulo

CREATE TRIGGER trg_ValidarStockNanomateriales
ON Auditoria_Consumo_Nanomateriales
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si hay nanomaterialeas suficiente
    IF EXISTS (SELECT 1 FROM inserted i
        INNER JOIN Nanomateriales n ON i.ID_Nanomaterial = n.ID_Nanomaterial
        WHERE n.stock < i.Cantidad_Consumida
    )
    BEGIN
	---- error cuando no hay sufucunete nanomaterial 

        RAISERROR('Error: Stock insuficiente para realizar el consumo.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Insertar el registro de consumo
    INSERT INTO Auditoria_Consumo_Nanomateriales (ID_Nanomaterial,ID_Empleado_Solicitante,Cantidad_Consumida,Fecha_Consumo,Observaciones)
    SELECT 
        ID_Nanomaterial,ID_Empleado_Solicitante,Cantidad_Consumida,isnull(Fecha_Consumo, GETDATE()),Observaciones
    FROM inserted;
    
    -- Actualizar el stock
    UPDATE n
    SET n.stock = n.stock - i.Cantidad_Consumida
    FROM Nanomateriales n
    INNER JOIN inserted i ON n.ID_Nanomaterial = i.ID_Nanomaterial;
    
END;
GO
