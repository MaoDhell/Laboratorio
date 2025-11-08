CREATE DATABASE LabNanomateriales;
GO

USE LabNanomateriales;
GO

----------------------------------------------------
-- 1. Personal del laboratorio 

CREATE TABLE Empleados (
    ID_Empleado INT PRIMARY KEY IDENTITY(1,1),
    PrimerNombre NVARCHAR(50) NOT NULL,
    SegundoNombre NVARCHAR(50),
    PrimerApellido NVARCHAR(50) NOT NULL,
    SegundoApellido NVARCHAR(50) NOT NULL,
    Rol NVARCHAR(50) NOT NULL CHECK (Rol IN ('Investigador', 'Técnico', 'Supervisor', 'Analista', 'Administrador')),
    Departamento NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Telefono NVARCHAR(20),
    Fecha_Contratacion DATE NOT NULL,
    Salario DECIMAL(10,2),
    Estado NVARCHAR(20) DEFAULT 'Activo' CHECK (Estado IN ('Activo', 'Inactivo', 'Licencia'))
);

------------------------------------------------------
-- 2. Proveedores de reactivos y equipos

CREATE TABLE Proveedores (
    ID_Proveedor INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Empresa NVARCHAR(150) NOT NULL,
    Contacto_Nombre NVARCHAR(100),
    Email NVARCHAR(100),
    Telefono NVARCHAR(20),
    Direccion NVARCHAR(200),
    Ciudad NVARCHAR(50),
    Pais NVARCHAR(50) DEFAULT 'Colombia',
    Tipo_Proveedor NVARCHAR(50) CHECK (Tipo_Proveedor IN ('Químicos', 'Equipos', 'Consumibles', 'Gases', 'Mixto')),
    Calificacion DECIMAL(3,2) CHECK (Calificacion BETWEEN 0 AND 5),
    Fecha_Registro DATE DEFAULT GETDATE()
);

-----------------------------------------------------
-- 3. Clasificación de reactivos quimicos 

CREATE TABLE Categorias_Reactivos (
    ID_Categoria INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Categoria NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(300),
    Nivel_Peligrosidad NVARCHAR(20) CHECK (Nivel_Peligrosidad IN ('Bajo', 'Medio', 'Alto', 'Crítico')),
    Requiere_Almacenamiento_Especial BIT DEFAULT 0
);

------------------------------------------------------
-- 4. Reactivos quimicos (catalogo/lista/idk)

CREATE TABLE Reactivos (
    ID_Reactivo INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Reactivo NVARCHAR(150) NOT NULL,
    Formula_Quimica NVARCHAR(100),
    Numero_CAS NVARCHAR(20) UNIQUE,
    ID_Categoria INT FOREIGN KEY REFERENCES Categorias_Reactivos(ID_Categoria),
    ID_Proveedor INT FOREIGN KEY REFERENCES Proveedores(ID_Proveedor),
    Pureza DECIMAL(5,2) CHECK (Pureza BETWEEN 0 AND 100),
    Costo_Unitario DECIMAL(10,2) NOT NULL,
    Unidad_Medida NVARCHAR(20) CHECK (Unidad_Medida IN ('g', 'kg', 'mL', 'L', 'mol', 'unidad')),
    Punto_Reorden INT DEFAULT 10,
    Ficha_Seguridad_URL NVARCHAR(300)
);

-------------------------------------------------------
-- 5. Existencia de los reactivos (inventario)

CREATE TABLE Inventario_Reactivos (
    ID_Inventario INT PRIMARY KEY IDENTITY(1,1),
    ID_Reactivo INT FOREIGN KEY REFERENCES Reactivos(ID_Reactivo),
    Lote NVARCHAR(50) NOT NULL,
    Cantidad_Disponible DECIMAL(10,3) NOT NULL CHECK (Cantidad_Disponible >= 0),
    Ubicacion_Almacen NVARCHAR(50) NOT NULL,
    Fecha_Ingreso DATE DEFAULT GETDATE(),
    Fecha_Vencimiento DATE,
    Temperatura_Almacenamiento DECIMAL(5,2),
    Estado_Reactivo NVARCHAR(20) DEFAULT 'Disponible' CHECK (Estado_Reactivo IN ('Disponible', 'Reservado', 'Vencido', 'En Uso')),
    CONSTRAINT UQ_Reactivo_Lote UNIQUE (ID_Reactivo, Lote)
);

---------------------------------------------------------
-- 6. Nanomateriales producidos (inventario)

