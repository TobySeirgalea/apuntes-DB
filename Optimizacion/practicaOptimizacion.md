# Ejercicios de optimización

## Ejercicio 0.1

### Índices

|tabla     |columna      |indice                  |tipo        |is_unique |
|----------|-------------|------------------------|------------|----------|
|Product   |Name         |AK_Product_Name         |NONCLUSTERED|1         |
|Product   |ProductNumber|AK_Product_ProductNumber|NONCLUSTERED|1         |
|Product   |rowguid      |AK_Product_rowguid      |NONCLUSTERED|1         |
|Product   |ProductID    |PK_Product_ProductID    |CLUSTERED   |1         |

### Primer query

![Primer plan](./images/ej1_plan1.png)

- El `WHERE` se hace sobre `productNumber`, por lo que podemos utilizar el índice `AK_Product_ProductNumber` para obtener las filas que cumplen `ProductNumber ='EC-R098'` mediante él.
- Luego como el índice no cubre por completo la consulta, ya que en él no se encuentra el atributo `Name`, debe aplicar un `Key lookup` utilizando la clave de la tabla para esa fila `ProductID` que se encuentra en la hoja del mismo índice para acceder a la tabla `Product` y traerse el atributo `Name` correspondiente a esa fila.
- Notar que el plan requiere utilizar el orden dado por el índice `AK_Product_ProductNumber`, ya que tiene el campo `Ordered: True` entre sus propiedades, esto se debe a que mediante el orden lógico de ese índice puede encontrar más fácilmente qué fila se corresponde con un `ProductNumber ='EC-R098'`.
- Para hacer el `Key lookup` también utiliza el órden, pero en este caso no es un órden lógico, sino el físico de las filas de la tabla, por ser un índice *clustered*. Así puede encontrar qué fila es la que tiene el valor de la clave, para obtener el valor del atributo `Name`.
- En este caso ambas entradas del `Inner join` son pequeñas, por lo que se optó por un *Nested loop*.
- Al tratarse de una sola entrada, podríamos podríamos almacenar la de arriba en memoria y hacer un *Hash join*. También al estar ambas ordenadas podríamos utilizar un *Merge join*.
- Esa query es considerada trivial para el optimzador, por lo que no realizó ninguna búsqueda de optimización para el plan de ejecución.

### Segunda query

![Segundo plan](./images/ej1_plan2.png)

- En este caso por la misma razón que en el anterior se optó por utilizar el índice `AK_Product_ProductNumber`, pero para esta consulta sí que es un índice completo, ya que en su hoja encontramos también el `ProductID`, al igual que el `ProductNumber` por el que estamos buscando, así que no hace falta ningún `Key lookup` ni nada porque ya tenemos todos los atributos que necesitamos retornar.

## Ejercicio 0.2


tabla             columna             indice                                               tipo          is_unique 
----------------  ------------------  ---------------------------------------------------  ------------  ----------
SalesOrderDetail  rowguid             AK_SalesOrderDetail_rowguid                          NONCLUSTERED  1         
SalesOrderDetail  ProductID           IX_SalesOrderDetail_ProductID                        NONCLUSTERED  0         
SalesOrderDetail  SalesOrderDetailID  PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID  CLUSTERED     1         
SalesOrderDetail  SalesOrderID        PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID  CLUSTERED     1         

TABLE_NAME        COLUMN_NAME            IS_NULLABLE  DATA_TYPE       
----------------  ---------------------  -----------  ----------------
SalesOrderDetail  SalesOrderID           NO           int             
SalesOrderDetail  SalesOrderDetailID     NO           int             
SalesOrderDetail  CarrierTrackingNumber  YES          nvarchar        
SalesOrderDetail  OrderQty               NO           smallint        
SalesOrderDetail  ProductID              NO           int             
SalesOrderDetail  SpecialOfferID         NO           int             
SalesOrderDetail  UnitPrice              NO           money           
SalesOrderDetail  UnitPriceDiscount      NO           money           
SalesOrderDetail  LineTotal              NO           numeric         
SalesOrderDetail  rowguid                NO           uniqueidentifier
SalesOrderDetail  ModifiedDate           NO           datetime        

