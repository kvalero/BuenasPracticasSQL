USE Tests;
SET NOCOUNT ON;
GO

/* Algunas peculiaridades de las fechas */

-- Hay muchos formatos ambiguos para escribir fechas
-- Dependen del idioma del usuario, la base de datos, etc

-- SET LANGUAGE FRENCH;

SELECT CONVERT(datetime, '2017.07.06')
UNION ALL
SELECT CONVERT(datetime, '07/06/2017')
UNION ALL
SELECT CONVERT(datetime, '2017-07-06 12:34:56.789');

-- para datetime y datetime2 los únicos seguros son:
SELECT CONVERT(datetime, '20170706')
UNION ALL
SELECT CONVERT(datetime, '2017-07-06T12:34:56.789')
UNION ALL
SELECT CONVERT(datetime, '20170708 12:34:56.789');

-- para date, se puede usar YYYYMMDD o YYYY-MM-DD
SELECT CONVERT(date, '2017.07.06')
UNION ALL
SELECT CONVERT(date, '07/06/2017');


SELECT CONVERT(date, '20170706')
UNION ALL
SELECT CONVERT(date, '2017-07-06');

-- SET LANGUAGE US_ENGLISH;


-- Siempre usen la función DATEADD si quieren sumar días
-- no usen simplemente columna_date + 1

DECLARE @fecha datetime = GETDATE();
SELECT @fecha + 1;
GO


DECLARE @fecha2 datetime2 = GETDATE();
SELECT @fecha2 + 1;
GO

-- y si es date?
DECLARE @fecha3 date = GETDATE();
SELECT @fecha3 + 1;
GO

-- lo correcto
DECLARE @fecha datetime = GETDATE(),@fecha2 datetime2 = GETDATE(),@fecha3 date = GETDATE();

SELECT	DATEADD(DAY,1,@fecha),
		DATEADD(DAY,1,@fecha2),
		DATEADD(DAY,1,@fecha3);


-- NO usen las abreviaciones cuando usen las funciones de fecha/tiempo
DECLARE @fecha datetime = GETDATE();

SELECT DATEPART(D,@fecha)    
UNION ALL 
SELECT DATEPART(W,@fecha)   
UNION ALL 
SELECT DATEPART(M,@fecha)   
UNION ALL 
SELECT DATEPART(Y,@fecha)   

-- usen MONTH, YEAR, etc
SELECT DATEPART(DAY,@fecha)    
UNION ALL 
SELECT DATEPART(WEEK,@fecha)   
UNION ALL 
SELECT DATEPART(MONTH,@fecha)   
UNION ALL 
SELECT DATEPART(YEAR,@fecha)   



-- Eviten usar BETWEEN para períodos de tiempo
-- o al menos, tengan presente sus dificultades

DROP TABLE IF EXISTS dbo.Ventas;

CREATE TABLE dbo.Ventas
(
  FechaVenta datetime2
);
GO

INSERT dbo.Ventas(FechaVenta) VALUES
  ('20170501 00:00'),
  ('20170501 01:00'),
  ('20170521 00:00'),
  ('20170531 04:00'),
  ('20170531 13:27:32.534'),
  ('20170531 23:59:59.9999999'),
  ('20170601 00:00');
GO

SELECT FechaVenta 
FROM dbo.Ventas
ORDER BY FechaVenta;
GO

-- ahora, qué pasa si uso algunos parámetros tipo datetime?
DECLARE @inicio datetime = '20170501', @fin datetime = DATEADD(MILLISECOND, -3, '20170601');

SELECT FechaVenta, @inicio, @fin 
FROM dbo.Ventas
WHERE FechaVenta BETWEEN @inicio AND @fin;
GO

-- y con smalldatetime?
DECLARE @inicio smalldatetime = '20170501', @fin smalldatetime = DATEADD(MILLISECOND, -3, '20170601');

SELECT FechaVenta, @inicio, @fin 
FROM dbo.Ventas
WHERE FechaVenta BETWEEN @inicio AND @fin;
GO


-- ahora con date:
DECLARE @inicio date = '20170501', @fin date = DATEADD(MILLISECOND, -3, '20170601');

SELECT FechaVenta, @inicio, @fin 
FROM dbo.Ventas
WHERE FechaVenta BETWEEN @inicio AND @fin;
GO


-- conocen la función EOMONTH?:
DECLARE @inicio datetime = '20170501'

SELECT FechaVenta, @inicio, EOMONTH(@inicio) 
FROM dbo.Ventas
WHERE FechaVenta BETWEEN @inicio AND EOMONTH(@inicio);
GO


-- Mejor usar rangos con una condición de < estricto
DECLARE @inicio date = '20170501';

SELECT FechaVenta, @inicio, DATEADD(MONTH,1,@inicio) 
FROM dbo.Ventas
WHERE FechaVenta >= @inicio 
AND FechaVenta < DATEADD(MONTH,1,@inicio);


DROP TABLE dbo.Ventas;
GO


-- Conocen la función FORMAT?
SELECT	FORMAT(GETDATE(),'yyyyMMdd') fecha,
		FORMAT(GETDATE(),'yyyy MMMM, dd') fecha2;


-- Si no necesitan formatos extraños, es mejor usar CONVERT:

DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

DECLARE @v1 varchar(8);

SELECT @v1 = FORMAT(modify_date,'yyyyMMdd') 
FROM sys.all_objects;
GO
-- sí, no usé TOP 1 a propósito

DECLARE @v1 varchar(8);
SELECT @v1 = CONVERT(CHAR(8),modify_date,112) 
FROM sys.all_objects;
GO

-- y el performance?
SELECT	Operacion = 
		CASE 
			WHEN t.[text] LIKE N'%FORMAT(%' THEN 'Format' 
			ELSE 'Convert' 
		 END, 
		qs.total_elapsed_time 
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) AS t
WHERE t.[text] LIKE N'%@v1 = %';


-- Sólo para recordar, eviten usar funciones sobre columnas al hacer filtros

SELECT	DISTINCT TOP (100000) 
		Id = o.object_id, 
		c.Column_Id, 
		o.Modify_Date
INTO dbo.Objetos
FROM sys.all_objects AS o
CROSS JOIN sys.all_columns AS c;
GO

CREATE UNIQUE CLUSTERED INDEX ui ON dbo.Objetos(Id, Column_Id);
GO
CREATE INDEX i ON dbo.Objetos(Modify_Date);
GO
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
GO 

SELECT *
FROM dbo.Objetos
WHERE Modify_date >= '20160101'
AND Modify_date < '20170101';


SELECT *
FROM dbo.Objetos
WHERE DATEPART(YEAR,Modify_date) = 2016;


SELECT *
FROM dbo.Objetos
WHERE CONVERT(CHAR(4),Modify_date,112) = '2016';
-- se recibe un warning

