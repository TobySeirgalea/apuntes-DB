# Bases de datos NOSQL

## Bibliografía

- Fundamentals of Database Systems por Libro de Ramez A Elmasri y Shamkant B. Navathe

**NOSQL** se refiere a *not only SQL* y surge porque muchas aplicaciones necesitan sistemas que no sean relacionales para grandes volumenes de datos.

Ejemplos:

- Google → BigTable:
  - Column based NOSQL system.
  - Apache Hbase es primo *open source*.
- Amazon → DynamoDB:
  - Key-value NOSQL system.
- Facebok → Cassandra:
  - NOSQL system que usa conceptos de key-value y column based.
- MongoDB, CouchDB:
  - Document based.
  - Abiertos.
- GraphBase, Neo4J:
  - Abiertos y de *graph databases*.
- etc...

## Características

Priorizan:

- [Semistructured data storage](#semistructured-data-storage).
- [High performance](#high-performance).
- [Disponibilidad](#disponibilidad).
- [Replicación de datos](#replicación-de-datos).
- [Escalabilidad](#escalabilidad).

Por sobre:

- Consistencia inmediata.
- Query language poderosos.
- Structured data storage.

### Semistructured data storage

- En mayoría no es requerido tener un esquema.
- Se utiliza *semistructured data*, auto descriptiva.
- Las *constraints* deben estar explicitadas en la aplicación.
- No necesitan *query language* poderoso como **SQL** porque se los archivos se localizan por la key del objeto. Si proveen *query language* este es subconjunto de **SQL**.
- Suelen proporcionar una *API* para que la aplicación realice las consultas con la key.
- Permiten almacenar distintas versiones de archivos asociándoles un *timestamp*.

### High performance

Necesitás búsqueda rápida de uno en particular entre muchísimos archivos. Para eso **NOSQL** usan una de las siguientes opciones:

- *Hashing*: Obtenemos localización a partir de la key del archivo.
- *Range partitioning*: Particionamos el espacio en rangos de valores para la key, así dada una key sabemos qué partición le corresponde.
- *Indexing*:

### Disponibilidad

- Mayoría son sistemas que requieren disponibilidad continua.

- Se la logra con replicación de datos entro distintos nodos de forma invisible para el usuario. Así si uno falla otra puede responder.

- Debe incorporar control de concurrencia y consistencia.

### Replicación de datos

- Dificulta escritura, ya que se deben actualizar todas las copias relentizando la operación.
- Facilita lectura porque varios pueden responder.
- Muchos en vez de requerir consistencia inmediata requieren *eventual consistency*.

#### Modelos

- *Master-slave replication*:
  - Escritura: Solo se escribe al nodo *master* y eventualmente se propagará a los *slaves*. De acá sale lo de *eventual consistency*.
  - Lectura:
    - O Leemos solo al *master*.
    - O permitimos leer a *slaves* pero no garantizamos que sea el valor actualizado.
- *Master-master replication*:
  - Permito leer y escribir a cualquier copia pero debo tener mecanismos de reconciliación para que haya alguna consistencia.

#### Sharding de archivos

Podés tener múltiples accesos a un mismo archivo concurrentemente. Entonces muchos **NOSQL** distribuyen el acceso al archivo en distintos nodos.

### Escalabilidad

En sistemas distribuidos la escalabiliadad puede ser:

- Horizontal: Sistema se expande añadiendo nodos para almacenar datos y procesarlos.
- Vertical: Sistema se expande mejorando capacidad de almacenamiento y procesamiento en los nodos.

En **NOSQL** la *escalabilidad* se implementa con el sistema en funcionamiento. Por lo tanto necesita técnicas para que esta no interfiera en su normal funcionamiento.

## Categorías

### Systems-document based

- Se almacena la información en formatos como JSON, XML u otros.
- Los documentos son *self-describing data* [^1].
- Documentos pueden tener nuevos y diferentes atributos.
- Se accede vía ID, pero pueden tener otros índices para rápido acceso.

[^1]: Definición 1: Cuando el nombre del atributo y su valor se almacenan juntos en una tupla.
    Definición 2: En *semistructured data*, donde se junta la información del esquema con los valores de los atributos, los objetos pueden tener distintos atributos no conocidos de antemano y se los llama *self-describing data*

#### Caso MongoDB

- Almacena documentos en **BJSON** *(Binary JSON)*, más eficientes que **JSON**.
- Cada documento de una colección tiene un único `_id` field. A no ser que se solicite lo contrario.
- `_id` puede ser generado por el sistema o especificado por usuario, siempre que este identifique unívocamente a cada documento, tipo *primary key*.
- En vez de mediante un esquema. La forma de acceso y relación entre colecciones las determina usuario en base a cómo define los documentos y qué decide almacenar en ellos. Por ejemplo guardando `_id` del relacionado o el documento entero.
- Teoría de diseño de bases de datos también sirve acá, pero no al no tener esquema no tenemos *constraints* automatizadas del lado de la base de datos, entonces toca implementarlos desde lado de aplicación.
- ([Define su API para operaciones CRUD.](https://www.mongodb.com/es/docs/manual/crud/))

##### Atomicidad en MongoDB

- La mayoría de *updates* son atómicos si hacen referencia a un solo documento.
- También permite definir transacciones sobre múltiples documentos. En ellas usa **two-phase commit** para garantizar *consistencia* y *atomicidad*, es decir sólo hace el *commit* cuando todas están listas.

##### Replicación en MongoDB ← system availability

- Se llama *replica set* a crear múltiples copias de los mismos datos en diferentes nodos.
- Cuando el *nodo primario* falla, se realiza una votación entre los *nodos secundarios* para ver cuál es el nuevo *nodo primario*.
- Un *replica set* debe tener al menos $3$ participantes y siempre debe ser un número impar, sino se añade un *nodo árbitro* para desempatar en el proceso de elección.
- El *nodo árbitro* no puede ser elegido como *nodo primario* ni contiene una réplica del dato, sino que solo vota en la *elección de sucesor del nodo primario*.
- Uno solo es considerado *nodo primario*, el resto son considerados *nodos secundarios*.
- Usa una variación del *master-slave*.
- Todas las escrituras van al *nodo primario*.
- Los *nodos secundarios* toman del *Oplog* del primario los datos para actualizarse.
- Las lecturas por defecto van al *nodo primario*, pero se puede configurar para que puedan ser respondidas por tanto *nodos secundarios* como el primario para ganar velocidad, a pesar de perder consistencia porque podría no estar actualizado.

##### Sharding en MongoDB ← load balancing & scalability

- También conocido como *horizontal partitioning*, divide documentos en tantos nodos como indique el proceso *horizontal scaling* del sistema y almacena las particiones disjuntas de los documentos en otros nodos.
- Cada nodo sólo responde a las operaciones sobre documentos en dicho nodo.
- Se debe indicar un *partitioning field/shard key*, para realizar la partición. Este debe cumplir:
  - Estar en todo documento de la colección, tipo *pk*.
  - Tener un index, para rápido acceso.
- *hash partitioning*: Preferible si solo accedemos de a un documento.
- *range partitioning*: Preferible si accedemos a varios en un rango, *range queries*.

Cuenta con un módulo que lleva registro de qué nodos tienen qué *shards* según el *partition method* elegido, llamado **query router**. En caso de no poder determinar cuál corresponde le manda la *query* a todos los nodos con *shards*.

### Key-value stores

- Acceso vía key, identificado unívoco.
- Valor puede ser objeto, documento, record u otra estructura de datos.

#### Caso DynamoDB

##### DynamoDB data model

- Table: Colección de *self-describing items*.
- Items: Una cantidad de tuplas <attribute, value>. value puede ser contener múltiples valores.
- Attributes: Uno o varios pueden formar la *pk*, mediante la cual se localiza la tupla deseada.
  - En el caso de elegir uno sólo, este se usa para el hash.
  - En el caso de elegir dos, uno se usa para el hash y el otro para ordenar los valores que hayan colisionado.

#### Caso Voldemort

- Almacena tuplas <key, value> en su *store*.
- Tiene operaciones de:
  - Lectura: `store.get(k)`.
  - Escritura: `store.put(k, v)`.
  - Borrado: `store.delete(k)`.
- Values pueden especificarse con **JSON**.
- `Serializer` class provee conversión de formato de value de usuario al interno del sistema. Lo debe proporcionar el usuario, o usar uno *built-in*.

##### Consistent hashing

- Ponele que tenés que dado un par <key, value> tenés que, con una función de hash, determinar a en qué nodo lo guardas.
- Si aplicás la función de hash y luego para saber en qué nodo va aplicás módulo $2^{cantidad~rangos}$. Esto sería *linear hashing*. Esto es bueno para añadir y remover nodos en orden secuencial (*splitting* y *shrink* de *buckets*), pero malo para orden arbitrario (te toca justo uno del medio y tendrías que reacomodar todo lo posterior).
- *Consistent hashing* surge para evitar eso y pasar a solo tener que reordenar $\frac{cantidad~de~claves}{cantidad~de~slots}$.
- Consiste en aplicar la función de hash al par <key, value> para mapearlo a un punto de la circunferencia unitaria, por ejemplo $hash(<key, value>) \% 360$.
- Luego asignarlo al primer nodo que se encuentre en un recorrido en sentido horario.
- En caso de agregar un $n-esimo$ nodo calculamos el punto de la circunferencia $\theta$ donde se ubicará y movemos a todos las tuplas que se encuentran en el recorrido desde el nodo previo a $\theta$ en sentido antihorario, hasta $\theta$ a este nuevo nodo incorporado. Así movimos solo $\frac{1}{n}$ tuplas en peor caso.
- Si querés borrar movés todos los que se encuentre en rango del nodo a borrar hacia su nodo sucesor en sentido horario.
- Asignamos tantos puntos en la circunferencia a un nodo como proporción de capacidad total tenga dicho nodo.
- Permite *horizontal scaling*, ya que podemos añadir nodos.
- Permite *replicación de datos* añadiendo las réplicas en los siguientes nodos en sentido horario.

##### Manejo de consistencia

- Utiliza la técnica *versioning and read repair*, que consisten en permitir escrituras concurrentes, pero asociarlas a *timestamp*. Al momento de lectura se retorna la más actual. En caso de haber varias se envían todas a usuario que selecciona o realiza una versión final reconciliadora se envía ese valor a los nodos para que haya *consistencia*.

#### Caso Redis

- Almacena en memoria principal para servir como un cache.
- Usa *master-slave replication*.
- Busca alta disponibilidad.
- Ofrece persistencia a disco.

### Column based

- Particionan tabla en familias de columnas, donde cada una se almacena en sus propios archivos.
- Permiten *versioning* de los valores.
- A diferencia de [*key-value stores*](#key-value-stores), las *keys* son multidimensionales, pudiendo tener varios componentes, en general *column family* y *column qualifier*.

#### Caso Hbase

Alternativa opensource de Google BigTable.

##### Hbase data model

- Namespaces: Colección de tablas.
- Tables: Donde se almacenan las *rows*. Cada una tiene un nombre.
- Rows: Donde se almacenan los datos en las tablas. Cada una tiene un único *row key*, que sirve de *pk*.
- Columns: Identificado por $<column family:column qualifier>$
- Column families:
  - Se declaran al crear la tabla.
  - Son fijos.
  - Cada una se almacena en su propio archivo del *HDFS file system*.
- Column qualifiers:
  - Hacen al modelo *self-describing*.
  - Se pueden añadir dinámicamente una vez ya creada la tabla.
  - Programador debe saber cuál pertenece a cuál familia.
- Data cells:
  - Unidad básica de datos.
  - Se especifican mediante $(table, rowid, columnFamily, columnQualifier, timestamp)$.

Hbase permite *versioning* asociando a cada dato un *timestamp* con la hora del sistema en que fue creado.

También ofrece sus operaciones en formato de *CRUD operations*, a partir de las cuales podemos crear otras más complejas.

##### Funcionamiento interno

Las *tablas* se dividen en *regiones*, donde cada una contiene un rango de *row keys* y de *stores*, en estas últimas van las *column families*. Las *regiones* se almacenan en *region servers/storage nodes*. El *master server* monitorea los *region servers*, divide las tablas en *regiones* y las asigna a los *region servers*.

### Graph based

- Datos representados en grafos.
- Se hallan datos recorriendo aristas usando *path expressions*.
- Podemos asociar datos a nodos y/o ejes.

#### Caso Neo4j

- Tiene su propio **DQL** (*data query language*) de alto nivel, **Cypher**.
- Los nodos pueden tener varios *labels* y pueden ser agrupados por ellos.
- Las aristas son relaciones dirigidas en cuanto a su declaración, pero pueden ser transitadas en ambos sentidos.
- Tanto nodos como aristas pueden tener *propiedades* que almacenan datos.
- Los *paths* son caminos en el grafo y suelen ser partes de queries que especifican un patrón. Se terminan retornando todos los nodos alcanzables.
- Permite definir *optional schemas* para definir *constraints* sobre *labels* y *propiedades* e *indexes*.
- Cada nodo tiene un id único interno.

##### Cypher query language

- Una query se compone de cláusulas, que se pueden componer entre si.

### Otros sistemas

Sistemas que no se categorizan tan facilmente:

- Hybrid **NOSQL** systems.
- Object databases.
- XML databases.

## Manejo de consistencia y concurrencia

- Forzar la serialización de las operaciones es la forma más fuerte de consistencia.
- Tiene un costo importante.

### CAP theorem

Explica requerimientos en un sistema distribuido con replicación.

- **C***onsistencia*, entre copias. No es la misma que *A***C***ID*.
- **A***vailability*, del sistema para *read*/*write*: Dichas operaciones o se completan con éxito o se recibe un mensaje de error.
- **P***artition tolerance*, sistema debe seguir funcionando si red de nodos tiene un error y se particiona en $2$ o más donde solo se pueden comunicar nodos de una misma partición.

**CAP** *theorem* dice que no podés tener las $3$ en un sistema distribuido con replicación de datos. Por lo tanto hay que elegir a lo sumo $2$ para garantizar.

Generalmente *availability* y *partition tolerance*.