- La relación entre `Product` y `SalesOrderDetail` es 1:N, ya que la clave de `Product` está del lado de `SalesOrderDetail` como *foreign key*, lo que indice que para una fila de `SalesOrderDetail` hay una única en `Product` relacionada.
- Para la segunda query estima que hay una única fila que cumple, mientras que para la primera estima entre 20 y 21.
- Para la primera como tiene 121317 filas en total, que es mucha diferencia respecto a las 21 filas que espera devolver, entonces no conviene hacer un *scan*. Conviene utilizar el *clustered index*, que es el orden físico de las filas y que viene ordenado por su clave que está compuesta por `SalesOrderID` y `SalesOrderDetailID`, entonces las 21 filas con el valor de `SalesOrderId` buscado estarán contiguas en el *índice clustered*.
- Para la segunda query, como el *índice clustered* está ordenado primero por `SalesOrderID` y luego por `SalesOrderDetailID`, entonces todos los valores que coincidan en `SalesOrderDetailID` pero difieran en `SalesOrderID` van a estar separados y no contiguos en el índice, por lo que no puede hacer *seek* ya que no conoce el valor del salesOrderID con el que está como clave, debería hacer un *scan* del *clustered index* de 121317 filas. Como cada fila de `SalesOrderDetail` se relaciona con una sola de `Product`, entonces el índice con `ProductID` va a tener tantas entradas como valores distintos de `SalesOrderDetail` hayan en la tabla `SalesOrderDetail`, mientras que el *clustered* tendrá tantas filas como valores distintos de la tupla (`SalesOrderID`, `SalesOrderDetailID`) haya. Así que ya que es inevitable hacer un *scan*, lo hace por el índice más chico.

## Ejercicio 0.3

Ya antes de ejecutarlas y ver los planes se puede decir que la segunda será más costosa. Notar que no podemos hablar de óptima, ya que son consultas distintas. ¿Por qué? Por como está ordenado el *índice clustered*, primero por `SalesOrderID` y luego por `SalesOrderDetaildID`, vamos a tener para la primer cláusula `WHERE` una sola fila posible y la podemos encontrar directamente con un *seek*, ya que todas las que tengan `SalesOrderID = 43683` estarán contiguas en el *índice clustered*. En cambio para la segunda no podemos hacer lo mismo, ya que las filas que cumplan con la segunda condición del `OR` las debemos buscar por separado y no las podemos obtener todas en el mismo *seek* con el que obtendríamos las de la primer condición.

### Primer plan

Predicción:

- Me imagino un *index seek* sobre `PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID` para obtener las que cumplan, de forma directa.

Explicación del plan:

- Predicción acertada. Notar como tiene la propiedad `Ordered: True`, ya que para el plan es necesario que esté ordenado. Además al ser *clustered*, ese es el órden físico.
- Según sus estimaciones solo habrá una fila que cumpla, por lo que conviene hacer un *index seek* ya que el índice tiene 121317 filas en total. Además al ser la clave del índice por lo que estamos buscando, el *index seek* es muy eficiente.

### Segundo plan

Predicción:

- Me imagino un *index seek* sobre `PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID` para obtener las mismas que en la primer query.
- Para las segundas un *index scan* sobre  `IX_SalesOrderDetail_ProductID`, por ser inevitable el *index scan* y ese el índice más chico que me permite recorrerlo para obtener los distintos valores del atributo `SalesOrderDetailID`.
- Con ambos resultados podrías hacer un `concatenate` y pasárselo al `SELECT`.

Explicación del plan:

- Predicción errónea. Era más óptimo hacer un *index scan*.
Explicación del plan:

- Predicción errónea. Era más óptimo hacer un solo *index scan*.
- No existe ningún índice ordenado por `SalesOrderDetailID` como primer criterio, así que no se puede hacer un *seek* para esa condición y hay que recorrer un índice completo. Ese único scan evalúa el `OR` entero como *predicate* en cada fila, usando la lista enlazada de los *leaf nodes*.
- En los *leaf nodes* de `IX_SalesOrderDetail_ProductID`, además de `ProductID`, se encuentra la clave del clustered `(SalesOrderID, SalesOrderDetailID)` (si fuera un heap sería un RID), que se usa como *row locator* para acceder a la fila completa. Como la consulta solo necesita esas dos columnas, el índice **cubre** la consulta y no hace falta un *Key Lookup*.
- Entre los índices que se pueden recorrer (el clustered, este y el de `rowguid`), el optimizador elige este porque es el más angosto: tiene una entrada por fila, igual que los demás, pero cada una ocupa menos bytes, así que hay menos páginas hoja que leer. En un scan el costo está en la cantidad de páginas hoja, no en la profundidad del B-Tree.