CREATE TABLE Nanomateriales (
    ID_Nanomaterial INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Nanomaterial NVARCHAR(150) NOT NULL,
    Tipo_Nanomaterial NVARCHAR(50) CHECK (Tipo_Nanomaterial IN ('Nanopartícula', 'Nanotubos', 'Grafeno', 'Quantum Dots', 'Nanocompuesto')),
    Composicion_Quimica NVARCHAR(200),
    Aplicacion NVARCHAR(100) CHECK (Aplicacion IN ('Catálisis', 'Electrónica', 'Medicina', 'Farmacéutica', 'Energía', 'Ambiental')),
    Tamanio_Promedio_nm DECIMAL(10,3),
    Descripcion NVARCHAR(500),
    Fecha_Desarrollo DATE,
    Costo_Estimado_Gramo DECIMAL(10,2),
    Estado_Desarrollo NVARCHAR(30) CHECK (Estado_Desarrollo IN ('Investigación', 'Desarrollo', 'Producción', 'Descontinuado'))
);

---------------------------------------------------------
-- 7. Registro de equipos de laboratorio

CREATE TABLE Equipamiento (
    ID_Equipo INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Equipo NVARCHAR(150) NOT NULL,
    Tipo_Equipo NVARCHAR(100) CHECK (Tipo_Equipo IN ('Síntesis', 'Caracterización', 'Análisis', 'Seguridad', 'Medición', 'Computacional')),
    Modelo NVARCHAR(100),
    Numero_Serie NVARCHAR(100) UNIQUE,
    Fabricante NVARCHAR(100),
    ID_Responsable INT FOREIGN KEY REFERENCES Empleados(ID_Empleado),
    Fecha_Adquisicion DATE,
    Costo_Adquisicion DECIMAL(12,2),
    Ubicacion NVARCHAR(100),
    Estado_Equipo NVARCHAR(30) DEFAULT 'Operativo' CHECK (Estado_Equipo IN ('Operativo', 'Mantenimiento', 'Averiado', 'Fuera de Servicio')),
    Frecuencia_Mantenimiento_Dias INT DEFAULT 90
);

----------------------------------------------------------
-- 8. Historial de mantenimiento

CREATE TABLE Mantenimiento_Equipos (
    ID_Mantenimiento INT PRIMARY KEY IDENTITY(1,1),
    ID_Equipo INT FOREIGN KEY REFERENCES Equipamiento(ID_Equipo),
    Tipo_Mantenimiento NVARCHAR(50) CHECK (Tipo_Mantenimiento IN ('Preventivo', 'Correctivo', 'Calibración', 'Actualización')),
    Fecha_Mantenimiento DATE NOT NULL,
    ID_Tecnico INT FOREIGN KEY REFERENCES Empleados(ID_Empleado),
    Descripcion_Trabajo NVARCHAR(500),
    Costo_Mantenimiento DECIMAL(10,2),
    Proximo_Mantenimiento DATE,
    Estado_Resultado NVARCHAR(30) CHECK (Estado_Resultado IN ('Exitoso', 'Requiere Seguimiento', 'Requiere Reparación'))
);

-----------------------------------------------------------
-- 9. Registro de ordenes de produccion de nano materiales

CREATE TABLE Ordenes_Sintesis (
    ID_Orden INT PRIMARY KEY IDENTITY(1,1),
    Codigo_Orden AS ('ORD-' + RIGHT('0000' + CAST(ID_Orden AS VARCHAR(10)), 4)),
    ID_Nanomaterial INT FOREIGN KEY REFERENCES Nanomateriales(ID_Nanomaterial),
    ID_Empleado_Responsable INT FOREIGN KEY REFERENCES Empleados(ID_Empleado),
    ID_Equipo_Principal INT FOREIGN KEY REFERENCES Equipamiento(ID_Equipo),
    Fecha_Inicio DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Fin_Estimada DATETIME,
    Fecha_Fin_Real DATETIME,
    Cantidad_Objetivo DECIMAL(10,3) NOT NULL,
    Unidad_Cantidad NVARCHAR(20) CHECK (Unidad_Cantidad IN ('g', 'kg', 'mg', 'unidades')),
    Prioridad NVARCHAR(20) DEFAULT 'Normal' CHECK (Prioridad IN ('Baja', 'Normal', 'Alta', 'Urgente')),
    Estado_Orden NVARCHAR(30) DEFAULT 'Planificada' CHECK (Estado_Orden IN ('Planificada', 'En Proceso', 'Completada', 'Cancelada', 'Fallida')),
    Observaciones NVARCHAR(500),
    Costo_Total DECIMAL(12,2)
);

------------------------------------------------------------
-- 10. Ordenes y reactivos utilizados

