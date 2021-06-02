USE Tests;
SET NOCOUNT ON;
GO

-- Los cursores tienen su uso (no son el demonio)
-- pero si los usan, al menos usen el tipo correcto
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
GO

DECLARE @v1 sysname, @v2 datetime2 = GETDATE();

DECLARE CC CURSOR FOR
SELECT o1.name 
FROM sys.all_objects AS o1
CROSS JOIN (SELECT TOP (100) name 
			FROM sys.all_objects) AS o2;

OPEN CC; 
FETCH NEXT FROM CC INTO @v1;
WHILE @@FETCH_STATUS <> -1
BEGIN
  SET @v1 = @v1 + N'';
  FETCH NEXT FROM CC INTO @v1;
END

CLOSE CC; 
DEALLOCATE CC;

SELECT DATEDIFF(MILLISECOND, @v2, SYSDATETIME());

-- ahora usando LOCAL FAST_FORWARD
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
GO

DECLARE @v1 sysname, @v2 datetime2 = GETDATE();

DECLARE CC CURSOR LOCAL FAST_FORWARD FOR
SELECT o1.name 
FROM sys.all_objects AS o1
CROSS JOIN (SELECT TOP (100) name 
			FROM sys.all_objects) AS o2;

OPEN CC; 
FETCH NEXT FROM CC INTO @v1;
WHILE @@FETCH_STATUS <> -1
BEGIN
  SET @v1 = @v1 + N'';
  FETCH NEXT FROM CC INTO @v1;
END

CLOSE CC; 
DEALLOCATE CC;

SELECT DATEDIFF(MILLISECOND, @v2, SYSDATETIME());




-- NO usen SELECT * en produccíón!!!!!!!!!!!

CREATE TABLE dbo.t1(c1 int, c2 int);
GO

INSERT dbo.t1(c1,c2) 
VALUES(1,2);
GO

CREATE VIEW dbo.v_t1
AS
  SELECT * 
  FROM dbo.t1;
GO

-- qué pasa si hacemos cambios a la tabla?
EXEC sys.sp_rename N'dbo.t1.c2', N'c3', N'COLUMN';

ALTER TABLE dbo.t1 ADD c2 date 
    NOT NULL DEFAULT GETDATE();

ALTER TABLE dbo.t1 ADD c4 uniqueidentifier 
    NOT NULL DEFAULT NEWID();
GO

-- la vista muestra data incorrecta
SELECT * FROM dbo.t1;
SELECT * FROM dbo.v_t1;
GO

EXEC sys.sp_refreshview @viewname = N'dbo.v_t1';
GO

SELECT * FROM dbo.v_t1;
GO


-- Ahora, si realmente quieren evitar que desarrolladores usen SELECT *
-- y han tenido un mal día: 
-- crédito a Remus Rusanu

ALTER TABLE dbo.t1 ADD ["No usen SELECT * !!!"] AS 1/0;
GO

SELECT * FROM dbo.t1;
GO
SELECT c1,c2,c3 FROM dbo.t1;
GO

DROP VIEW dbo.v_t1;
DROP TABLE dbo.t1;



-- Si tienen una tabla grande, o que siempre está en uso
-- eviten usar COUNT(*)
SELECT ID = ROW_NUMBER() OVER(ORDER BY o1.object_id)
INTO dbo.Datos
FROM sys.all_objects AS o1
CROSS JOIN (SELECT TOP (100) *
			FROM sys.all_objects) o2;

SELECT COUNT(*) 
FROM dbo.Datos;

-- usen:
SELECT SUM([rows]) 
FROM sys.partitions 
WHERE [object_id] = OBJECT_ID(N'dbo.Datos')
AND index_id IN (0,1);








