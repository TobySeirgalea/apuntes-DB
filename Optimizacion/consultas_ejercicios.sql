
--Ejercicio 2:

--SELECT SalesOrderID, SalesOrderDetailID
--FROM Sales.SalesOrderDetail
--WHERE SalesOrderID = 58950

--SELECT SalesOrderID, SalesOrderDetailID
--FROM Sales.SalesOrderDetail
--WHERE SalesOrderDetailID = 68531


--Ejercicio 3:
--SELECT SalesOrderID, SalesOrderDetailID
--FROM Sales.SalesOrderDetail
--WHERE SalesOrderID = 43683 AND SalesOrderDetailID = 240

--SELECT SalesOrderID, SalesOrderDetailID
--FROM Sales.SalesOrderDetail
--WHERE SalesOrderID = 43683 OR SalesOrderDetailID = 240

--Ejercicio 4:
-- SELECT ProductID, PV.BusinessEntityID, Name
-- FROM Purchasing.ProductVendor PPV 
--     JOIN Purchasing.Vendor PV
--         ON (PPV.BusinessEntityID =PV.BusinessEntityID)

-- SELECT ProductID, PV.BusinessEntityID, Name
-- FROM Purchasing.ProductVendor PPV 
--     JOIN Purchasing.Vendor PV
--         ON (PPV.BusinessEntityID =PV.BusinessEntityID)
-- WHERE StandardPrice > $10

-- SELECT ProductID, PV.BusinessEntityID, Name
-- FROM Purchasing.ProductVendor PPV 
--     JOIN Purchasing.Vendor PV
--         ON (PPV.BusinessEntityID =PV.BusinessEntityID)
-- WHERE StandardPrice > $10 AND Name LIKE N'F%'


--Ejercicio 4:
SELECT P.Name, PSC.Name SubCatrom
FROM Production.Product P
JOIN Production.ProductSubcategory PSC
ON p.ProductSubcategoryID = psc.ProductSubcategoryID

SELECT P.Name, PSC.Name SubCatrom
FROM Production.Product P
JOIN Production.ProductSubcategory PSC
ON p.ProductSubcategoryID = psc.ProductSubcategoryID
ORDER BY psc.ProductSubcategoryID

--Queries auxiliares:

-- SELECT
-- object_name(cols.object_id) tabla
-- ,cols.name columna
-- ,ind.name indice
-- ,ind.type_desc tipo
-- ,ind.is_unique
-- FROM
-- sys.columns cols, sys.indexes ind , sys.index_columns ind_cols
-- where
-- cols.object_id = ind.object_id
-- and cols.object_id = ind_cols.object_id
-- and cols.column_id = ind_cols.column_id
-- and ind.index_id = ind_cols.index_id
-- and object_name(cols.object_id) LIKE 'Vendor'
-- order by object_name(cols.object_id), ind.name;

-- SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE
-- FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE table_name = 'SalesOrderDetail';