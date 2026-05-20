# Apunte SQL

Fuentes:

- "Databases, the complete book", chapter 6 y 7, Ullman.

## Características

- **SQL** es case-insensitive. Solo se distinguen mayúsculas de minúsculas cuando está entre comillas/apóstrofe ''.
- Las queries finalizan con ;
- Dos apóstrofes seguidos representan al símbolo apóstrofe, ya que los *strings* los representamos entre ellos.

### Colisión de nombres de atributos

Si tenemos dos relaciones que coinciden en el nombre de un atributo, podemos usar el nombre de la relación seguido de un punto y el nombre del atributo para desambiguar. Por ejemplo
    `MovieStar(name, address, gender, birthdate)`
    `MovieExec(name, address, cert#, netWorth)`

```SQL
    SELECT MovieStar.name, MovieExec.name
    FROM MovieStar, MovieExec
    WHERE MovieStar.address = MovieExec.address;
```

Esta sintáxis también puede ser utilizada aunque no haya colisión de nombres.

### Tuplas como variables

- Si tenés que utilizar dos o más tuplas de una misma relación podés usar una tupla como variable. Para eso repetimos por cada una el nombre de la relación en la cláusula **FROM** y para referirnos a cada ocurrencia le asignamos un alias.
- Luego de cada relación en el **FROM** podemos poner el keyword **AS** y un nombre para la tupla variable, aunque el **AS** es opcional.
- **SELECT** y **WHERE** pueden utilizar esos alias para desambiguar.
- Ejemplo:

    ```SQL
        SELECT Star1.name, Star2.name
        FROM MovieStar Star1, MovieStar Star2
        WHERE Star1.address = Star2.address 
            AND Star1.name  < Star2.name; 
    ```

- Todas las referencias a atributos en **SELECT** y **WHERE** son a variables de tuplas, solo que cuando una relación aparece una única vez en **FROM** se usa el mismo nombre como variable de tupla.
- Las **variables de tuplas de una misma relación pueden referirse a una misma tupla a la vez**. Para evitar esas tuplas en el resultado la condición debe evitar que una tupla comparada consigo misma cumpla.
- También tener en cuenta que si la condición no lo evita podemos tener la tupla (A, B) y la tupla (B, A) en el resultado.

### Subqueries

