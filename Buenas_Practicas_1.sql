DROP DATABASE IF EXISTS Tests;
GO

CREATE DATABASE Tests;
GO

USE Tests;


SET NOCOUNT ON;
GO


/* Entender cómo funcionan los NULL's */
DROP TABLE IF EXISTS dbo.Nulos;

CREATE TABLE dbo.Nulos(c1 int, c2 int, c3 int);

INSERT INTO dbo.Nulos
VALUES	(1,2,3),
		(4,NULL,5),
		(NULL,NULL,6),
		(0,5,10);

SELECT *
FROM dbo.Nulos
WHERE c1 <= 4;

SELECT *
FROM dbo.Nulos
WHERE c1 > 4;

SELECT *, c1+c2+c3 Total
FROM dbo.Nulos;

SELECT COUNT(*) N
FROM dbo.Nulos;

SELECT COUNT(c1) N
FROM dbo.Nulos;

SELECT SUM(c1) Suma
FROM dbo.Nulos;

SELECT AVG(c1*1.0) Promedio
FROM dbo.Nulos;

SELECT *
FROM dbo.Nulos
WHERE c1 = c2;

SELECT *
FROM dbo.Nulos
WHERE c1 != c2;

SELECT DISTINCT c2
FROM dbo.Nulos;

SELECT c2, N = COUNT(*) 
FROM dbo.Nulos
GROUP BY c2;

-- qué pasa si usamos UNION ALL?
SELECT c2
FROM dbo.Nulos
UNION ALL
SELECT c1
FROM dbo.Nulos;

-- qué pasa si usamos UNION?
SELECT c2
FROM dbo.Nulos
UNION
SELECT c1
FROM dbo.Nulos;


SELECT c2
FROM dbo.Nulos
EXCEPT
SELECT c1
FROM dbo.Nulos;

SELECT c2
FROM dbo.Nulos
INTERSECT
SELECT c1
FROM dbo.Nulos;

DROP TABLE dbo.Nulos;
GO



/* Siempre definan explícitamente el largo al usar tipos de datos string */

-- ejemplo 1: inconsistencia en el largo por defecto
DECLARE @a varchar = 'hola';

SELECT a, b, LEN(b) Largo_b
FROM (	SELECT a = @a, 
			   b = CONVERT(nvarchar, 'este es un string de ejemplo, no tengo imaginación para escribir muchas cosas')
	 ) x;


-- ejemplo 2

CREATE TABLE dbo.ejemplo2
(
  c1 varchar(max),
  c2 varchar(max),
  c3 varchar
);
GO

CREATE OR ALTER PROCEDURE dbo.ejemplo2_agregar_fila
  @v1 varchar,
  @v2 varchar(10),
  @v3 varchar
AS
BEGIN
  INSERT dbo.ejemplo2(c1,c2,c3) VALUES(@v1,@v2,@v3);
END
GO

EXEC dbo.ejemplo2_agregar_fila	@v1 = 'érase una vez un dato', 
								@v2 = 'en una galaxia muy muy lejana',
								@v3 = 'y colorín colorado.....';

SELECT c1, c2, c3 
FROM dbo.ejemplo2;

-- se perdieron datos....y no arrojó error

GO
DROP PROCEDURE dbo.ejemplo2_agregar_fila;
DROP TABLE dbo.ejemplo2;
GO



-- ejemplo 3: elegir el largo de los datos sí importa (tiempos de ejecución y memoria requerida)
DROP TABLE IF EXISTS dbo.t1, dbo.t2, dbo.t3;
GO

-- creamos tablas con 4 columnas con largos distintos
CREATE TABLE dbo.t1(a nvarchar(50), b nvarchar(50), c nvarchar(50), d nvarchar(50));

CREATE TABLE dbo.t2(a nvarchar(2000), b nvarchar(2000), c nvarchar(2000), d nvarchar(2000));

CREATE TABLE dbo.t3(a nvarchar(max), b nvarchar(max), c nvarchar(max), d nvarchar(max));
GO

-- insertamos datos
INSERT dbo.t1(a,b,c,d)
SELECT TOP (200000) 
		LEFT(c1.name,1), 
		RIGHT(c2.name,1), 
		ABS(c1.column_id/10), 
		ABS(c2.column_id%10)
FROM sys.all_columns c1
CROSS JOIN sys.all_columns c2
ORDER BY c2.[object_id];

INSERT dbo.t2(a,b,c,d) 
SELECT a,b,c,d 
FROM dbo.t1;

INSERT dbo.t3(a,b,c,d) 
SELECT a,b,c,d 
FROM dbo.t1;
GO

SET STATISTICS IO ON;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
GO

-- ejecutamos la misma consulta en las 3 tablas
SELECT	a,b,c,d, 
		ROW_NUMBER() OVER(PARTITION BY b, c ORDER BY d DESC)
FROM dbo.t1 
GROUP BY a,b,c,d 
ORDER BY c,a DESC;
GO

SELECT	a,b,c,d, 
		ROW_NUMBER() OVER(PARTITION BY b, c ORDER BY d DESC)
FROM dbo.t2
GROUP BY a,b,c,d 
ORDER BY c,a DESC;
GO

