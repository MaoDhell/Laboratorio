
USE LabNanomateriales;
GO

CREATE TRIGGER trg_AuditoriaStockNanomateriales
ON Nanomateriales
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Auditar nuevos nanomateriales
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria_Inventario_Nanomateriales(ID_Nanomaterial,Operacion,Cantidad_Anterior,Cantidad_Nueva,Motivo)
        SELECT 
            ID_Nanomaterial,'INSERT',0,stock,'Nuevo nanomaterial registrado: ' + Nombre_Nanomaterial
        FROM inserted;
    END
    
    -- Auditar cambios en stock
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria_Inventario_Nanomateriales(ID_Nanomaterial, Operacion,Cantidad_Anterior,Cantidad_Nueva,Motivo)
        SELECT 
            i.ID_Nanomaterial,'UPDATE',d.stock,i.stock,'Actualización de stock: ' + i.Nombre_Nanomaterial
        FROM inserted i
        INNER JOIN deleted d ON i.ID_Nanomaterial = d.ID_Nanomaterial
        WHERE i.stock != d.stock;
    END
    
    -- regiistrar eliminación de nanomateriales
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria_Inventario_Nanomateriales(ID_Nanomaterial,Operacion,Cantidad_Anterior,Cantidad_Nueva,Motivo)
        SELECT 
            ID_Nanomaterial,'DELETE',stock,0,'Nanomaterial eliminado: ' + Nombre_Nanomaterial
        FROM deleted;
    END
    
END;
GO