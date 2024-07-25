--Elimino la base de datos en caso que exista
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'Pokemon_sql')
BEGIN
    DROP DATABASE Pokemon_sql;
END
GO

--Creo la base de datos, con los nombres y la ubicacion
CREATE DATABASE Pokemon_sql
ON PRIMARY (NAME = Pokemon_sql_Data, FILENAME = 'C:\sql_data\Pokemon_sql_new.mdf')
LOG ON (NAME = Pokemon_sql_Log, FILENAME = 'C:\sql_data\PokemonDB_sql_log_new.ldf');
GO

--Cambio para usar esta base de datos
USE Pokemon_sql;
GO

-- Elimino la tabla pokemones, si es que ya existe 
IF OBJECT_ID('Pokemones', 'U') IS NOT NULL
    DROP TABLE Pokemones;
GO

-- Elimino la tabla Entrenadores, si es que ya existe 
IF OBJECT_ID('Entrenadores', 'U') IS NOT NULL
    DROP TABLE Entrenadores;
GO

-- Elimino la tabla Entrenadores_Pokemones, si es que ya existe 
IF OBJECT_ID('Entrenadores_Pokemones', 'U') IS NOT NULL
    DROP TABLE Entrenadores_Pokemones;
GO

-- Elimino la tabla Batallas, si es que ya existe 
IF OBJECT_ID('Batallas', 'U') IS NOT NULL
    DROP TABLE Batallas;
GO

--Creo la tabla de pokemones, establezco su PK, nombre, tipo, habilidad, victorias y derrotas.
CREATE TABLE Pokemones (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(50) NOT NULL,
    Tipo NVARCHAR(20) CHECK (Tipo IN ('Fuego', 'Agua', 'Viento')) NOT NULL,
    Habilidad INT CHECK (Habilidad >= 0 AND Habilidad <= 1000) NOT NULL,
    Victorias INT CHECK (Victorias >= 0) NOT NULL,
    Derrotas INT CHECK (Derrotas >= 0) NOT NULL
);
GO

--inserto datos en la tabla pokemon
INSERT INTO Pokemones (Nombre, Tipo, Habilidad, Victorias, Derrotas)
VALUES ('Charmander', 'Fuego', 850, 30, 10),
       ('Squirtle', 'Agua', 600, 20, 5),
       ('Pidgey', 'Viento', 400, 15, 8),
	   ('Pikachu', 'Fuego', 950, 22, 2),
	   ('NoelioDeCaz', 'Fuego', 750, 23, 12),
	   ('ChuchaPat', 'Agua', 650, 28, 15),
       ('BurroRub', 'Viento', 620, 20, 5),
       ('MatuteFa', 'Agua',670, 15, 8),
	   ('MoccaLov', 'Fuego', 625, 12, 1),
	   ('FridaTer', 'Viento', 400, 23, 10);
GO

--creo tabla de entrenadores, id es la PK, agrego nombre, tipo, habilidad, victorias y derrotas
CREATE TABLE Entrenadores (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(50) NOT NULL,
    Tipo NVARCHAR(20) CHECK (Tipo IN ('Junior', 'Pro', 'Legendario')) NOT NULL,
    Habilidad INT CHECK (Habilidad >= 0 AND Habilidad <= 1000) NOT NULL,
    Victorias INT CHECK (Victorias >= 0) NOT NULL,
    Derrotas INT CHECK (Derrotas >= 0) NOT NULL
);
GO

--inserto datos en la tabla entrenadores
INSERT INTO Entrenadores(Nombre, Tipo, Habilidad, Victorias, Derrotas)
VALUES ('DaniVil', 'Legendario', 800, 30, 10),
       ('GustLo', 'Legendario', 600, 20, 5),
       ('TitiEsp', 'Pro', 750, 15, 8),
	   ('LuchoBeltran', 'Junior', 100, 2, 20),
	   ('SaraLez', 'Pro', 750, 23, 12),
	   ('ChichoAl', 'Pro', 850, 28, 15),
       ('HocoTiz', 'Pro', 620, 20, 5),
       ('RodriAr', 'Pro',670, 15, 8),
	   ('JulioMa', 'Legendario', 850, 12, 1),
	   ('TerereX', 'Legendario', 400, 23, 10);
GO

-- Creo la tabla Entrenadores_Pokemones para asociar entrenadores y pokemones
CREATE TABLE Entrenadores_Pokemones (
    Entrenador_Id INT NOT NULL,
    Pokemon_Id INT NOT NULL,
    PRIMARY KEY (Pokemon_Id), -- Cambio la clave primaria para asegurar que cada Pokémon esté asignado solo a un entrenador
    FOREIGN KEY (Entrenador_Id) REFERENCES Entrenadores(Id),
    FOREIGN KEY (Pokemon_Id) REFERENCES Pokemones(Id)
);
GO

