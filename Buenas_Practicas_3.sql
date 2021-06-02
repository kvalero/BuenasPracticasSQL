USE Tests;
SET NOCOUNT ON;
GO

/* Una tabla NO TIENE un orden inherente, la única forma de asegurar 
   un resultado ordenado, es usando ORDER BY                          */

CREATE TABLE dbo.Nombres
(
  Id int PRIMARY KEY, 
  Nombre varchar(200)
);
GO

-- insertemos registros en orden no alfabético

INSERT dbo.Nombres(Id,Nombre) 
VALUES	(1,'marco'),
		(2,'kamal'),
		(3,'alberto');

-- el resultado de esta consulta la va a ordenar según la llave primaria
-- porque es lo óptimo en este caso
SELECT Id,Nombre
FROM dbo.Nombres;

-- ahora alguien crea otro índice
CREATE INDEX i1 ON dbo.Nombres(Nombre);

-- ahora el método óptimo es hacer un scan en este índice
SELECT Id,Nombre
FROM dbo.Nombres;


-- Algunos usan TOP 100 PERCENT...ORDER BY en subconsultas
-- pero esto no ayuda...
SELECT Id,Nombre
FROM (	SELECT TOP (100) PERCENT 
				Id,Nombre 
		FROM dbo.Nombres 
		ORDER BY Id) AS x;

-- tampoco hacer un ordenamiento implícito usando ROW_NUMBER
WITH CTE AS 
(
	SELECT	Id,Nombre , 
			RN = ROW_NUMBER() OVER (ORDER BY Id) 
	FROM dbo.Nombres
)
SELECT Id,Nombre  
FROM CTE;

-- quizás si la función window se materializa, pero no es seguro
WITH CTE AS 
(
	SELECT	Id,Nombre , 
			RN = ROW_NUMBER() OVER (ORDER BY Id) 
	FROM dbo.Nombres
)
SELECT Id,Nombre,RN
FROM CTE;

-- En fin, para asegurar un orden, deben usar ORDER BY sobre el resultado completo!
SELECT Id, Nombre
FROM dbo.Nombres
ORDER BY Id;

-- (por favor no usen ORDER BY 1, 2, .....)

DROP TABLE dbo.Nombres;
GO





-- Orden de evaluación de los comandos
-- SQL es un lenguaje DECLARATIVO

CREATE TABLE dbo.AlgunosNumeros
(
	ID int, 
	Puntaje varchar(20)
);

CREATE TABLE dbo.Relacionada
(
  ID int
);

INSERT dbo.AlgunosNumeros(ID, Puntaje) 
VALUES	(1,'50'),
		(2,'Marco'),
		(4,'71');

INSERT dbo.Relacionada(ID) 
VALUES	(1), 
		(4), 
		(13), 
		(350);
GO

SELECT n.ID, n.Puntaje * 5
FROM dbo.AlgunosNumeros AS n
INNER JOIN dbo.Relacionada AS r
	ON n.ID = r.ID;
GO

WITH Numeros AS
(
  SELECT ID, Puntaje
  FROM dbo.AlgunosNumeros
  WHERE ISNUMERIC(Puntaje) = 1
  --WHERE Puntaje NOT LIKE '%[^0-9]%' 
)
SELECT ID, Puntaje
FROM Numeros
WHERE Puntaje > 10;
GO

-- qué hacer?
SELECT	n.ID, 
		5 * CASE WHEN ISNUMERIC(n.Puntaje) = 1 
				 THEN n.Puntaje 
				 ELSE NULL 
			END,
		TRY_CONVERT(int, n.Puntaje) * 5 -- desde SQL Server 2012
FROM dbo.AlgunosNumeros AS n
INNER JOIN dbo.Relacionada AS r
	ON n.ID = r.ID;
GO

DROP TABLE dbo.AlgunosNumeros, dbo.Relacionada;