CREATE TABLE Orden_Reactivos (
    ID_Orden_Reactivo INT PRIMARY KEY IDENTITY(1,1),
    ID_Orden INT FOREIGN KEY REFERENCES Ordenes_Sintesis(ID_Orden),
    ID_Reactivo INT FOREIGN KEY REFERENCES Reactivos(ID_Reactivo),
    ID_Inventario INT FOREIGN KEY REFERENCES Inventario_Reactivos(ID_Inventario),
    Cantidad_Consumida DECIMAL(10,3) NOT NULL CHECK (Cantidad_Consumida > 0),
    Costo_Unitario_Momento DECIMAL(10,2) NOT NULL, -- Costo en el momento del consumo
    Fecha_Consumo DATETIME DEFAULT GETDATE(),
    Costo_Parcial AS (Cantidad_Consumida * Costo_Unitario_Momento) PERSISTED,
    CONSTRAINT UQ_Orden_Reactivo UNIQUE (ID_Orden, ID_Reactivo, ID_Inventario)
);

------------------------------------------------------------
-- 11. Registro de cada sintesis

CREATE TABLE Parametros_Proceso (
    ID_Parametro INT PRIMARY KEY IDENTITY(1,1),
    ID_Orden INT FOREIGN KEY REFERENCES Ordenes_Sintesis(ID_Orden),
    Temperatura_Celsius DECIMAL(6,2),
    Presion_Atmosferas DECIMAL(6,3),
    Duracion_Minutos INT,
    pH_Solucion DECIMAL(4,2) CHECK (pH_Solucion BETWEEN 0 AND 14),
    Velocidad_Agitacion_RPM INT,
    Atmosfera NVARCHAR(30) CHECK (Atmosfera IN ('Aire', 'Nitrógeno', 'Argón', 'Vacío', 'Oxígeno')),
    Metodo_Sintesis NVARCHAR(100),
    Notas_Adicionales NVARCHAR(500)
);

------------------------------------------------------------
-- 12. calidad nanomateriales producidos 

CREATE TABLE Control_Calidad (
    ID_Control INT PRIMARY KEY IDENTITY(1,1),
    ID_Orden INT FOREIGN KEY REFERENCES Ordenes_Sintesis(ID_Orden),
    Fecha_Evaluacion DATE DEFAULT GETDATE(),
    ID_Evaluador INT FOREIGN KEY REFERENCES Empleados(ID_Empleado),
    Rendimiento_Porcentaje DECIMAL(5,2) CHECK (Rendimiento_Porcentaje BETWEEN 0 AND 100),
    Pureza_Porcentaje DECIMAL(5,2) CHECK (Pureza_Porcentaje BETWEEN 0 AND 100),
    Tamanio_Medido_nm DECIMAL(10,3),
    Resultado_Evaluacion NVARCHAR(30) CHECK (Resultado_Evaluacion IN ('Aprobado', 'Rechazado', 'Requiere Re-análisis')),
    Tecnica_Analisis NVARCHAR(100),
    Observaciones_Calidad NVARCHAR(500),
    ID_Equipo_Analisis INT FOREIGN KEY REFERENCES Equipamiento(ID_Equipo)
);

-------------------------------------------------------------
-- 13. trazabilidad lotes producidos

CREATE TABLE Lotes_Nanomateriales (
    ID_Lote INT PRIMARY KEY IDENTITY(1,1),
    Codigo_Lote AS ('LOTE-' + RIGHT('00000' + CAST(ID_Lote AS VARCHAR(10)), 5)),
    ID_Nanomaterial INT FOREIGN KEY REFERENCES Nanomateriales(ID_Nanomaterial),
    ID_Orden INT FOREIGN KEY REFERENCES Ordenes_Sintesis(ID_Orden),
    Cantidad_Producida DECIMAL(10,3),
    Unidad_Medida NVARCHAR(20),
    Fecha_Produccion DATE DEFAULT GETDATE(),
    Fecha_Vencimiento DATE,
    Ubicacion_Almacen NVARCHAR(50),
    Estado_Lote NVARCHAR(30) DEFAULT 'Disponible' CHECK (Estado_Lote IN ('Disponible', 'Reservado', 'Vendido', 'Vencido', 'Descartado'))
);

--------------------------------------------------------------
-- 14. log de cambios en inventario

CREATE TABLE Auditoria_Inventario (
    ID_Auditoria INT PRIMARY KEY IDENTITY(1,1),
    ID_Inventario INT FOREIGN KEY REFERENCES Inventario_Reactivos(ID_Inventario),
    ID_Reactivo INT FOREIGN KEY REFERENCES Reactivos(ID_Reactivo),
    Operacion NVARCHAR(20) CHECK (Operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    Cantidad_Anterior DECIMAL(10,3),
    Cantidad_Nueva DECIMAL(10,3),
    Usuario NVARCHAR(100) DEFAULT SYSTEM_USER,
    Fecha_Operacion DATETIME DEFAULT GETDATE(),
    Motivo NVARCHAR(200)
);