>[!IMPORTANT]
> Todos los índices tienen una entrada por fila de la tabla, lo único que puede variar es el tamaño de cada entrada, en base a la cantidad y tamaño de los atributos que utilice.

## Ejercicio 0.4

### Índices ProductVendor

|tabla        |columna         |indice                                     |tipo        |is_unique |
|-------------|----------------|-------------------------------------------|------------|----------|
|ProductVendor|BusinessEntityID|IX_ProductVendor_BusinessEntityID          |NONCLUSTERED|0         |
|ProductVendor|UnitMeasureCode |IX_ProductVendor_UnitMeasureCode           |NONCLUSTERED|0         |
|ProductVendor|BusinessEntityID|PK_ProductVendor_ProductID_BusinessEntityID|CLUSTERED   |1         |
|ProductVendor|ProductID       |PK_ProductVendor_ProductID_BusinessEntityID|CLUSTERED   |1         |


### Índices Vendor

|tabla     |columna         |indice                    |tipo        |is_unique |
|----------|----------------|--------------------------|------------|----------|
|Vendor    |AccountNumber   |AK_Vendor_AccountNumber   |NONCLUSTERED|1         |
|Vendor    |BusinessEntityID|PK_Vendor_BusinessEntityID|CLUSTERED   |1         |

### Primer query

- Espera leer toda la tabla de `Vendor`.
- De `Vendor` necesita los atributos `Name` y `BusinessEntityID`. Solo `BusinessEntityID` es clave.
- Ningún índice cubre por completo a los atributos `Name` y `BusinessEntityID`, así que hace un *clustered index scan* con el índice `PK_Vendor_BusinessEntityID` para obtener toda la tabla y termina retornando los `Name` y `BusinessEntityID` para cada entrada.
- Para `ProductVendor` también estima leer toda la tabla, por lo que conviene un *scan*.
- Solo le interesan los atributos `BusinessEntityID` y `ProductID` de ella, entonces le conviene utilizar el *índice unclustered* `IX_ProductVendor_BusinessEntityID` ya que es el más chico que cubre la consulta en comparación con el *índice clustered* `PK_ProductVendor_ProductID_BusinessEntityID`. Del índice `IX_ProductVendor_BusinessEntityID` puede obtener `BusinessEntityID` y `ProductID`, ya que en `ProductVendor` esos son sus claves y por ser una tabla con *clustered index* tienen sus valores en sus hojas.
- Como ambos índices `IX_ProductVendor_BusinessEntityID` y `PK_Vendor_BusinessEntityID` vienen ordenados por `BusinessEntityID` que es el atributo por el que se hace el `JOIN`, entonces puede realizar un *merge join* de ambos.

### Segunda query

- Se agrega  una condición `WHERE` sobre un atributo de la tabla `ProductVendor`.
- Estima que 412/460 van a cumplir la condición, por lo que va a convenir hacer un *scan*.
- El índice que usamos en la query anterior (`IX_ProductVendor_BusinessEntityID`) ya no es tan útil porque necesitamos el atributo `StandarPrice` que no está cubierto.
- Conviene directamente recorrer todas las filas desde el *índice clustered* y sobre ellas aplicar la condición del `WHERE` para acabar proyectando solo los atributos `ProductID` y `BusinessEntityID`, como vemos en `Output List`.
- Respecto al *hash join*:
  - La primer entrada es de 104 filas, por lo que es una cantidad reducida que puede entrar en la tabla de hash almacenada en memoria.
  - Al hacer hash puede, una vez creó la tabla de hash en memoria puede probar con cada fila de las 412 para ver cuáles matchean, recorriendolas una sola vez, por lo que termina viendo 104+412 filas.
  - Los planes se ejecutan de izquierda a derecha, pero el flujo de datos es de derecha a izquierda. Si usara *nested loops* tendría que hacer $104*412$ chequeos, además de que los chequeos para la tabla `ProductVendor` son sobre un *clustered index* al que debe escanear para obtener los distintos `BusinessEntityID` porque se debe quedar con los que cumplan que `StandardPrice > $10`.