SELECT	a,b,c,d, 
		ROW_NUMBER() OVER(PARTITION BY b, c ORDER BY d DESC)
FROM dbo.t3
GROUP BY a,b,c,d 
ORDER BY c,a DESC;
GO

SELECT	Tabla						= SUBSTRING(t.[text],CHARINDEX(N'FROM ',t.[text])+5,6),
		[Memoria Requerida]			= s.max_ideal_grant_kb, 
		[Memoria Obtenida]			= s.last_grant_kb, 
		[Duración de la Consulta]   = s.last_elapsed_time -- en microsegundos
FROM sys.dm_exec_query_stats AS s
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) AS t
WHERE t.[text] LIKE N'%dbo.t[1-3]%'
ORDER BY Tabla;

DROP TABLE dbo.t1, dbo.t2, dbo.t3;
GO





/* Usar sp_ como prefijo de los procedimientos almacenados */
CREATE OR ALTER PROCEDURE dbo.sp_procedimiento1
AS
  CREATE TABLE #Temp1(c1 INT);
  INSERT INTO #Temp1
  VALUES (1);
GO

CREATE OR ALTER PROCEDURE dbo.procedimiento1
AS
  CREATE TABLE #Temp1(c1 INT);
  INSERT INTO #Temp1
  VALUES (1);
GO

CREATE OR ALTER PROCEDURE dbo.loop_sp1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @i INT = 1;
    WHILE @i <= 50
    BEGIN
      EXEC dbo.sp_procedimiento1;
      SET @i = @i + 1; -- o @i += 1
    END
END
GO

CREATE OR ALTER PROCEDURE dbo.loop_1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @i INT = 1;
    WHILE @i <= 50
    BEGIN
      EXEC dbo.procedimiento1;
      SET @i = @i + 1;
    END
END
GO

DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
GO

SELECT SYSDATETIME() Inicio;
GO
EXEC dbo.loop_sp1;
GO
SELECT SYSDATETIME() loop_sp1;
GO
EXEC dbo.loop_1;
GO
SELECT SYSDATETIME() loop_1;
GO


DECLARE @Tiempo1 datetime2, @Tiempo2 datetime2, @Tiempo3 datetime2;
SELECT	@Tiempo1 = '2017-05-24 23:54:42.1603193',
		@Tiempo2 = '2017-05-24 23:54:42.2228270',
		@Tiempo3 = '2017-05-24 23:54:42.2762380';

SELECT	DATEDIFF(NANOSECOND,@Tiempo1,@Tiempo2) loop_sp1,
		DATEDIFF(NANOSECOND,@Tiempo2,@Tiempo3) loop_1;
;




/* Mayúsculas y minúsculas */

-- Los tipos de datos, se escriben con mayúscula o minúscula?
-- Podemos ver sys.types
SELECT *
FROM sys.types;


CREATE DATABASE EjemploRaro COLLATE Latin1_General_BIN2; 
GO
USE EjemploRaro;
GO

SELECT geography::STGeomFromText('LINESTRING(-5 14, -8 11)', 4326);
GO
SELECT GEOGRAPHY::STGeomFromText('LINESTRING(-5 14, -8 1)', 4326);
GO

USE Tests;
GO
ALTER DATABASE EjemploRaro SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE EjemploRaro;

-- En general, nunca tendrán problemas con esto, pero es una buena práctica
-- escribir los tipos de datos en minúsculas (sí, a mí también me sorprende)



-- Y qué pasa con los nombres de objetos?
CREATE TABLE dbo.OrdenCliente(IdOrden int, IdCliente int);

SELECT idorden, idCLIENTE
FROM dbo.ordencliente;


DROP DATABASE IF EXISTS CaseSensitive;
GO
CREATE DATABASE CaseSensitive
COLLATE Modern_Spanish_CS_AS;
GO

USE CaseSensitive;
GO

CREATE TABLE dbo.OrdenCliente(IdOrden int, IdCliente int);

SELECT idorden, idCLIENTE
FROM dbo.ordencliente;
GO

SELECT IdOrden, IdCliente
FROM dbo.OrdenCliente;
GO

CREATE PROCEDURE dbo.sp1
AS
BEGIN
  SELECT idorden 
  FROM dbo.ordencliente;
END
GO

EXEC dbo.sp1;
GO


USE Tests;
GO
ALTER DATABASE CaseSensitive SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE CaseSensitive;
GO



-- Recomendación, usen punto y coma para terminar los comandos SQL
-- cada vez más comandos lo necesitan como obligatorio
CREATE TABLE #T1(c1 int);
GO

MERGE #T1 AS t
USING(VALUES (1),(2),(3)) AS c(c1)
ON t.c1 = c.c1
WHEN MATCHED THEN
   UPDATE SET c1 = c.c1
WHEN NOT MATCHED THEN
   INSERT (c1) VALUES (c.c1);
GO

DROP TABLE #T1;

-- CTEs necesitan que el comando anterior termine con un punto y coma
SELECT 1

WITH CTE(c1) AS
(
	SELECT 1
)
SELECT *
FROM CTE;