-- Asigno pokemones a los entrenadores
INSERT INTO Entrenadores_Pokemones (Entrenador_Id, Pokemon_Id)
VALUES   
	(1, 2),  -- DaniVil también tiene a Squirtle
    (1, 4),  -- DaniVil también tiene a Pidgey
    (2, 3),  -- GustLo también tiene a Pikachu
    (2, 5),  -- GustLo también tiene a NoelioDeCaz
    (3, 6);  -- TitiEsp también tiene a ChuchaPat
GO

-- Consultar todos los pokemones de cada entrenador con IDs
SELECT 
    e.Id AS Entrenador_Id,
    e.Nombre AS Entrenador,
    p.Id AS Pokemon_Id,
    p.Nombre AS Pokemon
FROM 
    Entrenadores_Pokemones ep
JOIN 
    Entrenadores e ON ep.Entrenador_Id = e.Id
JOIN 
    Pokemones p ON ep.Pokemon_Id = p.Id
ORDER BY 
    e.Nombre;
GO

-- Crear la tabla Batallas, control solo puede ser ganador uno de los contendientes
CREATE TABLE Batallas (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Fecha DATETIME NOT NULL,
    Entrenador1_Id INT NOT NULL,
    Pokemon1_Id INT NOT NULL,
    Entrenador2_Id INT NOT NULL,
    Pokemon2_Id INT NOT NULL,
    Ganador INT NOT NULL,
    FOREIGN KEY (Entrenador1_Id) REFERENCES Entrenadores(Id),
    FOREIGN KEY (Pokemon1_Id) REFERENCES Pokemones(Id),
    FOREIGN KEY (Entrenador2_Id) REFERENCES Entrenadores(Id),
    FOREIGN KEY (Pokemon2_Id) REFERENCES Pokemones(Id),
    FOREIGN KEY (Ganador) REFERENCES Entrenadores(Id),
    CHECK (Ganador = Entrenador1_Id OR Ganador = Entrenador2_Id),
);
GO

-- Elimino el trigger si ya existe
IF OBJECT_ID('trg_ValidarEntrenadorPokemon', 'TR') IS NOT NULL
    DROP TRIGGER trg_ValidarEntrenadorPokemon;
GO

