# Apunte SQL

Fuentes:

- "Databases, the complete book", chapter 6, Ullman.

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

## Paralelismo con álgebra relacional

```SQL
    SELECT L
    FROM R
    WHERE C
```

Es equivalente al $\pi_{L}(\sigma_{C}(R))$.

### Producto

```SQL
    SELECT name 
    FROM Movies, MovieExecutives
    WHERE title = 'Star Wars' AND producerC# = cert#;
```

Al poner varias relaciones en el **FROM** pasamos a considerar todas las posibles tuplas resultantes de combinar los atributos en bloque de la relación Movies con los atributos en bloque de la relación MovieExecutives. Podés verlo como FROM R_1, R_2 es flatten([attrs(R_1), attrs(R_2)]) renombrando en caso de colisión.

Si una de las relaciones es vacía no habrá forma de formar una tupla con atributos de todas las relaciones, así que la query resultará en una relación vacía.

### Operaciones entre queries

**SQL** nos permite realizar operaciones entre queries encerradas entre paréntesis.

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

### Subqueries

- Son queries dentro de otras queries. En **SQL** podemos anidar queries tanto como queramos.
- Pueden aparecer en:
  - Retornando relaciones o una constante que usamos en cláusulas **WHERE**.
  - En cláusulas **FROM** seguidas de una [variable de tupla](#tuplas-como-variables) que representa una tupla de la relación resultante de la *subquery*.
  
## Keywords y su significado

### **SELECT**

- Cláusula que indica qué atributos de las tuplas que cumplan las condiciones irán a la relación resultante.
- `*` Significa proyectar todos los atributos.
- Podemos indicar los atributos que queremos proyectar de las tuplas separados por comas.
- Es como la proyección del álgebra relacional.
- Puede referirse a cualquiera de los atributos de las relaciones en el **FROM**.

### **FROM**

- Cláusula que indica la/s relación/es a las que se refiere la query.

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

## Orden de ejecución de cláusulas

El orden de primeras a últimas es:

- [].
- **ORDER BY**.
- **SELECT**.
- [Operaciones entre queries](#operaciones-entre-queries)

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
