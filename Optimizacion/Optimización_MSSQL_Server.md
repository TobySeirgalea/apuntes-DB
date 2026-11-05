# Optimización MSSQL Server

Cada operador tiene componente logico (lo que hace) y físico (algoritmo con el que lo implementa)

Icono más a izquierda (eg. select) contiene info del plan en su conjunto, los de los operadores solo sobre ese operador.

Grosor flecha = cantidad datos pasan por ahí.

Porcentajes de costos de operador son respecto al plan completo. Los genera optimizer basado en estadisticas. No son CPU ni I/0, sino números de referencia.
 Son estimaciones no exactos.

- Index seek: Usa nonclustered index.

Si hay ordenes de magnitud de diferencia entre la cantidad de filas estimada a devolver y la devuelta es un red flag.

Clasificación de operadores físicos:

|Reading data      |Combining data  |Grouping and ordering data|Manipulating data|Modifying data      |Performance|
|:----------------:|:--------------:|:------------------------:|:---------------:|:------------------:|:---------:|
|Table/Index scan  |Nested loops    |sort                      |computer scalar  |Table/Index insert  |bitmap     |
|Index seek        |merge join      |stream aggregate          |filter           |Table/Index update  |spools     |
|lookup            |hash match      |hash match (aggregate)    |top              |Table/Index delete  |parallelism|
|constant scan     |adaptative join |window aggregate          |sequence project |Table/Index merge   |           |
|                  |sequence        |segment                   |                 |assert              |           |
|                  |concatenation   |window spool              |                 |split               |           |
|                  |switch          |                          |                 |collapse            |           |

Index seek y nested loops son más counes en queries frecuentes que retornan pocos datos.
index scans son más eficientes cuando se lee gran parte de la tabla
Merge join o hash match joins son más eficientes para join de grandes data streams.

operadores como sort, hash match y adaptatuve join requiere gran cantidad de memoria disponible para ejecutarse.

operadores en plan se llaman de izquierda a derecha (→).

Cada operador soporta la operación getNext que te da la siguiente fila. Por lo que si tenemos un TOP/LIMIT k antes de un scan, solo se hacen k llamados a getNext por lo que se lee hasta darle k al TOP/LIMIT y luego deja de leer.

streaming operators van pasando filas a medida que terminaro de aplicar la operación sobre ella. blocking operators deben aplicarla sobre todas las filas antes de pasar un resultado.

clustered index scan es streaming operator, a medida que va leyendo las filas del index te las va pasando. 

sort es blocking, por lo que tiene que recibir todos los datos y aplicar la operación sobre todos ellos antes de retornar cualquier resultado. e.g. un TOP/LIMIT k SORT debe ordenar todas las filas, aunque sean muchisimas para poder luego seleccionar solo k

semi-blocking solo deben esperar hasta completar parte de la operacion antes de liberar la primer fila, como hash match que primero procesa todas las del primer input, pero las del segundo va retornando resultados a medida que las lee.

no hay listado oficial en MSSQL de blocking, semi o stream.

en properties del primer operador encontrás info general del plan como si encontró el mejor o terminó de analizar planes por timeout, etc. Tiempo y recursos para generar el plan, etc.

Algunos operadores pueden tener warnings (simbolos encima), no son señales de errores pero hay que tenerlos en cuenta.

. Primero centrarse en operaciones donde haya diferencia entre filas estiamdas y actuales.
. Mirar operadores más costosos aunque sabiendo que es una estimacion y no son comparables entre planes, además algunos como compute scalar tienen costo fijado.
. Las sugerencias de indices son sugerencias. Algunos pueden agilizar una consulta pero relentizar las demás. Los ínfices se crean teniendo en cuenta todo el workflow.
. Ver flechas gordas porque significan que pasan muchos datos. También prestar atencion a los cambios abruptos en grosor. Una gruesa al inicio que luego se va achicando puede indicar que hace falta filtrar antes. Si se van agrandando es que se está multiplicando la cantidad de datos al pasar por los operadores.
. si ves un operador que no te esperarias que estuviera en el plan para esa query, analizalo.

index/table scans: va leyendo las páginas del indice o de la tabla. Indica que se acceden a muchas filas.

seek operator: usa un index para identificar punto inicio y posible punto final para hacer scan sobre las paginas de ese indice. Suele tener menor cantidad de filas accedidas.

un scan que termina trayendo pocos datos o un seek que trae muchos es indicio de que algo hay que optimizar.

usar parámetros en queries permite al motor reutilizar el plan.

### indices:

An index is an on-disk structure associated with a table or view that speeds retrieval of rows from the table or view. An index contains keys built from one or more columns in the table or view

Both clustered and nonclustered indexes can be unique. With a unique index, no two rows can have the same value for the index key

indexes are automatically maintained for a table or view whenever the table data is modified.

#### clustered index:
Clustered indexes sort and store the data rows in the table or view based on their key values. These key values are the columns included in the index definition.

The only time the data rows in a table are stored in sorted order is when the table contains a clustered index. When a table has a clustered index, the table is called a clustered table. If a table has no clustered index, its data rows are stored in an unordered structure called a heap.

##### Primary key y clustered index
The primary key ensures that the values of a column in the table are unique so that all rows are identified with a unique key. By default when we create a primary key SQL Server creates a unique clustered index. However, we can create a primary key without a clustered index because the only mandatory requirement is uniqueness for the primary key. So the main differences between the primary key and clustered index are:

A primary key is a logical structure and it provides the uniqueness for a table
A clustered index is a physical structure and it provides the physical order of the records on the storage
Perhaps, this question is the right one to ask:

“Why we use the primary key and clustered indexes on the same key column?”

#### nonclustered indexes

structure separate from the data rows. A nonclustered index contains the nonclustered index key values and each key value entry has a pointer to the data row that contains the key value.

The pointer from an index row in a nonclustered index to a data row is called a row locator. The structure of the row locator depends on whether the data pages are stored in a heap or a clustered table. For a heap, a row locator is a pointer to the row. For a clustered table, the row locator is the clustered index key.



#### Operaciones

##### index scan

lee todas las filas de una tabla.

Optimizer puede hacer que se use el orden de un indice para hacer el scan lo cual puede ser útil si uno de lo siguientes operadores lo necesitaba ordenado.

Si tiene que aplicar un filtro, esa condición aparece en predicate. Ese predicado se evalua para cada fila, a diferencia del caso de seek predicate.

si tiene que hacer un scan y tiene un índice mas chico que el clustered que le pueda proveer todos los campos que necesita en el select, entonces conviene utilizar ese ya que además de los valores que son clave en el indice , por ser tabla con clustered index, en las hojas contiene la clave clustered para acceder a la fila con ese valor de clave de indice, por lo que para retornar las claves del indice y la clave cluster podemos retornar las hojas del indice y listo.

![unclustered index](./images/uncluestered_index_mssql)

una mala logica de query puede forzar al optimizador a elegir un scan por sobre un index seek, un ejemplo son las non sargable queries

En SQL Server, una consulta es sargable cuando el predicado (la condición del WHERE, JOIN, HAVING, etc.) puede aprovechar un índice para filtrar datos directamente, sin tener que procesar fila por fila. En otras palabras: si el optimizador ve que puede usar un índice de forma directa, lo hará. Si no, te prepara un bonito Index Scan o Table Scan con aroma a cuello de botella.

como le has puesto una función encima, el optimizador no puede buscar directamente. Tiene que aplicar la función a cada fila y luego comparar.

El caso anterior ilustra la regla de oro de la sargabilidad: si transformas la columna del predicado, estás condenado a un escaneo. Las funciones como LEFT, SUBSTRING, CONVERT, DATEDIFF, COALESCE o incluso simples operadores matemáticos, rompen la posibilidad de usar índices si se aplican sobre la columna.

https://www.soydba.es/sargabilidad-el-arte-de-no-cabrear-al-optimizador/

##### Index seek

navega por btree directo a pagina con fila o rango de filas que necesita.

ocurre si existe indice que matchee con predicate column de query y el indice puede proveer todas las columnas que la query necesita. o si no cubre la query pero retorna una pequeña cantidad de las filas.

Puede ser sobre clustered o non clustered

##### key look up



### joins

operador fisico elegido depende de tamaño de las tablas y si estan ordenadas o no

#### nested loops
por cada fila del de arriba busca entre las filas de abajo las que matcheen

A Nested Loops operator can be highly efficient, as long as the outer input is small and it is
cheap to search the inner input, which in the case of simple join operations is often achieved
by indexing the "inner table" on the join column

en consultas correlaacionadas, esdecir cuando la subquery usa valores de la externa. Por lo que la interna se deberá repetir tantas veces como valores use de la externa.

#### hash match
crea hash table con las filas del de arriba y después va chequeando cuales matchean de las de abajo

#### merge join

lee de los dos en simultaneo (ambos ordenados en join column) y mergea las que matchean en valor de join column


For a one to many Merge Join, the input without duplicates has to be the top input.  If the values are equal, it always advances the bottom input, the one that can have duplicates.

there is no reason to worry about “many to one” (as opposed to “one to many”): the optimizer would simply reverse the order of the inputs. When both inputs have guaranteed uniqueness (“one to one”), then either input can be at the top side and it will work.

 When both inputs have guaranteed uniqueness (“one to one”), then either input can be at the top side and it will work. But what if we have no uniqueness guarantee in either of the inputs? The query below illustrates this.

 SELECT     pv.BusinessEntityID,
           pv.StandardPrice,
           sod.ProductID,
           sod.SalesOrderID
FROM       Sales.SalesOrderDetail   AS sod
INNER JOIN Purchasing.ProductVendor AS pv
      ON   sod.ProductID = pv.ProductID;

Both inputs have the same ProductID value, so the bottom input advances to find the next ProductVendor. If this is for the same ProductID, it is another match with the current row from SalesOrderDetail and the ProductVendor input will once more be advanced. This continues until we hit a new ProductID in ProductVendor. At that point the next row from SalesOrderDetail is read. But what it that row has the same ProductID as the previous row? The bottom input has just advanced past all the matching rows, that are now actually needed again. But execution plan operators do not support a GetPrevious() method; only GetNext() exists. How does the Merge Join produce the required join results in this case? The answer is that it stores the data it might need again in tempdb.

va leyendo de la top input. los que matchean los va metiendo en tempdb y si el siguiente de la top es el igual al anterior, puede leer directo de tempdb los que matchearon para ese mismo valor en fila anterior. Cuando cambia el valor de la top, tiene que flush la tempdb y repetir proceso. supongo que se puede fija antes si el siguiente es igual

#### adaptative join

es de mssql2017, implementa nested loops y hash match eligiendo el de menor costo en runtime.