-- Crear trigger para validar que un entrenador solo pueda seleccionar pokemones que tiene asignado
CREATE TRIGGER trg_ValidarEntrenadorPokemon
ON Batallas
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar entrenador1 y pokemon1
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM Entrenadores_Pokemones ep
            WHERE ep.Entrenador_Id = i.Entrenador1_Id
              AND ep.Pokemon_Id = i.Pokemon1_Id
        )
    )
    BEGIN
        RAISERROR ('El Entrenador1 no tiene asignado el Pokemon1.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Validar entrenador2 y pokemon2
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM Entrenadores_Pokemones ep
            WHERE ep.Entrenador_Id = i.Entrenador2_Id
              AND ep.Pokemon_Id = i.Pokemon2_Id
        )
    )
    BEGIN
        RAISERROR ('El Entrenador2 no tiene asignado el Pokemon2.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Insertar o actualizar los registros en la tabla Batallas
    INSERT INTO Batallas (Fecha, Entrenador1_Id, Pokemon1_Id, Entrenador2_Id, Pokemon2_Id, Ganador)
    SELECT Fecha, Entrenador1_Id, Pokemon1_Id, Entrenador2_Id, Pokemon2_Id, Ganador
    FROM inserted;
END;
GO

-- Elimino el trigger si ya existe
IF OBJECT_ID('trg_EliminarEntrenadoresPokemones', 'TR') IS NOT NULL
    DROP TRIGGER trg_EliminarEntrenadoresPokemones;
GO

-- Crear trigger para eliminar registros relacionados de Entrenadores_Pokemones y Batallas antes de eliminar un Pokemon
CREATE TRIGGER trg_EliminarEntrenadoresPokemones
ON Pokemones
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @deletedPokemones TABLE (Id INT);
    INSERT INTO @deletedPokemones (Id)
    SELECT Id
    FROM deleted;

    -- Eliminar registros relacionados en Entrenadores_Pokemones
    DELETE FROM Entrenadores_Pokemones
    WHERE Pokemon_Id IN (SELECT Id FROM @deletedPokemones);

    -- Eliminar registros relacionados en Batallas
    DELETE FROM Batallas
    WHERE Pokemon1_Id IN (SELECT Id FROM @deletedPokemones)
       OR Pokemon2_Id IN (SELECT Id FROM @deletedPokemones);

    -- Eliminar el Pokemon
    DELETE FROM Pokemones
    WHERE Id IN (SELECT Id FROM @deletedPokemones);
END;
GO


-- Insertar datos en la tabla Batallas
INSERT INTO Batallas (Fecha, Entrenador1_Id, Pokemon1_Id, Entrenador2_Id, Pokemon2_Id, Ganador)
VALUES
    ('2024-07-03 12:00:00', 1, 2, 2, 3, 1),  -- DaniVil vs GustLo
    ('2024-07-03 12:00:00', 1, 4, 2, 5, 1),  -- DaniVil vs GustLo
    ('2024-07-03 12:00:00', 3, 6, 2, 3, 2);  -- TitiEsp vs GustLo
GO

-- Consultar todas las batallas
SELECT 
    b.Id AS Batalla_Id,
    b.Fecha,
    e1.Nombre AS Entrenador1,
    p1.Nombre AS Pokemon1,
    e2.Nombre AS Entrenador2,
    p2.Nombre AS Pokemon2,
    CASE 
        WHEN b.Ganador = e1.Id THEN e1.Nombre
        WHEN b.Ganador = e2.Id THEN e2.Nombre
    END AS Ganador
FROM 
    Batallas b
JOIN 
    Entrenadores e1 ON b.Entrenador1_Id = e1.Id
JOIN 
    Pokemones p1 ON b.Pokemon1_Id = p1.Id
JOIN 
    Entrenadores e2 ON b.Entrenador2_Id = e2.Id
JOIN 
    Pokemones p2 ON b.Pokemon2_Id = p2.Id
ORDER BY 
    b.Fecha;
GO

-- Intento eliminar un pokemon para ver si se elimina correctamente de todas las tablas
DELETE FROM Pokemones WHERE Id IN (2);
GO

-- Consultar de nuevo todas las batallas para verificar el resultado
SELECT 
    b.Id AS Batalla_Id,
    b.Fecha,
    e1.Nombre AS Entrenador1,
    p1.Nombre AS Pokemon1,
    e2.Nombre AS Entrenador2,
    p2.Nombre AS Pokemon2,
    CASE 
        WHEN b.Ganador = e1.Id THEN e1.Nombre
        WHEN b.Ganador = e2.Id THEN e2.Nombre
    END AS Ganador
FROM 
    Batallas b
JOIN 
    Entrenadores e1 ON b.Entrenador1_Id = e1.Id
JOIN 
    Pokemones p1 ON b.Pokemon1_Id = p1.Id
JOIN 
    Entrenadores e2 ON b.Entrenador2_Id = e2.Id
JOIN 
    Pokemones p2 ON b.Pokemon2_Id = p2.Id
ORDER BY 
    b.Fecha;
GO

-- Consultar de nuevo todos los pokemones de cada entrenador con IDs para verificar el resultado
SELECT 
    e.Id AS Entrenador_Id,
    e.Nombre AS Entrenador,
    p.Id AS Pokemon_Id,
    p.Nombre AS Pokemon
FROM 
    Entrenadores_Pokemones ep
JOIN 
    Entrenadores e ON ep.Entrenador_Id = e.Id
JOIN 
    Pokemones p ON ep.Pokemon_Id = p.Id
ORDER BY 
    e.Nombre;
GO

-- Consulto las batallas y el nombre del entrenador ganador
SELECT 
    b.Id AS Batallas_Id,
    b.Fecha,
    e.Nombre AS Ganador_Nombre
FROM 
    Batallas b
JOIN 
    Entrenadores e
ON 
    b.Ganador = e.Id;
GO

-- Eliminar un o varios Entrenadores
DELETE FROM Entrenadores
WHERE Id IN (20);

-- Eliminar una o varias Batallas
DELETE FROM Batallas
WHERE Id IN (20);

--Consulta la tabla de pokemones 
SELECT * FROM Pokemones;
GO

--Consulto la tabla de Entrenadores
SELECT * FROM Entrenadores;
GO

--Consulta la tabla de Batallas
SELECT * FROM Batallas;
GO

-- Actualizo un Pokémon
UPDATE Pokemones
SET Nombre = 'Alfred', -- Nuevo nombre
    Tipo = 'Fuego',       -- Nuevo tipo
    Habilidad = 950,      -- Nueva habilidad
    Victorias = 50,       -- Nuevas victorias
    Derrotas = 02         -- Nuevas derrotas
WHERE Id = 1;             -- Id del Pokémon que deseo actualizar
GO

-- Actualizo un Entrenador
UPDATE Entrenadores
SET Nombre = 'Danivil', -- Nuevo nombre
    Tipo = 'Legendario',       -- Nuevo tipo
    Habilidad = 800,      -- Nueva habilidad
    Victorias = 30,       -- Nuevas victorias
    Derrotas = 10         -- Nuevas derrotas
WHERE Id = 1;             -- Id del Entrenador que deseo actualizar
GO

-- Actualizo una Batalla
UPDATE Batallas
SET Fecha = '2024-07-03 12:00:00', -- Nueva fecha
    Entrenador1_Id = 1,       -- Nuevo entrenador1
    Pokemon1_Id = 1,      -- Nuevo pokemon1
    Entrenador2_Id = 2,       -- Nuevo entrenador2
    Pokemon2_Id = 2,	-- Nuevo pokemon2
	Ganador = 1			-- nuevo ganador
WHERE Id = 1;             -- Id de la Batalla que deseo actualizar
GO