### Tercer query

- Se agrega una condición al `WHERE` sobre el atributo `Name` de `Vendor`.
- Como no hay ningún índice que cubra los atributos `Name` y `BusinessEntityID` de `Vendor`, debe hacer un *scan* ya que no puede hacer un *seek* al no tener índice sobre `Name`. Elige hacer un *clustered index scan* y obtener `BusinessEntityID` de los que cumplan la condición de `Name LIKE N'F%'`. Si usara un *hash join* debería chequear todas las filas de *probe*, que son 460, contra las 7 entradas de la *hash table*.
- Como el *outer input* del `JOIN` es chico, solo 7 filas y tiene un índice sobre el atributo a joinear en `ProductVendor`, que es `IX_ProductVendor_BusinessEntityID`, por lo que dado el valor de `BusinessEntityID` *outer input* buscar qué fila de `ProductVendor` matchea con ese `BusinessEntityID` se puede realizar con un *seek* de forma directa, no como en [segunda query](#segunda-query-1) donde teníamos que hacer un *clustered index scan*.
- Sobre esas filas que cumplen la condición de *join* y  `Name LIKE N'F%'` resultantes del *join* hace un *Key lookup* con los valores de `ProductID` y de `BusinessEntityID` para traer los de `StandardPrice`, pero sobre ellos aplica el predicado del `WHERE StandardPrice > $10`.
- Finalmente los junta con sus datos provenientes del anterior *nested loop* y los retorna.

En la primer query tiene para ambas tablas índices ordenados por el atributo de join, entonces conviene *merge join*.

En la segunda no están ordenadas, por lo que no puede hacer merge. Tampoco tiene una forma de acceder directo a las que matcheen con outer input como para hacer un nested loop efectivamente, ya que tiene que recorrer todas las del probe, usa hash.

En la tercera tiene forma de acceder directo con un indice a la fila que matchee sin necesidad de hacer un recorrido por todas las del inner input por lo que es óptimo un nested.

## Ejercicio 0.5

### Índice `Product`

|tabla     |columna      |indice                  |tipo        |is_unique |
|----------|-------------|------------------------|------------|----------|
|Product   |Name         |AK_Product_Name         |NONCLUSTERED|1         |
|Product   |ProductNumber|AK_Product_ProductNumber|NONCLUSTERED|1         |
|Product   |rowguid      |AK_Product_rowguid      |NONCLUSTERED|1         |
|Product   |ProductID    |PK_Product_ProductID    |CLUSTERED   |1         |

### Columnas `Product`

|TABLE_NAME|COLUMN_NAME          |IS_NULLABLE|DATA_TYPE       |
|----------|---------------------|-----------|----------------|
|Product   |ProductID            |NO         |int             |
|Product   |Name                 |NO         |nvarchar        |
|Product   |ProductNumber        |NO         |nvarchar        |
|Product   |MakeFlag             |NO         |bit             |
|Product   |FinishedGoodsFlag    |NO         |bit             |
|Product   |Color                |YES        |nvarchar        |
|Product   |SafetyStockLevel     |NO         |smallint        |
|Product   |ReorderPoint         |NO         |smallint        |
|Product   |StandardCost         |NO         |money           |
|Product   |ListPrice            |NO         |money           |
|Product   |Size                 |YES        |nvarchar        |
|Product   |SizeUnitMeasureCode  |YES        |nchar           |
|Product   |WeightUnitMeasureCode|YES        |nchar           |
|Product   |Weight               |YES        |decimal         |
|Product   |DaysToManufacture    |NO         |int             |
|Product   |ProductLine          |YES        |nchar           |
|Product   |Class                |YES        |nchar           |
|Product   |Style                |YES        |nchar           |
|Product   |ProductSubcategoryID |YES        |int             |
|Product   |ProductModelID       |YES        |int             |
|Product   |SellStartDate        |NO         |datetime        |
|Product   |SellEndDate          |YES        |datetime        |
|Product   |DiscontinuedDate     |YES        |datetime        |
|Product   |rowguid              |NO         |uniqueidentifier|
|Product   |ModifiedDate         |NO         |datetime        |

### Índice `ProductSubcategory`

|Tabla             |Columna             |Indice                                    |Tipo        |is_unique |
|------------------|--------------------|------------------------------------------|------------|----------|
|ProductSubcategory|Name                |AK_ProductSubcategory_Name                |NONCLUSTERED|1         |
|ProductSubcategory|rowguid             |AK_ProductSubcategory_rowguid             |NONCLUSTERED|1         |
|ProductSubcategory|ProductSubcategoryID|PK_ProductSubcategory_ProductSubcategoryID|CLUSTERED   |1         |

### Columnas `ProductSubcategory`

|TABLE_NAME        |COLUMN_NAME         |IS_NULLABLE|DATA_TYPE       |
|------------------|--------------------|-----------|----------------|
|ProductSubcategory|ProductSubcategoryID|NO         |int             |
|ProductSubcategory|ProductCategoryID   |NO         |int             |
|ProductSubcategory|Name                |NO         |nvarchar        |
|ProductSubcategory|rowguid             |NO         |uniqueidentifier|
|ProductSubcategory|ModifiedDate        |NO         |datetime        |

### Primer query

- `ProductSubcategory` tiene un índice que cubre la consulta: `AK_ProductSubcategory_Name` con el que puede obtener `Name` y también `ProductSubcategoryID` por ser su clave y tener índice clustered.
- No le conviene usar el clustered directo porque al tener más atributos, es más grande.
- Estima que va a tener que retornar todas las filas, por lo que conviene un *scan*.
- Respecto a `Product` también estima que va a tener que retornar toda la tabla, por lo que conviene un *scan*.
- Si bien el índice AK_Poduct_Name tiene la calve y ese atributo, no tiene el atributo productSubcategoryID por el que debe hacer el join, entonces al no cubrir la consulta le conviene usar directo el clustered index.
- Como el outer input es chico (37 filas de 65B), entra en memoria y como no tiene forma de acceder directo con el subcategory id porque necesitaba también el name, entonces tuvo que usar el indice clustered, por lo que al tener que recorrerlo todo, conviene hacerlo una sola vez, tras poner todos los del outer en la hash table en vez de hacerlo 37 veces por cada una de las 504 filas que estima, como lo haría si usara un nested loop.

### Segunda query

- Se pide que los resultados estén ordenados por `ProductSubcategoryID`.
- Como `ProductSubcategoryID` es clave de la tabla ProductSubcategory` y solo tiene el índice *clustered* que lo tenga como clave utiliza ese, ya que está ordenado por ese atributo. Como va a tener que leer toda la tabla le conviene directamente hacer un *scan*.
- Para las filas de `Product` no cuenta con un índice con clave `ProductSubcategoryID` y tampoco es clave de la tabla, así que necesita obtenerlo del índice *clustered* con un *scan*. Como el índice *clustered* está ordenado por `ProductID` y no por `ProductSubcategoryID`, necesita aplicar un *sort*. Como resultado del *sort* obtiene todas las filas de la tabla `Product` ordenadas por `ProductSubcategoryID`.
- Para retornar las filas ordenadas por `ProductSubcategoryID`, necesita aplicar un *merge join* sobre las filas que vienen ordenadas de `ProductSubcategory` y las de `Product` sobre el atributo `ProductSubcategoryID`. Al estar ambas ordenadas sobre el atributo con el que se hace el *join* este tipo de *join* permite hacerse recorriendo ambas en simultáneo en un recorrido de 504+37 filas. Si usara un hash join no tiene garantías de preservar el orden, y si usara un nested loop no solo que no tiene garantías de preservar el orden, sino que sería muchas más iteraciones y necesitaría un table spoon para almacenar y poder acceder rapidamente a los resultados del sort.

## Ejercicio 0.6

### Índices `Person`

|tabla     |columna              |indice                                 |tipo        |is_unique |
|----------|---------------------|---------------------------------------|------------|----------|
|Person    |rowguid              |AK_Person_rowguid                      |NONCLUSTERED|1         |
|Person    |FirstName            |IX_Person_LastName_FirstName_MiddleName|NONCLUSTERED|0         |
|Person    |LastName             |IX_Person_LastName_FirstName_MiddleName|NONCLUSTERED|0         |
|Person    |MiddleName           |IX_Person_LastName_FirstName_MiddleName|NONCLUSTERED|0         |
|Person    |BusinessEntityID     |PK_Person_BusinessEntityID             |CLUSTERED   |1         |
|Person    |AdditionalContactInfo|PXML_Person_AddContact                 |XML         |0         |
|Person    |Demographics         |PXML_Person_Demographics               |XML         |0         |
|Person    |Demographics         |XMLPATH_Person_Demographics            |XML         |0         |
|Person    |Demographics         |XMLPROPERTY_Person_Demographics        |XML         |0         |
|Person    |Demographics         |XMLVALUE_Person_Demographics           |XML         |0         |

### Columnas `Person`

|TABLE_NAME|COLUMN_NAME          |IS_NULLABLE|DATA_TYPE       |
|----------|---------------------|-----------|----------------|
|Person    |BusinessEntityID     |NO         |int             |
|Person    |PersonType           |NO         |nchar           |
|Person    |NameStyle            |NO         |bit             |
|Person    |Title                |YES        |nvarchar        |
|Person    |FirstName            |NO         |nvarchar        |
|Person    |MiddleName           |YES        |nvarchar        |
|Person    |LastName             |NO         |nvarchar        |
|Person    |Suffix               |YES        |nvarchar        |
|Person    |EmailPromotion       |NO         |int             |
|Person    |AdditionalContactInfo|YES        |xml             |
|Person    |Demographics         |YES        |xml             |
|Person    |rowguid              |NO         |uniqueidentifier|
|Person    |ModifiedDate         |NO         |datetime        |

### Primer query

- `NameStyle` no puede ser `NULL` y como no tiene `DISTINCT NameStyle`, entonces debo contarlos todos, así que no me queda otra que hacer un *scan* para toda la tabla ya que, implícitamente, me están pidiendo que cuente la cantidad de filas.
- Como el índice *clustered* almacena toda las columnas, su tamaño va a ser mayor en bytes (9 bytes contra 19 bytes) que el del índice *nonclustered* `AK_Person_rowguid`, y como ambos atributos son *unique*, entonces habrá un valor distinto de `rowguid` para cada fila, así que haciendo un *index scan* sobre ese índice puedo contarlas, de forma más óptima.
- Luego se aplica el *stream aggregator* para realizar el `COUNT` y un *compute scalar* para castear el resultado a *int*.

### Segunda query

- `Title` puede ser `NULL`.
- La función de agregación `COUNT(*)` tiene en cuenta los `NULL`, pero `COUNT(ATTR)` con `ATTR` un atributo cualquiera los ignora.
- Entonces en este caso nos interesa no contar los que tengan `Title = NULL`, para eso necesitamos ese atributo y como no tenemos índice sobre él, debemos obtenerlo de la tabla con el *indice clustered*.
- Luego se aplica el *stream aggregator* para realizar el `COUNT` y un *compute scalar* para castear el resultado a *int*.

## Ejercicio 0.7

### Índices `Employee`

|tabla     |columna          |indice                                        |tipo        |is_unique |
|----------|-----------------|----------------------------------------------|------------|----------|
|Employee  |LoginID          |AK_Employee_LoginID                           |NONCLUSTERED|1         |
|Employee  |NationalIDNumber |AK_Employee_NationalIDNumber                  |NONCLUSTERED|1         |
|Employee  |rowguid          |AK_Employee_rowguid                           |NONCLUSTERED|1         |
|Employee  |OrganizationNode |IX_Employee_OrganizationLevel_OrganizationNode|NONCLUSTERED|0         |
|Employee  |OrganizationLevel|IX_Employee_OrganizationLevel_OrganizationNode|NONCLUSTERED|0         |
|Employee  |OrganizationNode |IX_Employee_OrganizationNode                  |NONCLUSTERED|0         |
|Employee  |BusinessEntityID |PK_Employee_BusinessEntityID                  |CLUSTERED   |1         |

### Columnas `Employee`

|TABLE_NAME|COLUMN_NAME      |IS_NULLABLE|DATA_TYPE       |
|----------|-----------------|-----------|----------------|
|Employee  |BusinessEntityID |NO         |int             |
|Employee  |NationalIDNumber |NO         |nvarchar        |
|Employee  |LoginID          |NO         |nvarchar        |
|Employee  |OrganizationNode |YES        |hierarchyid     |
|Employee  |OrganizationLevel|YES        |smallint        |
|Employee  |JobTitle         |NO         |nvarchar        |
|Employee  |BirthDate        |NO         |date            |
|Employee  |MaritalStatus    |NO         |nchar           |
|Employee  |Gender           |NO         |nchar           |
|Employee  |HireDate         |NO         |date            |
|Employee  |SalariedFlag     |NO         |bit             |
|Employee  |VacationHours    |NO         |smallint        |
|Employee  |SickLeaveHours   |NO         |smallint        |
|Employee  |CurrentFlag      |NO         |bit             |
|Employee  |rowguid          |NO         |uniqueidentifier|
|Employee  |ModifiedDate     |NO         |datetime        |

### Índices `JobCandidate`

|tabla       |columna         |indice                          |tipo        |is_unique |
|------------|----------------|--------------------------------|------------|----------|
|JobCandidate|BusinessEntityID|IX_JobCandidate_BusinessEntityID|NONCLUSTERED|0         |
|JobCandidate|JobCandidateID  |PK_JobCandidate_JobCandidateID  |CLUSTERED   |1         |

### Columnas `JobCandidate`

|TABLE_NAME  |COLUMN_NAME     |IS_NULLABLE|DATA_TYPE |
|------------|----------------|-----------|----------|
|JobCandidate|JobCandidateID  |NO         |int       |
|JobCandidate|BusinessEntityID|YES        |int       |
|JobCandidate|Resume          |YES        |xml       |
|JobCandidate|ModifiedDate    |NO         |datetime  |

### Primer query

- Me pide en el `SELECT` un atributo que no es clave y sobre el cual no tengo índice, que es `Resume`, así que no me queda otra que hacer un *index scan* del *clustered index* `PK_JobCandidate_JobCandidateID`. Además al pedirmelos todos y no filtrar con un `WHERE`, solo puedo hacer un *scan* de la tabla.
- Como me piden que las filas resultantes estén ordenadas por `BusinessEntityID` que no es clave *clustered index* de `PK_JobCandidate_JobCandidateID` y por `JobCandidateID`, entonces tenemos que hacer un *sort* por esos atributos.
- Como ambos inputs del `JOIN` están ordenados por la clave sobre la que se hace el `JOIN` y los que nos piden en `ORDER BY`, entonces podemos aprovechar que podemos hacer *index seek* sobre el input de abajo y utilizar un *nested loop* que nos requeriría un *seek* (rows read per execution = 1) por cada una de las 13 filas del input superior, en lugar de los 13+13 que nos requeriría un *merge join*.

### Segunda query

- Me pide en el `SELECT` un atributo que es clave de la tabla `JobCandidate`, además como la condición del `JOIN` es sobre el atributo `BusinessEntityID`, sobre el cual tengo el *índice nonclustered* `IX_JobCandidate_BusinessEntityID`, puedo directamente hacer un *index scan* de él, aprovechando que en sus hojas se encuentra el valor de la clave `JobCandidateID` y obtener todos lo que necesito escaneando ese índice que encima es de menor tamaño que el *clustered index* (4043 bytes vs. 13 bytes).
- Como la tabla `Employee` tiene como clave a `BusinessEntityID` y tiene un *índice clustered* cualquier índice me sirve para obtener esa información, pero como quiero hacer un `JOIN` sobre el atributo `BusinessEntityID` me conviene usar el *clustered index*, ya que está ordenado por `BusinessEntityID` y eso me va a servir para poder cumplir con el requisito del órden por `BusinessEntityID`. Además al estar ordenado por el atributo sobre el que se hace el `JOIN`, se puede hacer un *index seek*, en lugar de un *scan*.
- Como ambos inputs del `JOIN` están ordenados por la clave sobre la que se hace el `JOIN` y los que nos piden en `ORDER BY`, entonces podemos aprovechar que podemos hacer *index seek* sobre el input de abajo y utilizar un *nested loop* que nos requeriría un *seek* (rows read per execution = 1) por cada una de las 13 filas del input superior, en lugar de los 13+13 que nos requeriría un *merge join*.