- Son queries dentro de otras queries. En **SQL** podemos anidar queries tanto como queramos.
- Pueden aparecer en:
  - Retornando relaciones o una constante que usamos en cláusulas **WHERE**.
  - En cláusulas **FROM** seguidas de una [variable de tupla](#tuplas-como-variables) que representa una tupla de la relación resultante de la *subquery*.
  
#### *Correlated subquery*

- Son *subqueries* que dependen del valor que tome una *outer query* para evaluarse.
- La *correlated subquery* se evalúa una vez por cada valor que toma la *outer query*.
- Son útiles para resolver problemas como comparaciones *row by row*, *filtering* y *conditional updates*.
- Ejemplo de su sintaxis:

``` SQL
SELECT column1, column2, ...
FROM table1 t1
WHERE column1 operator
      (SELECT column
       FROM table2
       WHERE expr1 = t1.expr2);
```

  Vemos cómo la *subquery* usa un valor de la tupla de la *outer query*.

- Reglas de *scoping* para escribirlas:
  - Notar que en el ejemplo anterior usamos `t1.expr2` en la *correlated subquery*.
  - Esto se debe a que en una *query* los atributos pertenecen a las tuplas de la/s relación/es de la cláusula **FROM**, entonces si nos queremos referir a un atributo de una tupla de *outer query* debemos precederlo del alias para una tupla de la relación en ella.
  - Primero se busca en la subquery actual, si no se encuentra se busca en la más externa inmediata y sino se continúa escalando buscando ese atributo. Si finalmente no se encuentra hay un error.

#### Subqueries en **FROM**

Podemos utilizar *subqueries* en cláusulas **FROM** para utilizar las tuplas de la relación resultante de la *subquery*. Cómo esa relación fue generada dinámicamente, no tiene nombre, entonces para referirnos a las tuplas de esta podemos usar un alias.
Por ejemplo:

```SQL
SELECT name
FROM MovieExec, (SELECT producerC#
                 FROM Movies, StarsIn
                 WHERE title = movieTitle AND
                       year = movieYear AND 
                       starName = 'Harrison Ford'
                ) Prod
WHERE cert# = Prod.producerC#;
```

### Comparación de tuplas

- Sólo podemos comparar tuplas si tienen la misma cantidad de componentes (*scalar values*).
  - Los valores atómicos que pueden aparecer como componentes de una tupla son llamados *scalars*. Pueden ser constantes o atributos.
- La comparación entre *scalars* se realiza en el orden en que aparecen en tupla.

## Paralelismo con álgebra relacional

```SQL
SELECT L
FROM R
WHERE C
```

Es equivalente al $\pi_{L}(\sigma_{C}(R))$.

### Producto

#### Visto como lista de relaciones en cláusula **FROM**

```SQL
SELECT name 
FROM Movies, MovieExecutives
WHERE title = 'Star Wars' AND producerC# = cert#;
```

Al poner varias relaciones en el **FROM** pasamos a considerar todas las posibles tuplas resultantes de combinar los atributos en bloque de la relación Movies con los atributos en bloque de la relación MovieExecutives. Podés verlo como FROM R_1, R_2 es flatten([attrs(R_1), attrs(R_2)]) renombrando en caso de colisión.

Si una de las relaciones es vacía no habrá forma de formar una tupla con atributos de todas las relaciones, así que la query resultará en una relación vacía.

#### Visto como **CROSS JOIN**

Podemos obtener la relación resultante del producto cartesiano del álgebra relacional en **SQL** mediante la operación **CROSS JOIN**. Ejemplo:
`Movies(title, year, length, genre, studioName, producerC#)`

`Starsln(movieTitle, movieYear, starName)`

```SQL
Movies CROSS JOIN StarsIn;
```

Nos retorna una relación con $9$ columnas, una para cada atributo de las relaciones. Al igual que el producto cartesiano si ambas tienen un atributo con nombre en común se lo nombra con `nombreRelacion.atributoEnComún`.

### Theta-Joins

En **SQL** se las implementa con el operador [**JOIN ON**](#join--on).

### [Natural joins](#natural-join)

### Operaciones entre queries

**SQL** nos permite realizar operaciones entre queries encerradas entre paréntesis. Estas operaciones al ser de *sets* [eliminan los duplicados de sus relaciones resultantes](#eliminación-de-duplicados).

Las operaciones permitidas son:

- **UNION**, $\cup$ del álgebra relacional.
- **INTERSECT**, $\cap$ del álgebra relacional.
- **EXCEPT**, $-$ del álgebra relacional.

Ejemplo:
`MovieStar(name, address, gender, birthdate)`
`MovieExec(name, address, cert#, netWorth)`

```SQL
(SELECT name, address
FROM MovieStar
WHERE gender = 'F')
    INTERSECT
(SELECT name, address
FROM MovieExec
WHERE netWorth > 100000000);
```

Nos permitiría obtener todas las mujeres que sean estrellas de cine y ejecutivas con un ingreso mayor a $100000000$.

### Operaciones entre relaciones

#### Eliminación de duplicados

- Las relaciones son *bags* no *sets*, por lo tanto pueden tener duplicados.
- Para evitar duplicados debemos agregar tras la keyword **SELECT** la keyword **DISTINCT**, que indica que se debe producir solo una copia de cada tupla.
- **UNION**, **INTERSECT** y **EXCEPT** eliminan los duplicados de sus relaciones resultantes. Para evitar esto debemos seguir estas keywords de **ALL**, así evitamos que se eliminen los duplicados.
- Es una operación costosa, requiere de ordenar la relación o particionarla para que las tuplas iguales queden una al lado de otra.

### Aggregation

- **SQL** tiene 5 operadores de agregación:
  - **SUM**: Suma los valores de esa columna.
  - **AVG**: Se queda con el valor promedio de esa columna.
  - **MIN**: Se queda con el mínimo valor de esa columna.
  - **MAX**: Se queda con el máximo valor de esa columna.
  - **COUNT**: Cuenta la cantidad de tuplas en la relación resultante de aplicar cláusula **WHERE** a relaciones de cláusula **FROM**.
- Se suelen aplicar en la cláusula **SELECT** a una expresión valuada en algún escalar, generalmente a nombres de columnas.
- Reciben como parámetro entre paréntesis el atributo o expresión que se evalúa a un atributo.
- Podemos agregarle al atributo o expresión que se evalúa a un atributo, la keyword **DISTINCT** antes de su nombre para no considerar repetidos.
- Ejemplo:

    ```SQL
    SELECT COUNT(DISTINCT starName)
    FROM StarsIn;
    ```

- Todos los operadores al no tener valores en la columna de donde los obtienen retornan **NULL**, en cambio **COUNT** retorna $0$.

#### Aggregation: Comportamiento ante **NULL**s

- Todos los operadores los ignoran.
- Sólo cuando usamos `COUNT(*)` es tenido en cuenta, pero cuando tiene un atributo y no `*`, entonces se ignoran los valores **NULL**.

### Grouping

- Va a continuación de cláusula **WHERE**.
- Recibe una lista separada por comas de atributos.
- Agrupa las tuplas de acuerdo a sus valores.
- Ejemplo: Agrupamos las tuplas de la relación `Movies` por mismo valor en la columna `studioName`, luego retornamos una relación con una fila por cada valor distinto de `studioName` y la suma de los valores del atributo `length` del grupo.

    ```SQL
    SELECT studioName, SUM(length)
    FROM Movies
    GROUP BY studioName;
    ```

- No hace falta que tenga *aggregations* en cláusula **SELECT**.

La siguiente *query* nos retorna una relación con los nombres de los productores y la suma de longitudes de sus películas:

```SQL
SELECT name, SUM(length)
FROM MovieExec, Movies
WHERE producerC# = cert#
GROUP BY name;
```

Era necesario agrupar por `name`, sino no podíamos distinguir entre las de un productor y otro.

- El **GROUP BY** podés pensarlo como que te divide una tabla en varias tablas, una por cada valor distinto del atributo en base al que agrupamos, luego sobre esa relación se aplica el resto de la query.

- Podemos imponer condiciones o filtrar los miembros de los grupos agregando una condición en la cláusula [**HAVING**](#having).

#### Grouping: Comportamiento ante **NULL**s

Se lo trata como un valor cualquiera, por lo que podemos tener un grupo con tuplas con valor **NULL** en el atributo sobre el que se agrupó.

#### Restricciones sobre **SELECT**, **HAVING** y **ORDER BY** si hay **GROUP BY**

- Dentro de las [funciones de agregación](#aggregation)de puede usar cualquiera de los atributos de las relaciones que aparezcan en el **FROM**, ya sea en este nivel o en uno superior si es una *subquery*.
- Para el **SELECT** y para el **HAVING** sólo puede tener atributos fuera de [funciones de agregación](#aggregation) si aparecen en la lista de atributos del **GROUP BY**.

## Keywords y su significado

### **SELECT**

- Cláusula que indica qué atributos de las tuplas que cumplan las condiciones irán a la relación resultante.
- `*` Significa proyectar todos los atributos.
- Podemos indicar los atributos que queremos proyectar de las tuplas separados por comas.
- Es como la proyección del álgebra relacional.
- Puede referirse a cualquiera de los atributos de las relaciones en el **FROM**.
- Es cláusula requerida en toda *query* junto con **FROM**.

### **FROM**

- Cláusula que indica la/s relación/es a las que se refiere la query.
- Es cláusula requerida en toda *query* junto con **SELECT**

### **WHERE**

- Cláusula con condición que deben cumplir (evaluar a `TRUE` y no a `FALSE` o `UNKNOWN`) las tuplas que pasen a formar parte de la relación resultante.
- Si la condición contiene nombres de atributos, estos serán reemplazados por los valores de cada tupla en la que se evalúa la condición.
- Es como el selection del álgebra relacional.
- Puede contener:
        - Expresiones condicionales.
        -   Comparación de valores (=, <, >, <=, =>, <>) siendo el último un != de C.
        -   Dichos valores pueden ser constantes, atributos de las relaciones mencionadas en el **FROM**.
        -   Operadores aritméticos (+, *, -, etc).
        -   Operadores de strings como:
            - || que es el operador concatenación.
- Puede utilizar cualquiera de los atributos de las relaciones en el **FROM**.

### **AS**

- Es opcional.
- Sirve para asignar un alias y definir cómo se formarán los valores de las tuplas a partir de los atributos de la relación para los que serán los atributos de la relación resultante.
- Ejemplo donde se la usa para renombre:

    ```SQL
    SELECT title AS name, length AS duration
    FROM Movies
    WHERE studioName = 'Disney' AND year = 1990;
    ```

- Ejemplo donde se la utiliza para definir cómo obtener valor de tupla para el atributo en relación resultante:

    ```SQL
    SELECT title AS name, length*0.016667 as lengthInHours
    ```

- Ejemplo donde se la usa para añadir un atributo a la relación resultante:

    ```SQL
    SELECT title AS name, length*0.016667 as length, 'hrs' AS inHours
    ```

### **ORDER BY**

- Cláusula que recibe una lista de atributos y/o expresiones en base a cuyos valores ordenar la relación. Se ordena en base al primer atributo, en caso de empate se recurre al segundo y así con cada uno.
- Orden por default es **ASC** pero podemos agregarle **DESC** a un atributo si queremos que sea descendente sobre él.
- Se encuentra después de las cláusulas **WHERE**, **GROUP BY** y **HAVING**. Se ejecuta el ordenamiento después de la ejecución de estas.
- Se ejecuta antes de realizar el **SELECT**.
- Ejemplo de **ORDER BY** con una expresión:

    ```SQL
    SELECT *
    FROM R
    ORDER BY A+B DESC;
    ```

### [Operaciones entre queries](#operaciones-entre-queries)

### **EXISTS/NOT EXISTS**

Se le aplica a una relación. Retorna **TRUE** si y solo si la relación no es vacía.

```SQL
EXISTS Movies
```

### **IN/NOT IN**

- **IN**:
  - Retorna **TRUE** si y solo si el parámetro previo es igual a uno de los valores del parámetro siguiente.
  - Ejemplo: En este caso retorna **TRUE** sii s es un valor de `Movies`, relación con tuplas del mismo tamaño que s. [Ver comparación entre tuplas](#comparación-de-tuplas).

    ```SQL
    s IN Movies
    ```

- **NOT IN**:
  - Retorna **TRUE** si y solo si el parámetro previo no es igual a ningún valor del parámetro siguiente.
  - Ejemplo: En este caso retorna **TRUE** sii s es distinto de todo valor en `Movies`, relación con tuplas de mismo tamaño que s. [Ver comparación entre tuplas](#comparación-de-tuplas).

  ```SQL
  s NOT IN Movies
  ```

### **ALL/NOT ALL**

- **ALL** retorna **TRUE** si y solo si la comparación de su primer parámetro (el previo al keyword) da **TRUE** contra todo valor del segundo parámetro (la relación con tuplas de mismo tamaño que primer parámetro [Ver comparación entre tuplas](#comparación-de-tuplas)).
- Ejemplo: Esto da **TRUE** sii s es mayor estricto que cualquier valor en R, relación con tuplas de mismo tamaño que s.

    ```SQL
    s > ALL R
    ```

- Podemos usar cualquier otro comparador.

### **ANY/NOT ANY**

- **ANY** retorna **TRUE** si y solo si existe al menos un valor de la relación como segundo parámetro que cumple la condición de comparación con el primer parámetro.
- Solo se pueden comparar tuplas y relaciones con tuplas del mismo tamaño, [Ver comparación entre tuplas](#comparación-de-tuplas).
- Ejemplo: Esto da **TRUE** sii hay alguna tupla en R, relación con tuplas de mismo tamaño que s, para la cual s es mayor estricto.

### [**CROSS JOIN**](#visto-como-cross-join)

### **JOIN ... ON**

- El **ON** es opcional.
- También se los conoce como **INNER JOIN**, podemos agregar opcionalmente **INNER** antes de la keyword **JOIN**.
- Se utiliza con la siguiente sintaxis: `relación1 JOIN relación2 ON condición` donde la condición define qué deben cumplir las tuplas para aplicarles el **JOIN**.
- Ejemplo:
  `Movies(title, year, length, genre, studioName, producerC#)`
  `Starsln(movieTitle, movieYear, starName)`

```SQL
Movies JOIN StarsIn ON
    title = movieTitle AND year = movieYear;
```

  Retorna una relación con las tuplas de $9$ *scalar values*, es decir los atributos de la relación `Movies` y los de `StarsIn` pero con tuplas que tenga el mismo título y año en su respectiva relación.

- Puede haber redudancia entre columnas. Como en ejemplo anterior que tendríamos dos columnas con otra idéntica. Para evitarlo podemos realizar el **JOIN ... ON** en una cláusula **FROM** y con **SELECT** quedarnos solo con los atributos distintos.

### **NATURAL JOIN**

En esta operación:

- Todos los atributos de mismo nombre son igualados, es decir sólo tenemos hacemos *join* tuplas de ambas relaciones donde los atributos con mismo nombre tienen el mismo valor.
- Sólo uno de los atributos de mismo nombre permanece en la relación resultante.
- Ejemplo:
    `MovieStar(name, address, gender, birthdate)`
    `MovieExec(name, address, cert# , netWorth)`

  ```SQL
  MovieStar NATURAL JOIN MovieExec;
  ```

  Retorna una relación con el conjunto (sin repetidos) de atributos de ambos pero sólo con las tuplas cuyos valores en `MovieStar.name = MovieExec.name` y `MovieStar.address = MovieExec.address`.

### Outerjoins

- Un *outer join* hace el *join* de las tuplas en ambas relaciones, pero añade valores **NULL** en los atributos para los cuales una tupla no tiene valor, porque no tiene uno con  

- El **ON** final es opcional, si lo ponemos tenemos una **theta outer join** mientras que si no lo ponemos y agregamos el **NATURAL** antes de indicar el lado (**LEFT|FULL|RIGHT)** tenemos una **natural outer join**.

- **LEFT JOIN** - Devuelve todas las filas de la tabla izquierda (la tabla anterior a la palabra clave **JOIN**).
  - Para las filas que tienen una coincidencia en la tabla derecha (→), devuelve los valores de la tabla derecha.
  - Para las filas sin coincidencia en la tabla derecha, rellena los valores que faltan con **NULL**s.
  - Ejemplo de **NATURAL LEFT OUTER JOIN**:

    ```SQL
    MovieStar NATURAL LEFT OUTER JOIN MovieExec;
    ```
  
  - Ejemplo de **LEFT OUTER JOIN ... ON**:

    ```SQL
    Movies LEFT OUTER JOIN StarsIn ON 
        title = movieTitle AND year = movieYear;
    ```

- **RIGHT JOIN** - Devuelve todas las filas de la tabla derecha (la tabla después de la palabra clave **JOIN**).
  - Para las filas que tienen una coincidencia en la tabla izquierda (←), devuelve los valores de la tabla izquierda.
  - Para las filas sin coincidencia en la tabla izquierda (←), rellena los valores que faltan con **NULL**s.
  - Ejemplo de **NATURAL RIGHT OUTER JOIN**:

    ```SQL
    MovieStar NATURAL RIGHT OUTER JOIN MovieExec;
    ```

  - Ejemplo de **RIGHT OUTER JOIN ... ON**:

    ```SQL
    Movies RIGHT OUTER JOIN StarsIn ON
        title = movieTitle AND year = movieYear;
    ```

- **FULL JOIN** - Devuelve todas las filas de ambas tablas, utilizando **NULL**s para los valores sin coincidencia, ya sean atributos de la primera o de la segunda relación.
  - Ejemplo de **NATURAL FULL OUTER JOIN**:

    ```SQL
    Movies NATURAL FULL OUTER JOIN StarsIn;
    ```

  - Ejemplo de **FULL OUTER JOIN ... ON**:

    ```SQL
    Movies FULL OUTER JOIN StarsIn ON
        title = movieTitle AND year = movieYear;
    ```

### [**DISTINCT**](#eliminación-de-duplicados) $\delta (R)$

### [**COUNT**, **MIN**, **AVG**, **SUM**, **MAX**](#aggregation)

### [**GROUP BY**](#grouping)

### **HAVING**

Permite aplicar un filtrado sobre los miembros de los grupos formados por [**GROUP BY**](#group-by) para sólo mantener en ellos a los que cumplan la condición.

Ejemplo:

```SQL
SELECT name, SUM(length)
FROM MovieExec, Movies
WHERE producerC# = cert#
GROUP BY name
HAVING MIN(year) < 1930;
```

Retorna una relación con los nombres de los productores con películas previas a $1930$ y la suma de las longitudes de las películas.

### **INSERT**

- Es de las sentencias que modifican la base de datos.
- Su forma básica es:

    ```SQL
    INSERT INTO R(A_1, ..., A_n) VALUES (v_1, ..., v_n);
    ```

  `R` es la relación con atributos `A_1, ..., A_n`. `(v_1, ..., v_n)` es la tupla que se inserta.
- Ejemplo:

    ```SQL
    INSERT INTO StarsIn(movieTitle, movieYear, starName)
    VALUES('The Maltese False', 1942, 'Sydney Greenstreet');
    ```

- Podemos poner varias tuplas tras **VALUES** separadas por comas.
- Si insertás valores para todos los atributos de la relación podés omitir listarlos al lado de la relación, es decir el `(A_1, ..., A_n)`, pero debés listar los valores correspondientes a cada atributo en el mismo orden.
- Podemos insertar valores sólo para unos atributos y que el resto de inicialicen al valor por *default*. Para eso debemos listar al lado del nombre de la relación los atributos que queremos llenar y en el mismo orden en la tupla tras **VALUES** los valores.
- Ejemplo: `Customers(CustomerID, CustomerName, ContactName, Address, City, PostalCode, Country)`

    ```SQL
    INSERT INTO Customers (CustomerName, City, Country)
    VALUES ('Cardinal', 'Stavanger', 'Norway');
    ```

- También podemos hacer **INSERT INTO** de todas las tuplas de la relación resultante de una *subquery*. En dicho caso la *subquery* reemplaza la keyword **VALUES** y la tupla. Por ejemplo:

    ```SQL
    INSERT INTO Studio(name)
        SELECT DISTINCT studioName
        FROM Movies
        WHERE studioName NOT IN
            (SELECT name
            FROM Studio);
    ```

### **DELETE**

- También modifica la base de datos.
- Se expresa como:

    ```SQL
    DELETE FROM R WHERE <condition>;
    ```

- Elimina de la relación `R` todas las tuplas que cumplan `<condition>`.
- Si omitimos `WHERE <condition>` se eliminan todas las tuplas de la relación.
- Ejemplo:

    ```SQL
    DELETE FROM StarsIn
    WHERE movieTitle = 'The Maltese Falcon' AND
          movieYear = 1942 AND
          starName = 'Sydney Greenstreet';
    ```

    Notar como debemo especificar todo lo necesario para que matchee la tupla que queremos.

### **UPDATE**

- También modifica la base de datos.
- Se expresa como:

    ```SQL
    UPDATE R SET <new-value assignments> WHERE <condition>;
    ```

- `<new-value assignments>` es una lista separada por comas de `atributo = nuevoValor`.
- Modifica tuplas que ya están en la base de datos.
- Se buscan todas las tuplas de la relación `R` que satisfacen la `<condition>` del **WHERE**, y a ellas se las modifica evaluando la expresión de `<new-value assignments>` en cada una.
- Ejemplo: `MovieExec(name, ad d ress, c e rt# , netWorth)`

    ```SQL
    UPDATE MovieExec
    SET name = 'Pres. ' || name
    WHERE cert# IN (SELECT presC# FROM Studio); 
    ```

## Orden de ejecución de cláusulas

El orden de primeras a últimas es:

- **FROM**.
- **WHERE**.
- **GROUP BY**.
- **HAVING**.
- **SELECT**.
- **DISTINCT**.
- **ORDER BY**.
- **LIMIT/OFFSET**.
- [Operaciones entre queries](#operaciones-entre-queries)

## Orden de declaración

De primeras a últimas:

- **SELECT**.
- **FROM**.
- **WHERE**.
- **GROUP BY**.
- **HAVING**.
- **ORDER BY**.

## Tipos de datos

### Reales

Se utiliza la notación estándar. Por ejemplo:

```SQL
-12.34
1.23E45
```

### Booleanos

```SQL
TRUE
FALSE
```

Podemos usar cualquiera de los siguientes operadores lógicos: `NOT`, `AND`, `OR`, ordenados de mayor a menor precedencia.

### Strings

- Pueden ser de dos tipos:
  - Longitud fija: Usamos `CHAR`.
  - Longitud variable en el rango declarado: Usamos `VARCHAR`, en caso de no llegar al límite se añade *padding*.
- Al comparar dos *strings* de distinto tipo sólo se comparan los caracteres usados, ignorando el *padding*.
- Los comparadores aritméticos al aplicarse entre *strings* usan el orden lexicográfico.
- Podemos comparar vía *pattern matching* con una expresión del tipo

    ```SQL
    string LIKE pattern
    ```

#### ¿Qué es un *pattern*?

Es un *string* que puede utilizar dos caracteres especiales `%` y `_` donde:

- `%` matchea con cualquier secuencia de cero o más caracteres. Similar a un `*` de una *regex*.
- `_` matchea con cualquier caracter.

    ```SQL
    SELECT title
    FROM Movies
    WHERE title LIKE 'Star ____';
    ```

Donde cualquier title que consista en la palabra "Star" seguida de un espacio y $4$ letras va a hacer matching.

#### Bit Strings

Se representa con B seguido de ceros y unos entre comillas simples.

```SQL
B'01101'
```

#### Hex Strings

Se representan con X seguido del resto de dígitos entre 0-9, a-f.

```SQL
X'7ff'
```

### Dates & Times

- Podemos usar comparadores aritméticos con ellos.

#### Dates

Se representan con la keyword **DATE** seguida de un *string* con el siguiente formato 'XXX-XX-XX' donde X representa un dígito en $[0,9]$ cualquiera, no necesariamente iguales.

```SQL
DATE '1948-05-14'
```

Es necesario aplicar el *padding* con ceros para cumplir con el formato.

#### Time

Se representan con la keyword **TIME** seguida de un *string* con uno de los siguientes formatos:

- Formato 'XX:XX:XX.X' que representan horas $[0,23]$, minutos $[0,59]$, segundos $[0,59]$ y milisegundos.
- Formato 'XX:XX:XX[+|-]X:XX' donde el X tras un signo `+` o `-` indica la diferencia respecto al *Greenwich Mean Time*.

#### Timestamps

Combinan fechas y horarios. Se representan con la keyword **TIMESTAMP** seguida de un *string* compuesto por una fecha en formato válido, un espacio y un horario en un formato válido.

```SQL
TIMESTAMP '1948-05-14 12:00:00'
```

### NULL

- No es una constante, entonces no puede ser usado en una expresión como operando, pero sí podemos usar una variable que tenga ese valor. Es decir `NULL + 3` está mal pero `x + 3` con `x` con valor **NULL** es sintaxis correcta.
- Usarlo como operando izquierdo ← es sintaxis inválida.
- Podemos ver si un atributo tiene el valor **NULL** mediante `attribute IS NULL` o `attribute IS NOT NULL`.

Este dato admite múltiples interpretaciones semánticas:

- Valor desconocido.
- Valor inaplicable, no tiene sentido que haya un valor ahí, e.g. nombre de esposa en una tupla representando a un soltero.
- Valor retenido, no nos correponde saberlo.

#### Casos en los que lo podemos obtener en una tupla

- En *outerjoins*.
- En *insertions*.

#### Comparación con NULL

En **WHERE** podemos encontrarnos con un **NULL** si una tupla lo tiene en uno de los atributos de la condición de este.

- Con operadores aritméticos el **NULL** es absorbente, el resultado siempre será **NULL**.
- Con operadores de comparación el resultado es un **UNKNOWN**, incluso al comparar entre **NULLs**.

### UNKNOWN

Es un valor de verdad que surge tras la operación con **NULL** de otro valor de verdad.

#### Valor de UNKNOWN en expresiones lógicas

Regla mental:

- `TRUE`    → vale 1.
- `FALSE`   → vale 0.
- `UNKNOWN` → vale 1/2.

- `AND` tiene el valor de verdad del mínimo de los valores de verdad de sus operandos.
- `OR` tiene el valor del verdad del máximo de los valores de verdad de sus operandos.
- `NOT` tiene el valor de verdad de $1 - X$, donde $X$ es el valor de verdad de su operando.

#### Siempre considerar que pueden existir tuplas con valores NULL

```SQL
SELECT *
FROM Movies
WHERE length <= 120 OR length > 120;
```

No devuelve toda la relación Movies, porque si una tupla tiene length **NULL**, entonces la condición evalúa a **UNKNOWN** y no se considera esa tupla en la relación resultante.

## Constraints and Triggers

- ***active elements***: Son expresiones/declaraciones que escribimos una vez y se almacenan en la base de datos, esperando que se ejecuten cuando ocurra un evento específico.

- Podemos manejar desde *backend* los chequeos de que los datos sean correctos o podemos delegarselo al **DBMS** admin de la base de datos.

### Keys and Foreign Keys

#### **Foreign key constraint**

Se asegura que si un atributo de una tabla es *foreign key* de otra, el valor de este debe aparecer como componente de la *primary key* de la otra relación.

##### ¿Cómo las declaramos?

- El atributo al que hagamos referencia en la segunda relación debe ser **UNIQUE** o **PRIMARY KEY** de dicha relación.
- Si tenemos una *foreign key* $F$ que referencia a un set de atributos $G$ de otra relación, asumiendo que una tupla de la primer relación no tiene valores **NULL** en los atributos de $F$, entonces los valores de esa tupla para los atributos de $G$ deben coincidir con los de otra tupla en la segunda relación para los atributos de $G$.
- Podemos declarar *foreign keys* que referencien otros atributos de la relación actual.
- Si el atributo de nuestra tabla que es *foreign key* tiene valor **NULL**, no requerimos que en la tabla a la que referencia haya una tupla con **NULL** en el atributo referenciado, que como debe ser key solo podría tomar el valor **NULL** si fuera el atributo fuera declarado como **UNIQUE** es ves de como **PRIMARY KEY**.
- Si la *foreign key* es sobre un solo atributo, entonces lo declaramos:

```SQL
    <atributo> REFERENCES <otra tabla>(<atributo de otra tabla>)

    CREATE TABLE Studio (
    name CHAR(30) PRIMARY KEY,
    address VARCHAR(255),
    presC# INT REFERENCES MovieExec(cert#)
    );
```

- Si es una lista de atributos, entonces en la lista de atributos del **CREATE TABLE** ponemos:

```SQL
    FOREIGN KEY (<atributo>) REFERENCES <otra tabla>(<atributo de otra tabla>)

    CREATE TABLE Studio (
    name CHAR(30) PRIMARY KEY,
    address VARCHAR(255),
    presC# INT,
    FOREIGN KEY (presC#) REFERENCES MovieExec(cert#)
    );
```

##### Si la declaramos... ¿Qué cosas previene?

Para mantener la **integridad referencial** el **DBMS** lanza una excepción o un error en run time si sucede alguna de las siguientes acciones: Supongamos que tenemos una relación $A$ con un atributo $a$ que es *foreign key* de otro atributo $b$ *key* de otra relación $B$.

1. Si intentamos insertar([**INSERT**](#insert)) una tupla en $A$ cuyo valor para $a$ no es **NULL** y no está en el componente $b$ de ninguna tupla de $B$.
2. Si intentamos modificar ([**UPDATE**](#update)) una tupla de $A$ para poner en $a$ un valor que no aparece en el atributo $b$ de ninguna tupla de $B$.
3. Si intentamos borrar ([**DELETE**](#delete)) de $B$ una tupla cuyo valor para el atributo $b$ no es **NULL** y aparece como valor del atributo $a$ de alguna tupla en $A$.
4. Si intentamos modificar ([**UPDATE**](#update)) una tupla de $B$ cambiando el valor del atributo $b$ el cuál tenía una tupla en $A$ con dicho valor para el atributo $a$.

$1 \lor{} 2 \Rightarrow{rechazar~modificación}$

$3 \lor{} 4 \Rightarrow{}$ *default policy* $\lor{}$ *cascade policy* $\lor{}$ *set-null policy*

- ***Default policy***: Rechazar toda modificación no cumpla esto.

- ***Cascade policy***: Actualizar/borrar valor de atributo en $a$ de tupla en relación $A$.

- ***Set-Null policy***: Cambiar a **NULL** valor en atributo $a$ de tupla de $A$.

Estas políticas se definen al momento de declarar la *foreign key*. Podemos elegir una para [**UPDATE**](#update) y otra para [**DELETE**](#delete)

```SQL
CREATE TABLE Studio (
    name CHAR(30) PRIMARY KEY,
    address VARCHAR(255),
    presC# INT REFERENCES MovieExec(cert#)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
```

##### ***Dangling tuples***

Una ***dangling tuple*** es una tupla con un valor de *foreign key* que no aparece en la relación referenciada. Estas tuplas tampoco participarán en un [**JOIN**](#join--on) ya que si es sobre igualdad entre valor de atributo *foreign key* y el atributo *key*.

##### Posponer chequeo de ***constraints***

Si tenés una relación $A$ con un atributo $a$ que es *foreign key* de otro atributo $b$ de otra relación $B$, y querés añadir una nueva tupla a $A$ con un valor para $a$ que no se encuentra en ninguna tupla en $B$, entonces para preservar la [*foreign key constraint*](#foreign-key-constraint) podés:

1. Agregar la tupla a $A$ pero con valor **NULL** en atributo $a$, añadir tupla correspondiente a $B$ con ese nuevo valor en atributo $b$ y finalmente cambiar valor de atributo $a$ de la tupla añadida en $A$ al nuevo valor.
2. Agregar nueva tupla a $B$ con nuevo valor en $b$ y después añadir tupla a $A$ con nuevo valor en $a$.

Esto se rompe si el grafo de referencias tiene un ciclo, por ejemplo si $a$ es *foreing key* de $b$ en $A$ y $b$ es *foreign key* de $a$ en $B$. Para solucionar eso podemos:

1. Agrupamos los dos [**INSERT**](#insert) en una sola transacción.
2. Le decimos al **DBMS** que no chequee las *constaints* hasta que haya terminado esa transacción.

Para ello debemos seguir a la declaración de cada *key*, *foreign key* o otra *constaint* de keyword **DEFERRABLE** o **NOT DEFERRABLE**, siendo este último el valor por default.

- **NOT DEFERRABLE**: Se chequea inmediatamente después del *statement* de modificación si esta puede romper *constaint*.
- **DEFERRABLE**: Esperar a que la transacción se complete.
  - **INITIALLY DEFERRED**: Se pospone chequeo hasta justo antes de que transacción haga *commit*.
  - **INITIALLY IMMEDIATE**: Se realiza el chequeo inmediatamente después de cada *statement*.

```SQL
CREATE TABLE Studio (
    name CHAR(30) PRIMARY KEY,
    address VARCHAR(255),
    presC# INT UNIQUE
    REFERENCES MovieExec(cert#)
    DEFERRABLE INITIALLY DEFERRED
);
```

Podemos definirlo también para *constaints* propias. Por ejemplo si definimos la *constraint* con nombre <**ConstaintName**>, podemos definir su comporamiento ante estos casos con: `SET CONSTRAINT <ConstaintName> DEFERRED;` y deshacerlo con `SET CONSTRAINT <ConstaintName> IMMEDIATE;`
