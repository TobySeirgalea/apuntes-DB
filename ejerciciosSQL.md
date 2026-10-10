# Ejercicios SQL

2.1. Considerando el esquema de base de datos Chinook. Se pide:

(a) Mediante SQL, AR y SQL listar Nombres (FirstName y LastName) de los clientes (Customer) de Brasil.

```SQL
SELECT c.first_name, c.last_name
FROM customer c
WHERE c.country = 'Brazil';
```

(b) Mediante SQL, AR y SQL listar para cada cliente (Customer) las facturas (Invoice) que tiene. Se deberá mostrar el nombre del cliente, la fecha y número de factura (InvoiceDate e InvoiceID).

```SQL
SELECT c.first_name, c.last_name, i.invoice_date, i.invoice_id
FROM customer c INNER JOIN invoice i on c.customer_id = i.customer_id;
```

(c) Mediante SQL, AR y SQL listar, para cada track, el nombre del artista (Artist) que hizo el Album al que pertenece dicho track.

```SQL
SELECT t.track_id, t.name, artist.name
FROM track t INNER JOIN album a ON t.album_id = a.album_id
             INNER JOIN artist ON artist.artist_id = a.artist_id;
```

(e) Mediante SQL obtener los nombres de las PlayList que tienen más de 10 tracks de álbumes de ”Iron Maiden”.

```SQL
WITH tracks_de_iron_maiden AS (
    SELECT t.track_id
    FROM track t
        INNER JOIN album al 
            ON al.album_id = t.album_id
        INNER JOIN artist ar
            ON ar.artist_id = al.artist_id
    WHERE ar.name = 'Iron Maiden'
)
SELECT p.name
FROM playlist p
    INNER JOIN playlist_track pt ON p.playlist_id = pt.playlist_id
    INNER JOIN tracks_de_iron_maiden t ON t.track_id = pt.track_id
GROUP BY p.playlist_id, p.name
HAVING count(pt.track_id) > 10
```

(f) Mediante SQL indicar cuantos álbumes tiene cada PlayList. Debe devolver nombre de la PlayList y cantidad de álbumes.

```SQL
SELECT p.name, count(a.album_id)
FROM playlist p 
    INNER JOIN playlist_track pt 
        ON p.playlist_id = pt.playlist_id
    INNER JOIN track t 
        ON pt.track_id = t.track_id
    INNER JOIN album a 
        ON t.album_id = a.album_id
GROUP BY p.name
```

- Contamos `a.album_id` porque el `a.title` y el `a.artist_id` no necesariamente son únicos, entonces si tuviéramos dos álbumes distintos pero con el mismo título los contaríamos como uno, lo mismo si fuesen distintos pero del mismo artista, en el caso de que hiciéramos `count(a.artist_id)`.
**DUDA:**
- Tenemos nombres repetidos, pero si agregamos al `SELECT` `p.playlist_id` veremos que se trata de playlist con distinto id, pero mismo nombre, por lo tanto son distintas. Si agrupamos por `p.name` esas filas las perdemos, ya que nada nos asegura que `p.name` sea único.

(g) Mediante SQL listar los nombres de los empleados (Employee) mayores de 25 años que tienen al menos una factura (Invoice) con más de 10 ítems.

```SQL
WITH empleados_mayores_de_25 AS (
    SELECT e.*
    FROM employee e
    WHERE current_date - e.birth_date >= '25 year'
), id_facturas_con_mas_de_10_items AS (
    SELECT il.invoice_id
    FROM invoice_line il
    GROUP BY il.invoice_id
    HAVING count(il.invoice_line_id) > 10
), vendedores_de_clientes_de_facturas_con_mas_de_10_items AS (
    SELECT c.support_rep_id
    FROM invoice i
        INNER JOIN id_facturas_con_mas_de_10_items j
            ON i.invoice_id = j.invoice_id
        INNER JOIN customer c
            ON c.customer_id = i.customer_id
)
SELECT DISTINCT e.first_name, e.last_name
FROM empleados_mayores_de_25 e
    INNER JOIN vendedores_de_clientes_de_facturas_con_mas_de_10_items c
        ON e.employee_id = c.support_rep_id;
```

- Aunque la función de agregación no la use en el `SELECT`, sino en el `HAVING`, si quiero retornar un/unos atributo/s sin una función de agregación sobre él/ellos, antes debo agrupar por ese/esos atributos.
- Si en el `SELECT` le ponés un nombre a una agregación u atributos utilizando `AS`, ese nombre nombre no es válido para utilizarlo en el `HAVING`.

(h) Mediante SQL resolver el punto b) incluyendo en el listado los clientes que no tienen ninguna factura.

```SQL
SELECT c.first_name, c.last_name, i.invoice_date, i.invoice_id
FROM customer c LEFT OUTER JOIN invoice i on c.customer_id = i.customer_id;
```

- El tema es que como no hay tuplas en la relación *customer* que no tengan facturas asociadas no se aprecia la diferencia entre el resultado de esta query y la del b), pero si agregamos una tupla a *customer* si.

(i) Mediante SQL listar los nombres de los empleados que soportan clientes con más de 10 facturas.

```SQL
WITH ids_clientes_de_mas_de_10_facturas AS (
    SELECT c.customer_id
    FROM customer c
        INNER JOIN invoice i
            ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
    HAVING count(i.invoice_id) > 10
), 
ids_empleados_con_clientes_de_mas_de_10_facturas AS (
    SELECT c.support_rep_id as employee_id
    FROM customer c
        INNER JOIN ids_clientes_de_mas_de_10_facturas i
            ON c.customer_id = i.customer_id
)
SELECT DISTINCT e.first_name, e.last_name
FROM employee e 
	INNER JOIN ids_empleados_con_clientes_de_mas_de_10_facturas i 
		ON i.employee_id = e.employee_id
```

- En la primer CLE (`ids_clientes_de_mas_de_10_facturas`) estoy haciendo un `INNER JOIN` entre dos, la PK de una con la FK de la otra hacia ella para luego agrupar por esa misma. Podría ser más eficiente y directamente usar la tabla que la tiene como FK.

Versión mejorada:

```SQL
WITH ids_clientes_de_mas_de_10_facturas AS (
    SELECT i.customer_id
    FROM invoice i
    GROUP BY i.customer_id
    HAVING count(i.invoice_id) > 10
), 
ids_empleados_con_clientes_de_mas_de_10_facturas AS (
    SELECT c.support_rep_id as employee_id
    FROM customer c
        INNER JOIN ids_clientes_de_mas_de_10_facturas i
            ON c.customer_id = i.customer_id
)
SELECT DISTINCT e.first_name, e.last_name
FROM employee e 
	INNER JOIN ids_empleados_con_clientes_de_mas_de_10_facturas i 
		ON i.employee_id = e.employee_id
```

- Los alias declarados en el `FROM` si que tienen alcance en el `HAVING`, pero los declarados en el `SELECT` no.
- Si es una relación que surge de una M:N me puedo ahorrar el join con cualquiera de las otras dos si necesito sus claves porque ya las tengo.

(j) Mediante SQL listar los empleados junto a su jefe. Las tuplas resultantes tendrán la siguiente forma: (nombre empleado (FirstName), apellido de empleado (LastName), nombre jefe, apellido de jefe)

```SQL
SELECT e.first_name, e.last_name, j.first_name, j.last_name
FROM employee e
    INNER JOIN employee j
        ON e.reports_to = j.employee_id
```

- Para el caso del empleado de mayor jerarquía, que debería tener `reports_to = NULL` no coincide con ninguno en el `INNER JOIN` y por eso no se muestra.

(k) Resolver el ítem anterior pero que no falte ningún empleado en el listado

```SQL
SELECT e.first_name, e.last_name, j.first_name, j.last_name
FROM employee e
    LEFT OUTER JOIN employee j
        ON e.reports_to = j.employee_id
```

- Al usar `LEFT OUTER JOIN` mantenemos a todos los de la primera tabla (*employee* en este caso), incluso a los que no cumplen la condición de join, como es el caso del más alto en la jerarquía ya que al no tener jefes la condición de join `e.reports_to = j.employee_id` falla por ser `j` `NULL`.

(l) Obtener mediante SQL el promedio de tracks comprados en las facturas de cada cliente. Es decir si en una factura compro 8 tracks y en otra 4 el promedio es 6.

```SQL
WITH cantidad_tracks_de_factura AS (
SELECT il.invoice_id, count(il.track_id) AS cantidad_de_tracks
FROM invoice_line il 
GROUP BY il.invoice_id
),
promedio_tracks_por_cliente AS (SELECT i.customer_id, AVG(ct.cantidad_de_tracks) AS promedio
FROM invoice i 
    INNER JOIN cantidad_tracks_de_factura ct
        ON ct.invoice_id = i.invoice_id
GROUP BY i.customer_id)

SELECT c.customer_id, c.first_name, c.last_name, p.promedio
FROM customer c 
    INNER JOIN promedio_tracks_por_cliente p
        ON c.customer_id = p.customer_id;
```

Si te interesara considerar también a los clientes que aún no compraron nada, entonces modificando `promedio_tracks_por_cliente` nos los incluye pero con promedio `NULL`:

```SQL
promedio_tracks_por_cliente AS (SELECT c.customer_id, AVG(ct.cantidad_de_tracks) AS promedio
FROM customer c 
    LEFT OUTER JOIN invoice i
        ON i.customer_id = c.customer_id
    LEFT OUTER JOIN cantidad_tracks_de_factura ct
        ON ct.invoice_id = i.invoice_id
GROUP BY c.customer_id)
```

(m) Obtener para cada empleado el total de tracks del género ”Rock” comprados por los clientes que soporta.

```SQL
WITH rock_tracks_ids AS (
    SELECT t.track_id
    FROM track t 
        INNER JOIN genre 
			ON genre.genre_id = t.genre_id
    WHERE genre.name = 'Rock'
),
id_and_amount_of_rock_tracks_purchased_by_client AS (
    SELECT i.customer_id, count(r.track_id) AS amount_of_rock_tracks
    FROM invoice_line il
        INNER JOIN invoice i
            ON il.invoice_id = i.invoice_id
        INNER JOIN rock_tracks_ids r
            ON il.track_id = r.track_id
    GROUP BY i.customer_id
),
employee_who_sold_rock_tracks_to_client AS (
    SELECT c.support_rep_id AS employee_id, i.amount_of_rock_tracks
    FROM customer c 
        INNER JOIN id_and_amount_of_rock_tracks_purchased_by_client i
            ON i.customer_id = c.customer_id
)
SELECT e.employee_id, em.first_name, em.last_name, SUM(e.amount_of_rock_tracks)
    FROM employee_who_sold_rock_tracks_to_client e 
        INNER JOIN employee em
            ON em.employee_id = e.employee_id 
    GROUP BY e.employee_id, em.first_name, em.last_name
```

- Como el primer atributo de la cláusula `GROUP BY` de la query final tiene primero la PK, entonces el valor de esa columna es único, por lo tanto todos los que compartan ese valor tienen todos los demás atributos de la tupla con ese valor de PK en su respectiva tabla. Luego, añadir más atributos de esa respectiva tabla para poder listarlos en la cláusula `SELECT` no altera el resultado de la query. Finalmente podemos concluir que si agrupamos un el valor que es PK en una tabla, entonces podemos añadir sin problema todos los demás atributos de ella que queramos que aparezcan en tabla resultante de la consulta. En este caso `em.first_name` y `em.last_name`, pero tuvimos que añadir un `INNER JOIN` con la tabla para obtenerlos.
- En PostgreSQL el orden no importa en los atributos del `GROUP BY`.

Alternativa más óptima:

```SQL
    SELECT e.employee_id, e.first_name, e.last_name, count(il.invoice_line_id) AS amount_of_rock_tracks
    FROM invoice_line il
        INNER JOIN invoice i
            ON il.invoice_id = i.invoice_id -- Juntamos facturas con sus lineas
        INNER JOIN track t
            ON il.track_id = t.track_id -- A eso lo juntamos con el id del track de esa línea
        INNER JOIN genre g
            ON g.genre_id = t.genre_id -- A eso lo juntamos con el género de ese track
        INNER JOIN customer c
            ON i.customer_id = c.customer_id -- A eso lo juntamos con el cliente de esa factura
        INNER JOIN employee e
            ON e.employee_id = c.support_rep_id -- A eso lo juntamos con el vendedor asociado al cliente
    WHERE g.name = 'Rock' -- Solo nos interesan los de género 'Rock'
    GROUP BY e.employee_id, e.first_name, e.last_name
```

2.2. Considerando el siguiente esquema de una base de datos:

```SQL
FRECUENTA(Persona, Bar)
SIRVE (Bar, Cerveza)
GUSTA(Persona, Cerveza).
```

Se pide en AR, SQL y SQL obtener:
(a) Bares que sirven alguna cerveza que le guste a “Juan K.”

```SQL
SELECT DISTINCT s.Bar 
FROM Sirve s INNER JOIN Gusta g ON g.Cerveza = s.Cerveza
WHERE g.Persona = 'Juan K.';
```

- Si no ponemos `DISTINCT` nos va a retornar repetidos en caso de que a una persona le gusten dos cervezas que sean servidas por un mismo bar.

(b) Personas que frecuentan al menos un bar que sirve alguna cerveza que les guste.

```SQL
SELECT f.Persona
FROM Frecuenta f 
    INNER JOIN Sirve s 
        ON f.Bar = s.Bar
    INNER JOIN Gusta g 
        ON g.Cerveza = s.Cerveza AND g.Persona = f.Persona
GROUP BY f.Persona
HAVING count(f.Bar) > 0;
```

Alternativa:

```SQL
SELECT f.Persona
FROM Frecuenta f 
    INNER JOIN Sirve s 
        ON f.Bar = s.Bar
    INNER JOIN Gusta g 
        ON g.Cerveza = s.Cerveza 
WHERE g.Persona = f.Persona
GROUP BY f.Persona
HAVING count(f.Bar) > 0;
```

- El `INNER JOIN` ya te da todas las tuplas de ambas relaciones que cumplen la condición del `ON` por lo que no vamos a tener personas que frecuenten bares que no sirvan ninguna que les guste porque fallarían en el `WHERE g.Persona = f.Persona` (en el `ON g.Cerveza = s.Cerveza AND g.Persona = f.Persona` para los del caso anterior), por lo que podemos ahorrarnos el `GROUP BY` y el `HAVING`.

```SQL
SELECT DISTINCT f.Persona
FROM Frecuenta f 
    INNER JOIN Sirve s 
        ON f.Bar = s.Bar
    INNER JOIN Gusta g 
        ON g.Cerveza = s.Cerveza 
WHERE g.Persona = f.Persona
```

- Es necesario añadir `DISTINCT` ya que si una persona frecuenta varios bares que sirven cervezas que le gustan aparecerá muchas veces.

(c) Personas que no frecuenten ningún bar que sirva una cerveza que les guste.

```SQL
(SELECT f.Persona 
FROM Frecuenta f)
EXCEPT 
(SELECT f.Persona
    FROM Frecuenta f 
        INNER JOIN Sirve s 
            ON f.Bar = s.Bar
        INNER JOIN Gusta g 
            ON g.Cerveza = s.Cerveza AND g.Persona = f.Persona
    GROUP BY f.Persona
    HAVING count(f.Bar) > 0);
```

- A todas las personas que frecuentan un bar le sacamos las personas que frecuentan al menos un bar que sirva una cerveza que le guste.
- Por mismo motivo de item anterior te podés ahorra el `GROUP BY` y el `HAVING`.
- Falta añadirle las personas que les gusta una cerveza pero no frecuentan ningún bar.

```SQL
(SELECT f.Persona FROM Frecuenta f) UNION (SELECT g.Persona FROM Gusta g) -- Todas las posibles personas
EXCEPT 
(SELECT f.Persona
    FROM Frecuenta f 
        INNER JOIN Sirve s 
            ON f.Bar = s.Bar
        INNER JOIN Gusta g 
            ON g.Cerveza = s.Cerveza AND g.Persona = f.Persona),
```

- Si hay un atributo del cual queremos todos sus posibles valores, y este se encuentra en más de una tabla, debemos hacer la `UNION` de la proyección de ese atributo en cada tabla en la que se encuentre.
- No hace falta usar `DISTINCT` en los `SELECT` del `UNION` ya que aunque estos nos devuelvan repetidos, el `UNION` los elimina. El que no elimina repetidos es el `UNION ALL`.

(d) Personas que frecuentan todos los bares. (Asumir que todos los bares sirven al menos una cerveza).

- Primero debo obtener todos los bares, que son valores de un atributo que se encuentra en varias tablas distintas, como en item previo. El esquema inicial no está bien modelado ya que si tenemos solo estas relaciones, entonces si ya nadie frecuenta un bar esta entidad desaparece, lo mismo con las cervezas si a nadie le gustan y ningún bar las sirve.

```SQL
WITH bares AS ((SELECT f.Bar FROM Frecuenta f) UNION (SELECT s.Bar FROM Sirve s)),
     cantidad_de_bares_frecuentados_por_persona AS (
        SELECT f.Persona, count(f.Bar) AS cantidad_bares
        FROM Frecuenta f
        GROUP BY f.Persona)
SELECT c.Persona
FROM cantidad_de_bares_frecuentados_por_persona c
WHERE c.cantidad_bares = (SELECT count(b.Bar) FROM bares b)
```

**Pendiente**
(e) (Sólo para SQL) Definir una vista que devuelva una relación de la forma (p, c, b) de
tal manera que a la persona p le gusta la cerveza c, el bar b sirve la cerveza c y la
persona p frecuenta el bar b.

```SQL

```

2.3. Considerando el esquema de base de datos Chinook
(a) Mediante SQL obtener los álbumes que tiene al menos un track en TODAS las PlayLists.

```SQL
WITH album_presences_in_playlist AS (
    SELECT a.album_id, count(pt.playlist_id) AS presences_in_playlists
    FROM album a
        INNER JOIN track t 
            ON t.album_id = a.album_id
        INNER JOIN playlist_track pt
            ON pt.track_id = t.track_id
    GROUP BY a.album_id)
SELECT a.album_id, a.title, ar.name
FROM album a
    INNER JOIN album_presences_in_playlist p 
        ON p.album_id = a.album_id
	INNER JOIN artist ar 
        ON ar.artist_id = a.artist_id 
WHERE p.presences_in_playlists = (SELECT count(p.playlist_id) FROM playlist p);
```

- Notar que las funciones de agregación se aplican sobre la relación resultante de los `JOINS` en el `FROM`, por lo que en `album_presences_in_playlist` estamos aplicando `count(pt.playlist_id)` sobre una relación donde tenemos una tupla por cada track del álbum, y una por cada una de estas a su vez otra tupla por cada playlist donde se incluye ese track. Luego al agrupar por `album_id` tenemos para cada álbum un *bucket* con todas las tuplas con sus distintos tracks como con todas las playlists donde aparece cada uno, entonces al aplicar sobre ese *bucket* `count(pt.playlist_id)` terminamos contando una playlist por tantas veces como tracks de ese álbum incluya. Esto sucede porque en el *bucket* tenemos para un mismo `pt.playlist_id` tantas tuplas como tracks del álbum incluya. Por eso debemos usar `count(DISTINCT pt.playlist_id)`.

Corrección:

```SQL
WITH album_presences_in_playlist AS (
    SELECT a.album_id, count(DISTINCT pt.playlist_id) AS presences_in_playlists
    FROM album a
        INNER JOIN track t 
            ON t.album_id = a.album_id
        INNER JOIN playlist_track pt
            ON pt.track_id = t.track_id
    GROUP BY a.album_id)
SELECT a.album_id, a.title, ar.name
FROM album a
    INNER JOIN album_presences_in_playlist p 
        ON p.album_id = a.album_id
	INNER JOIN artist ar 
        ON ar.artist_id = a.artist_id 
WHERE p.presences_in_playlists = (SELECT count(p.playlist_id) FROM playlist p);
```

(b) Mediante SQL obtener los artistas que tienen menos álbumes en PlayList

```SQL
WITH album_presences_in_playlist AS (
    SELECT a.album_id, count(DISTINCT pt.playlist_id) AS presences_in_playlists
    FROM album a
        INNER JOIN track t 
            ON t.album_id = a.album_id
        INNER JOIN playlist_track pt
            ON pt.track_id = t.track_id
    GROUP BY a.album_id),
    artists_albums_in_playlist AS (
    SELECT ar.artist_id, ar.name, SUM(p.presences_in_playlists) AS total_presences_in_playlists
    FROM album_presences_in_playlist p
        INNER JOIN album a
            ON a.album_id = p.album_id
        INNER JOIN artist ar
            ON ar.artist_id = a.artist_id
        GROUP BY ar.artist_id, ar.name
)
SELECT a.artist_id, a.name, a.total_presences_in_playlists
FROM artists_albums_in_playlist a
WHERE a.total_presences_in_playlists = (SELECT MIN(b.total_presences_in_playlists) FROM artists_albums_in_playlist b)
```

- Si lo que querían era que obtengamos los artistas con menos álbumes distintos que aparezcan en las playlist, en vez de los artistas que tienen menor presencias de sus álbumes en playlist, entonces la query sería la siguiente:

```SQL
WITH artists_albums AS (
    SELECT ar.artist_id, a.album_id
    FROM artist ar
        INNER JOIN album a
            ON a.artist_id = ar.artist_id),
    playlists_albums AS (
        SELECT a.album_id, pt.playlist_id
        FROM playlist_track pt
            INNER JOIN track t
                ON t.track_id = pt.track_id
            INNER JOIN album a
                ON a.album_id = t.album_id
    ),
    artists_albums_in_playlists AS (
        SELECT aa.artist_id, count(DISTINCT aa.album_id) AS distinct_albums_in_playlists
        FROM artists_albums aa
            INNER JOIN playlists_albums pa
                ON aa.album_id = pa.album_id
        GROUP BY aa.artist_id
    )
    SELECT a.artist_id, a.name, aa.distinct_albums_in_playlists
    FROM artist a
        INNER JOIN artists_albums_in_playlists aa
            ON aa.artist_id = a.artist_id
    WHERE aa.distinct_albums_in_playlists = (SELECT MIN(b.distinct_albums_in_playlists) FROM artists_albums_in_playlists b) 
```

Alternativa:

- Podemos ahorrarnos el `INNER JOIN` entre *artist* y *album* ya que en *album* tenemos también el `artist_id` que es lo único que usamos ahí.

```SQL
WITH 
    artists_albums_in_playlists AS (
        SELECT a.artist_id, ar.name, count(DISTINCT a.album_id) AS distinct_albums_in_playlists
        FROM playlist_track pt
            INNER JOIN track t
                ON t.track_id = pt.track_id
            INNER JOIN album a
                ON a.album_id = t.album_id
            INNER JOIN artist ar
                ON ar.artist_id = a.artist_id
        GROUP BY a.artist_id, ar.name
    ),
    SELECT a.artist_id, a.name, a.distinct_albums_in_playlists
    FROM artists_albums_in_playlists a
    WHERE a.distinct_albums_in_playlists = (SELECT MIN(b.distinct_albums_in_playlists) FROM artists_albums_in_playlists b) 
```

2.4. Considerando el esquema de base de datos Chinook
(a) Mediante SQL, AR y SQL obtener los playlist que no contengan ningún track de los álbumes de los artistas “Black Sabbath” o “Chico Buarque”.

```SQL
(SELECT p.playlist_id FROM playlist p)
EXCEPT
(SELECT pt.playlist_id
FROM playlist_track pt
    INNER JOIN track t
        ON pt.track_id = t.track_id
    INNER JOIN album al
        ON al.album_id = t.album_id
    INNER JOIN artist ar
        ON ar.artist_id = al.artist_id
WHERE ar.name = 'Black Sabbath' OR ar.name = 'Chico Buarque')
```

(b) Mediante SQL, AR y SQL obtener los clientes que compraron tracks de un único género.

```SQL
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
    INNER JOIN invoice i
        ON i.customer_id = c.customer_id
    INNER JOIN invoice_line il
        ON il.invoice_id = i.invoice_id
    INNER JOIN track t
        ON t.track_id = il.track_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING count(DISTINCT t.genre_id) = 1    
```

2.5. Considerando el siguiente esquema de una base de datos que guarda información sobre series:
ACTOR(idActor, nombreActor, edad)
SERIE(idSerie, nombreSerie, idgénero, añoInicio, añoFin)
género(idgénero, nombregénero)
CANAL(idCanal, nombreCanal)
PARTICIPA_EN(idActor, idSerie)
TRANSMITE(idCanal, idSerie)

Se pide en SQL:
(a) Listar los nombres de los actores mayores de 30 años que participan en la serie “Friends”.

```SQL
SELECT a.nombreActor
FROM Actor a
    INNER JOIN Participa_en p
        ON p.idActor = a.idActor
    INNER JOIN Serie s
        ON s.idSerie = p.idSerie
WHERE s.nombreSerie = 'Friends' AND a.edad > 30
```

(b) Listar los nombres de los canales que transmiten todas las series de comedia.

```SQL
WITH series_de_comedia AS (SELECT s.idSerie
    FROM Serie s
        INNER JOIN género g
            ON s.idgénero = g.idgénero
WHERE g.nombregénero = 'Comedia')

SELECT c.nombreCanal
FROM Canal c
    INNER JOIN Transmite t
        ON t.idCanal = c.idCanal
    INNER JOIN series_de_comedia s
        ON s.idSerie = t.idSerie
GROUP BY c.idCanal, c.nombreCanal
HAVING count(s.idSerie) = (SELECT count(ss.idSerie) FROM series_de_comedia ss)
```

(c) Listar los nombres de los actores mayores de 30 años que participan en la serie “Friends” y que además participaron alguna vez en series que comenzaron luego del año 2000.

```SQL
(SELECT a.nombreActor
 FROM Actor a
    INNER JOIN Participa_en p
        ON p.idActor = a.idActor
    INNER JOIN Serie s
        ON s.idSerie = p.idSerie
 WHERE s.nombreSerie = 'Friends' AND a.edad > 30)
INTERSECT
(SELECT a.nombreActor
 FROM Actor a
    INNER JOIN Participa_en p
        ON p.idActor = a.idActor
    INNER JOIN Serie s
        ON s.idSerie = p.idSerie
 WHERE s.añoInicio > 2000)
```

**Warning**:

- Al realizar operaciones de conjuntos asegurarnos de utilizar columnas que sean claves (o al menos, que incluyan una), sino podemos acabar matcheando dos entidades distintas pero con mismo valor para un atributo.

Corrección:

```SQL
(SELECT a.idActor, a.nombreActor
 FROM Actor a
    INNER JOIN Participa_en p
        ON p.idActor = a.idActor
    INNER JOIN Serie s
        ON s.idSerie = p.idSerie
 WHERE s.nombreSerie = 'Friends' AND a.edad > 30)
INTERSECT
(SELECT a.idActor, a.nombreActor
 FROM Actor a
    INNER JOIN Participa_en p
        ON p.idActor = a.idActor
    INNER JOIN Serie s
        ON s.idSerie = p.idSerie
 WHERE s.añoInicio > 2000)
```

(d) Listar los nombres de los actores mayores de 30 años que participan en la serie “Friends” y que además nunca participaron en series que comenzaron luego del año 2000.

```SQL
(SELECT a.idActor, a.nombreActor
 FROM Actor a
    INNER JOIN Participa_en p
        ON p.idActor = a.idActor
    INNER JOIN Serie s
        ON s.idSerie = p.idSerie
 WHERE s.nombreSerie = 'Friends' AND a.edad > 30)
EXCEPT
(SELECT a.idActor, a.nombreActor
 FROM Actor a
    INNER JOIN Participa_en p
        ON p.idActor = a.idActor
    INNER JOIN Serie s
        ON s.idSerie = p.idSerie
 WHERE s.añoInicio > 2000)
```

(e) Listar los ids de las series que comenzaron más recientemente.

```SQL
SELECT s.idSerie
FROM Serie s
WHERE s.añoInicio = (SELECT MAX(ss.añoInicio) FROM Serie ss)
```

**Warning**:

```SQL
SELECT s.idSerie
FROM Serie s
GROUP BY s.añoInicio
HAVING MAX(s.añoInicio)
```

- Esta es incorrecta porque solo podemos tener condiciones booleanas en cuerpo de cláusula `HAVING`.

(f) Listar los ids de los actores que participaron en al menos 2 series.

```SQL
SELECT a.idActor
FROM Actor a
    INNER JOIN Participa_en p
        ON a.idActor = p.idActor
GROUP BY a.idActor
HAVING count(DISTINCT p.idSerie) >= 2;
```

- De nuevo estamos usando un `INNER JOIN` que se podría ahorrar ya que el *idActor* también se encuentra en *Participa_en*.

Corrección:

```SQL
SELECT p.idActor
FROM Participa_en p
GROUP BY p.idActor
HAVING count(DISTINCT p.idSerie) >= 2;
```

(g) Suponiendo que puede haber nombres de serie repetidos, listar los nombres que hayan sido usados en dos o más series.

```SQL
SELECT s.nombreSerie
FROM Serie s
GROUP BY s.nombreSerie
HAVING count(s.idSerie) >= 2
```

(h) Considerando lo mismo del ejercicio anterior, listar todos los canales que trasmiten alguna serie que tiene el nombre repetido.

```SQL
WITH
series_con_nombre_repetido AS (
    SELECT s.nombreSerie
    FROM Serie s
    GROUP BY s.nombreSerie
    HAVING count(s.idSerie) >= 2)
SELECT c.idCanal, c.nombreCanal
FROM Canal c
    INNER JOIN Transmite t
        ON t.idCanal = c.idCanal
    INNER JOIN Serie s
        ON s.idSerie = t.idSerie
WHERE s.nombreSerie IN series_con_nombre_repetido
```

- Como un canal puede transmitir varias series con nombre repetido, entonces debemos asegurarnos de añadir `DISTINCT` al `SELECT`.
- No podemos usar el nombre de una CTE directamente en un `IN`, `ALL`, `EXISTS` o `ANY`, sino que debemos poner la consulta *in-place* y entre paréntesis o `(SELECT atributo FROM CTE_table)`.

Corrección:

```SQL
SELECT DISTINCT c.idCanal, c.nombreCanal
FROM Canal c
    INNER JOIN Transmite t
        ON t.idCanal = c.idCanal
    INNER JOIN Serie s
        ON s.idSerie = t.idSerie
WHERE s.nombreSerie IN (SELECT s.nombreSerie
    FROM Serie s
    GROUP BY s.nombreSerie
    HAVING count(s.idSerie) >= 2)
```

(i) Obtener la serie con el promedio de edad (de los actores) más alto.

```SQL
WITH
promedios_edad_por_serie AS (
SELECT s.idSerie, s.nombreSerie, AVG(a.edad) AS promedio
FROM Serie s
    INNER JOIN Participa_en p
        ON p.idSerie = s.idSerie
    INNER JOIN Actor a
        ON p.idActor = a.idActor
GROUP BY s.idSerie, s.nombreSerie)

SELECT s.idSerie, s.nombreSerie, p.promedio
FROM promedios_edad_por_serie p
WHERE p.promedio = (SELECT MAX(pp.promedio) FROM promedios_edad_por_serie pp)
```

(j) Obtener el género donde participa el actor más joven.

**Warning**:

```SQL
SELECT a.idActor, MAX(a.edad)
FROM Actor a
GROUP BY a.idActor
```

- Esto solo te retorna el máximo valor de edad para cada uno de los actores, lo cual no tiene mucha utilidad.
- Pensar agregaciones sobre `GROUP BY` como que armamos un *bucket* para cada valor posible del atributo por el que agrupamos. Ponemos ahí todas las tuplas que coincidan en ese valor. Luego aplicamos la función de agregación sobre cada *bucket*, pero no relacionamos los *buckets* de distinto grupo.

```SQL
WITH actor_mas_joven AS (
    SELECT a.idActor
    FROM Actor a
    WHERE a.edad = (SELECT MIN(aa.edad) FROM Actor aa))
SELECT g.idgénero, g.nombregénero
FROM actor_mas_joven a
    INNER JOIN Participa_en p
        ON p.idActor = a.idActor
    INNER JOIN Serie s
        ON s.idSerie = p.idSerie
    INNER JOIN género g
        ON g.idgénero = s.idgénero
```

2.6. Considerando el siguiente esquema de una base de datos con los partidos de fútbol de Primera A:
PARTIDO (equipo1, equipo2, torneo, goles1, goles2, puntos1, puntos2)
JUGADOR (nombre, edad, equipo)
 Cada partido se registra una sola vez. Por ejemplo si River le ganó a Boca en el torneo “Apertura 2002” por 2 a 1, se registra únicamente la tupla (“River”, “Boca”, “Apertura 2002”, 2, 1, 3, 0). Los candidatos a campeones de un torneo se determinan sumando los puntos obtenidos por cada equipo, seleccionando los que suman el máximo valor. Al haber más de un candidato, se resuelve el campeonato tomando en cuenta la diferencia de goles.
 Para simplificar se asume que ningún jugador cambió de equipo y los nombres no se repiten.
Se pide:

(a) Expresar en AR y SQL las siguientes consultas:
i. Listar los equipos que jugaron exactamente en dos torneos.

```SQL
WITH (equipos_por_torneo AS (SELECT p.equipo1 AS equipo, p.torneo FROM Partido p) UNION (SELECT p.equipo2 AS equipo, p.torneo FROM Partido p))

SELECT e.equipo
FROM equipos_por_torneo e
GROUP BY e.equipo
HAVING count(e.torneo) = 2 --No hace falta DISTINCT porque equipos_por_torneo no tiene tuplas repetidas, por lo que no aparecerá un mismo torneo varias veces para un mismo equipo.
```

ii. Listar el jugador más joven y el más viejo de cada uno de los equipos que finalizaron invictos (sin perder ningún partido) en al menos dos torneos – Las
tuplas del resultado son de la forma (equipo, nombre1, nombre2)

```SQL
WITH equipos_1_invictos_en_torneo AS (
    SELECT e.equipo, e.torneo
    FROM equipos_por_torneo e 
        INNER JOIN Partido p
            ON p.equipo_1 = e.equipo AND p.torneo = e.torneo
    GROUP BY e.equipo, e.torneo
    HAVING MIN(p.puntos1) > 0
), equipos_2_invictos_en_torneo AS (
    SELECT e.equipo, e.torneo
    FROM equipos_por_torneo e 
        INNER JOIN Partido p
            ON p.equipo_2 = e.equipo AND p.torneo = e.torneo
    GROUP BY e.equipo, e.torneo
    HAVING MIN(p.puntos2) > 0
), equipos_invictos_por_torneo AS (
    equipos_1_invictos_en_torneo INTERSECT equipos_2_invictos_en_torneo --Ya sea que haya jugado como local o como visitante debe estar invicto en ambas para estar invicto en el torneo. Estoy asumiendo que si estás en equipo_1 jugaste como local y que no podés jugar todos tus partidos como local en un torneo.
),
 equipos_invictos_en_al_menos_dos_torneos AS (
    SELECT e.equipo
    FROM equipos_invictos_por_torneo e
    GROUP BY e.equipo
    HAVING count(e.torneo) >= 2
),
 mas_viejo_por_equipo AS (
    SELECT j.nombre, j.equipo
    FROM Jugador j
    GROUP BY j.equipo, j.nombre
    HAVING MAX(j.edad) --ERROR: contenido de HAVING debe reducirse a bool
 ),
 mas_joven_por_equipo AS (
    SELECT j.nombre, j.equipo
    FROM Jugador j
    GROUP BY j.equipo, j.nombre
    HAVING MIN(j.edad) --ERROR: contenido de HAVING debe reducirse a bool. Además al agruparlos también por j.nombre cada bucket queda con un solo elemento, por lo que todos van a tener mínima y máxima edad en su bucket
)
SELECT e.equipo, v.nombre, j.nombre
FROM equipos_invictos_en_al_menos_dos_torneos e
    INNER JOIN mas_viejo_por_equipo v
        ON v.equipo = e.equipo
    INNER JOIN mas_joven_por_equipo j
        ON j.equipo = e.equipo
```

- Una alternativa sería restarle los que perdieron un partido.

```SQL
..., equipos_que_perdieron_en_torneo AS (
    (SELECT p.equipo_1 AS equipo, p.torneo FROM Partido p WHERE puntaje_1 = 0) UNION (SELECT p.equipo_2 AS equipo, p.torneo FROM Partido p WHERE puntaje_2 = 0)),
equipos_invictos_por_torneo AS (
    (SELECT p.equipo_1 AS equipo, p.torneo FROM Partido p) EXCEPT (SELECT p.equipo, p.torneo FROM equipos_que_perdieron_en_torneo p))...,
```

**Corrección:**

- Acá consideramos que un equipo puede jugar como visitante en un torneo y no como local para usar la BBDD que armó Gemini AI.

```SQL
WITH
	EQUIPOS_POR_TORNEO AS (
		(
			SELECT
				P.EQUIPO1 AS EQUIPO,
				P.TORNEO
			FROM
				PARTIDO P
		)
		UNION
		(
			SELECT
				P.EQUIPO2 AS EQUIPO,
				P.TORNEO
			FROM
				PARTIDO P
		)
	),
	EQUIPOS_1_INVICTOS_EN_TORNEO AS (
		SELECT
			E.EQUIPO,
			E.TORNEO
		FROM
			EQUIPOS_POR_TORNEO E
			INNER JOIN PARTIDO P ON P.EQUIPO1 = E.EQUIPO
			AND P.TORNEO = E.TORNEO
		GROUP BY
			E.EQUIPO,
			E.TORNEO
		HAVING
			MIN(P.PUNTOS1) > 0
	)
	,EQUIPOS_2_INVICTOS_EN_TORNEO AS (
		SELECT
			E.EQUIPO,
			E.TORNEO
		FROM
			EQUIPOS_POR_TORNEO E
			INNER JOIN PARTIDO P ON P.EQUIPO2 = E.EQUIPO
			AND P.TORNEO = E.TORNEO
		GROUP BY
			E.EQUIPO,
			E.TORNEO
		HAVING
			MIN(P.PUNTOS2) > 0
	)
	,EQUIPOS_INVICTOS_POR_TORNEO AS (
		(
			SELECT
				*
			FROM
				EQUIPOS_1_INVICTOS_EN_TORNEO
		)
		UNION -- Cambiamos el INTERSECT por el UNION ya que un equipo no necesariamente debe jugar como local y podría ser campeón invicto siempre siendo visitante
		(
			SELECT
				*
			FROM
				EQUIPOS_2_INVICTOS_EN_TORNEO
		)
	) --Ya sea que haya jugado como local o como visitante debe estar invicto en ambas para estar invicto en el torneo. Estoy asumiendo que si estás en equipo_1 jugaste como local y que no podés jugar todos tus partidos como local en un torneo.
, EQUIPOS_INVICTOS_EN_AL_MENOS_DOS_TORNEOS AS (
		SELECT
			E.EQUIPO
		FROM
			EQUIPOS_INVICTOS_POR_TORNEO E
		GROUP BY
			E.EQUIPO
		HAVING
			COUNT(E.TORNEO) >= 2
	),
	EDAD_MAS_VIEJO_POR_EQUIPO AS ( -- SOLUCIÓN: Ante problema del HAVING buscamos la edad máxima por equipo, para después quedarnos con el jugador de ese equipo con esa edad.
		SELECT
			J.EQUIPO,
			MAX(J.EDAD) AS EDAD
		FROM
			JUGADOR J
		GROUP BY
			J.EQUIPO
	)
	,MAS_VIEJO_POR_EQUIPO AS (
		SELECT
			J.NOMBRE, J.EQUIPO
			FROM JUGADOR J
				INNER JOIN EDAD_MAS_VIEJO_POR_EQUIPO E 
					ON E.EQUIPO = J.EQUIPO
			WHERE J.EDAD = E.EDAD
	)
	,EDAD_MAS_JOVEN_POR_EQUIPO AS (
		SELECT
			J.EQUIPO,
			MIN(J.EDAD) AS EDAD
		FROM
			JUGADOR J
		GROUP BY
			J.EQUIPO
)
, MAS_JOVEN_POR_EQUIPO AS (
		SELECT
			J.NOMBRE, J.EQUIPO
			FROM JUGADOR J
				INNER JOIN EDAD_MAS_JOVEN_POR_EQUIPO E 
					ON E.EQUIPO = J.EQUIPO
			WHERE J.EDAD = E.EDAD
)
SELECT
	E.EQUIPO,
	V.NOMBRE,
	J.NOMBRE
FROM
	EQUIPOS_INVICTOS_EN_AL_MENOS_DOS_TORNEOS E
	INNER JOIN MAS_VIEJO_POR_EQUIPO V ON V.EQUIPO = E.EQUIPO
	INNER JOIN MAS_JOVEN_POR_EQUIPO J ON J.EQUIPO = E.EQUIPO
```

(b) Dada la misma BD del ejercicio anterior pero ahora considerando que cada partido
se registra dos veces. Por ejemplo si River le ganó a Boca en el torneo “Apertura
2002” por 2 a 1, se registran dos tuplas
(“River, “Boca”, “Apertura 2002”, 2, 1, 3, 0)
(“Boca”, “River”, “Apertura 2002”, 1, 2, 0, 3)
Expresar en SQL las siguientes consultas:
i. Listar los equipos que hayan finalizado invictos en al menos dos torneos.

- Ahora para ver si es campeón invicto alcanza con ver que todas las tuplas que lo tienen como equipo1 de un torneo haya ganado o empatado.

```SQL
WITH equipos_invictos_en_torneo AS (
    SELECT e.equipo1, e.torneo
    FROM Partido_doble e
    GROUP BY e.equipo1, e.torneo
    HAVING MIN(e.puntos1) > 0
)
SELECT e.equipo1
FROM equipos_invictos_en_torneo e
GROUP BY e.equipo1
HAVING count(e.torneo) >= 2
```

ii. Listar los torneos que finalizaron con más de un candidato a campeón.

```SQL
WITH puntaje_de_equipo_por_torneo AS (
    SELECT p.equipo1, p.torneo, SUM(p.puntos1) AS puntaje
    FROM Partido_doble p
    GROUP BY p.equipo1, p.torneo
),
maximo_puntaje_por_torneo AS (
    SELECT p.torneo, MAX(p.puntaje) AS puntaje
    FROM puntaje_de_equipo_por_torneo p
    GROUP BY p.torneo
),
candidatos_a_campeon_por_torneo AS (SELECT p.torneo, p.equipo1
FROM puntaje_de_equipo_por_torneo p
    INNER JOIN maximo_puntaje_por_torneo m
        ON p.torneo = m.torneo
WHERE p.puntaje = m.puntaje)

SELECT c.torneo
FROM candidatos_a_campeon_por_torneo c
GROUP BY c.torneo
HAVING count(c.equipo1) > 1
```

2.7. Considerando el siguiente esquema de una base de datos
PERSONA(Nombre, género, Fecha_Nac, Nombre_Madre, Nombre_Padre),
MATRIMONIO(Nombre_1, Nombre_2, Fecha_Realización, Fecha Fin)
Se asume que dos personas pueden contraer matrimonio entre sí más de una vez.
Se pide:
(a) Listar en SQL las personas que hayan tenido algún hijo en su primer matrimonio.

- Asumo que `Nombre_1` es siempre el del marido y `Nombre_2` el de la mujer. Además de que con primer matrimonio se refiere al de la pareja y no de las personas, es decir que si A se casa con B y tiene un hijo, pero B se había casado antes con C y tuvo un hijo, ambos estarán como primogénitos cada matrimonio de B.

```SQL
WITH
primeros_matrimonios AS (
    SELECT M.Nombre_1, M.Nombre_2, MIN(M.Fecha_Realizacion) AS Fecha_Realizacion, MIN(M.Fecha_Fin) AS Fecha_Fin
    FROM MATRIMONIO M
    GROUP BY M.Nombre_1, M.Nombre_2
)
    SELECT PM.Nombre_1, PM.Nombre_2, PM.Fecha_Realizacion, PM.Fecha_Fin, P.Nombre, P.Fecha_nac
    FROM PERSONA P
        INNER JOIN primeros_matrimonios PM
            ON PM.Nombre_2 = P.Nombre_Madre AND PM.Nombre_1 = P.Nombre_Padre
	WHERE (P.Fecha_nac BETWEEN PM.Fecha_Realizacion AND PM.Fecha_Fin) OR (PM.Fecha_Fin IS NULL AND P.Fecha_nac AFTER PM.Fecha_Realizacion)
```

- Si se quisieran solo tener a los primogénitos de cada miembro de un primer matrimonio, entonces si A se casa con B, tienen un hijo D y B se casó antes con C y tuvieron un hijo E, entonces el primer hijo D será primogénito de A pero no de B, pero E lo será de B y de C.

```SQL
WITH 
  primer_matrimonio_marido AS (
    SELECT M.Nombre_1, MIN(M.Fecha_Realizacion) AS Fecha_Realizacion
    FROM MATRIMONIO M
    GROUP BY M.Nombre_1)
, primer_matrimonio_mujer AS (
    SELECT M.Nombre_2, MIN(M.Fecha_Realizacion) AS Fecha_Realizacion
    FROM MATRIMONIO M
    GROUP BY M.Nombre_2
)
, hijos_primer_matrimonio_marido AS (
    SELECT P.Nombre, M.Nombre_1, M.Fecha_Realizacion, M.Fecha_Fin
    FROM primer_matrimonio_marido PM
        INNER JOIN MATRIMONIO M
            ON M.Nombre_1 = PM.Nombre_1 AND M.Fecha_Realizacion = PM.Fecha_Realizacion
        INNER JOIN PERSONA P
            ON P.Nombre_padre = PM.Nombre_1
    WHERE
        (P.Fecha_Nac BETWEEN M.Fecha_Realizacion AND M.Fecha_Fin) 
        OR
        (P.Fecha_Nac >= M.Fecha_Realizacion AND M.Fecha_Fin IS NULL))
, hijos_primer_matrimonio_mujer AS (
    SELECT P.Nombre, M.Nombre_2, M.Fecha_Realizacion, M.Fecha_Fin
    FROM primer_matrimonio_mujer PM
        INNER JOIN MATRIMONIO M
            ON M.Nombre_2 = PM.Nombre_2 AND M.Fecha_Realizacion = PM.Fecha_Realizacion
        INNER JOIN PERSONA P
            ON P.Nombre_madre = PM.Nombre_2
    WHERE
        (P.Fecha_Nac BETWEEN M.Fecha_Realizacion AND M.Fecha_Fin) 
        OR
        (P.Fecha_Nac >= M.Fecha_Realizacion AND M.Fecha_Fin IS NULL))

(SELECT H.Nombre FROM hijos_primer_matrimonio_marido H)
UNION
(SELECT H.Nombre FROM hijos_primer_matrimonio_mujer H)
```

(b) Expresar en SQL la consulta que devuelve como resultado los nombres de los hijos extramatrimoniales.

```SQL
SELECT P.Nombre, P.Nombre_padre, P.Nombre_madre, P.Fecha_nac, M.Fecha_Realizacion, M.Fecha_fin
FROM PERSONA P
    LEFT OUTER JOIN MATRIMONIO M
        ON P.Nombre_padre = M.Nombre_1 AND P.Nombre_madre = M.Nombre_2
WHERE
	NOT (P.Fecha_nac BETWEEN M.Fecha_Realizacion AND M.Fecha_Fin) OR (P.Nombre_padre IS NULL AND P.Nombre_madre IS NULL)
```

```SQL
WITH
hijos_matrimoniales AS (
SELECT P.Nombre, P.Nombre_padre, P.Nombre_madre, P.Fecha_nac
FROM PERSONA P
    INNER JOIN MATRIMONIO M
        ON P.Nombre_padre = M.Nombre_1 AND P.Nombre_madre = M.Nombre_2
WHERE
	(P.Fecha_nac BETWEEN M.Fecha_Realizacion AND M.Fecha_Fin)
	OR
	(P.Fecha_nac >= M.Fecha_Realizacion AND M.Fecha_Fin IS NULL)
)
(SELECT P.Nombre, P.Nombre_padre, P.Nombre_madre, P.Fecha_nac
FROM PERSONA P)
EXCEPT
(SELECT * FROM hijos_matrimoniales)
```

- Ojo cuando querés hacer `JOINS` para traer agregarle más info de otra tabla a una fila, porque si hay más de uno que coincida con ella en los valores del `ON` en esa otra tabla, entonces te aparecerán tuplas duplicadas con la información original. Si no es lo que te pide el enunciado está mal.

(c) Expresar en SQL la consulta que devuelve como resultado los nombres de los primogénitos de cada matrimonio.

```SQL
WITH
hijos_de_matrimonio AS (
    SELECT P.Nombre, P.Nombre_padre, P.Nombre_madre
    FROM PERSONA P
        INNER JOIN MATRIMONIO M
            ON P.Nombre_madre = M.Nombre_2 AND P.Nombre_padre = M.Nombre_1
    WHERE (P.Fecha_nac BETWEEN M.Fecha_realizacion AND M.Fecha_fin) OR (M.Fecha_fin IS NULL AND P.Fecha_nac >= M.Fecha_realizacion)
)
, primogenito_de_matrimonio AS (
    SELECT H.Nombre_padre, H.Nombre_madre, MIN(P.Fecha_nac) AS Fecha_nac
    FROM hijos_de_matrimonio H
		INNER JOIN PERSONA P
			ON P.Nombre = H.Nombre
	GROUP BY H.Nombre_padre, H.Nombre_madre
)
SELECT * 
FROM PERSONA P 
    INNER JOIN primogenito_de_matrimonio PM 
        ON PM.Nombre_padre = P.Nombre_padre 
            AND PM.Nombre_madre = P.Nombre_madre 
            AND PM.Fecha_nac = P.Fecha_nac
```

2.8. Dados los siguientes esquemas de relación (donde la relación Amigo es simétrica.)
Miembro (<ins>nombrePersona</ins>,<ins>nombreGrupo</ins>)
Amigo (<ins>nombrePersona1</ins>,<ins>nombrePersona2</ins>)
Persona (<ins>nombrePersona</ins>, edad, género)
Grupo (<ins>nombreGrupo</ins>>, fechaInicio)
Se pide:
(a) Obtener, en SQL, para cada persona los grupos en los cuales el no es miembro pero
todos sus amigos si son miembros. La consulta debe devolver tuplas con (nombrePersona, nombreGrupo) donde nombreGrupo es el nombre del grupo que cumple con lo que se pide.

- Preguntaría si con simétrica se refieren a que si A es amigo de B entonces (A, B) y (B, A) se encuentran en la relación Amigo o si solo se encuentra una de las dos pero debemos considerar a A como amigo de B y a B como amigo de A. Asumiendo la primera nos quedaría así:

```SQL
WITH 
amigos_de_persona AS (
SELECT P.NombrePersona, A.NombrePersona1 AS NombreAmigo
FROM PERSONA P 
    INNER JOIN AMIGO A
        ON A.NombrePersona2 = P.NombrePersona
)
, cantidad_de_amigos_por_persona AS (
    SELECT A.NombrePersona, COUNT(DISTINCT A.NombreAmigo) AS CantidadAmigos
    FROM amigos_de_persona A
    GROUP BY A.NombrePersona
)
, cantidad_amigos_de_persona_por_grupo AS (
    SELECT A.NombrePersona, M.NombreGrupo, COUNT(DISTINCT A.NombreAmigo) AS CantidadAmigosEnGrupo
    FROM amigos_de_persona A
        INNER JOIN MIEMBRO M
            ON M.NombrePersona = A.NombreAmigo
    GROUP BY M.NombreGrupo, A.NombrePersona
)
, grupos_con_todos_sus_amigos AS (
    SELECT CAP.NombrePersona, CAG.NombreGrupo
    FROM cantidad_de_amigos_por_persona CAP
        INNER JOIN cantidad_amigos_de_persona_por_grupo CAG
            ON CAP.NombrePersona = CAG.NombrePersona
    WHERE CAP.CantidadAmigos = CAG.CantidadAmigosEnGrupo
)
, grupos_de_persona AS (
    (SELECT P.NombrePersona, M.NombreGrupo
    FROM MIEMBRO M
        INNER JOIN PERSONA P
            ON M.NombrePersona = P.NombrePersona)
)
(SELECT *
FROM grupos_con_todos_sus_amigos) 
EXCEPT 
(SELECT * FROM grupos_de_persona)
```

(b) Realizar en SQL una consulta que devuelva las personas que sólo tienen
amigos de género diferente y mayores de 18 años (ej si el género es masculino solo
tendría de género femenino mayores de 18 y viceversa)

```SQL
WITH
amigos_por_persona AS (
SELECT A.NombrePersona1, COUNT(DISTINCT P.NombrePersona) AS cantidad_amigos
FROM AMIGO A
	INNER JOIN PERSONA P
		ON A.NombrePersona2 = P.NombrePersona
GROUP BY A.NombrePersona1),
amigos_por_genero_de_cada_persona_y_mayores AS (
SELECT A.NombrePersona1, COUNT(P2.Genero) AS cantidad_amigos_otro_genero
FROM AMIGO A
	INNER JOIN PERSONA P1
		ON A.NombrePersona1 = P1.NombrePersona
	INNER JOIN PERSONA P2
		ON P2.NombrePersona = A.NombrePersona2
WHERE P2.Genero != P1.Genero AND P2.Edad > 18
GROUP BY A.NombrePersona1, P2.Genero
)
SELECT A1.NombrePersona1
FROM amigos_por_genero_de_cada_persona_y_mayores A1
	INNER JOIN amigos_por_persona A2
		ON A2.NombrePersona1 = A1.NombrePersona1
WHERE A1.cantidad_amigos_otro_genero = A2.cantidad_amigos
```

**Alternativa por complemento**: Bastaría obtener a todas las personas que tienen un amigo del mismo género o uno de edad menor o igual a 18.

```SQL
WITH 
personas_con_amigos_menores_a_18_o_del_mismo_genero AS (
SELECT A.NombrePersona1
FROM AMIGO A
    INNER JOIN PERSONA P1
        ON P1.NombrePersona = A.NombrePersona2
    INNER JOIN PERSONA P2
        ON P2.NombrePersona = A.NombrePersona1
WHERE P2.Genero = P1.Genero OR P2.Edad <= 18)

(SELECT P.NombrePersona FROM PERSONA P)
EXCEPT 
(SELECT P1 FROM personas_con_amigos_menores_a_18_o_del_mismo_genero P1)
```

(c) Realizar en SQL una consulta que devuelva las personas
para las que todos sus amigos son miembros de al menos un grupo con fecha de inicio
mayor al 1/12/2001.

- Yo lo interpreté como que todos sus amigos son miembros al mismo tiempo de un grupo con una fecha de inicio que cumpla la condición.

```SQL
WITH 
amigos_por_grupo AS (
    SELECT A.NombrePersona1, M.NombreGrupo, COUNT(DISTINCT A.NombrePersona2) AS amigos_en_grupo
    FROM Miembro M
        INNER JOIN Amigo A
            ON A.NombrePersona2 = M.NombrePersona
    GROUP BY A.NombrePersona1, M.NombreGrupo
),
cantidad_de_amigos AS (
    SELECT A.NombrePersona1, COUNT(DISTINCT A.NombrePersona2) AS cantidad_amigos
    FROM Amigo A
    GROUP BY A.NombrePersona1
),
grupos_con_todos_sus_amigos AS (
    SELECT AG.NombrePersona1, AG.NombreGrupo
    FROM amigos_por_grupo AG
        INNER JOIN cantidad_de_amigos CA
            ON CA.NombrePersona1 = AG.NombrePersona1
    WHERE CA.cantidad_amigos = AG.amigos_en_grupo
)
SELECT GA.NombrePersona1
FROM grupos_con_todos_sus_amigos GA
    INNER JOIN Grupo G
        ON G.NombreGrupo = GA.NombreGrupo
WHERE G.FechaInicio > '1/12/2001'::Date
```

- Si pedían que sean personas tal que todos sus amigos pertenezcan a un grupo que cumpla la condición, pero no necesariamente todos deben pertenecer al mismo grupo, entonces sería lo siguiente:

```SQL
WITH
miembros_de_grupos_despues_de_la_fecha AS (
    SELECT M.NombrePersona
    FROM Miembro M
    INNER JOIN Grupo G
        ON G.NombreGrupo = M.NombreGrupo
    WHERE G.FechaInicio::Date > '2001-12-01'::Date
)
SELECT DISTINCT A.nombrePersona1
FROM Amigo A
WHERE A.nombrePersona2 IN (SELECT M.NombrePersona FROM miembros_de_grupos_despues_de_la_fecha M)
```

2.9. En el siguiente esquema tenemos dos relaciones, una de ellas representa items con su
nombre y precio actual mientras la otra guarda información histórica. Cada vez que hay
una variación en el precio se guarda en la tabla histórica. Tomar en cuenta que los items
se guardan solamente cuando cambia el precio y no todos los días.
Historia (idItem, fecha guardado, precio)
Items (idItem, nombre, precio actual, categoríaID)

(a) Realizar en SQL: Una consulta que devuelva el precio histórico promedio de los items
de categoríaID=1 al 1/7/1999
Nota: no usar SELECT en el FROM, vistas ni tablas auxiliares.

- Entendí que se refería al promedio del precio histórico de los items hasta esa fecha.

```SQL
SELECT AVG(H.Precio) AS precioPromedio
FROM Historia H
    INNER JOIN Items I
        ON I.idItem = H.idItem
GROUP BY I.categoriaID
HAVING I.categoriaID = 1 AND H.FechaGuardado <= '1999-07-01'::Date
```

Corrección:

- Te interesa saber el precio de cada item de esa categoría, no el promedio de todos los items de ella. Por eso hay que agrupar por `idItem` en vez de por `categoriaID`.
- Al comparar fechas tener en cuenta el formato de estas, ya que si no coinciden en formato tendremos errores.
- **No podés tener nada en el `HAVING` que no esté en el `GROUP BY`, en este caso `H.FechaGuardado` no debería estar.

Versión 1:

```SQL
SELECT I.idItem, AVG(H.Precio) AS precioPromedio
FROM Historia H
    INNER JOIN Items I
        ON I.idItem = H.idItem
WHERE H.Fecha_guardado <= '1999-07-01'::Date
GROUP BY I.idItem
HAVING I.categoriaID = 1 
```

Versión 2:

```SQL
SELECT I.idItem, AVG(H.Precio)
FROM Historia H
    INNER JOIN Items I
        ON I.idItem = H.idItem
WHERE H.Fecha_guardado <= '1999-07-01' AND I.CategoriaID = 1
GROUP BY I.idItem
```

- Si te pedían que devuelvas el promedio histórico entre todos los items de la categoría hasta esa fecha, entonces sería:

```SQL
SELECT I.categoriaID, AVG(H.Precio)
FROM Historia H
    INNER JOIN Items I
        ON I.idItem = H.idItem
WHERE I.categoriaID = 1 AND H.Fecha_guardado::Date <= '1999-07-01'::Date
GROUP BY I.categoriaID
```

(b) Escribir en SQL una consulta que devuelva los nombres de los items
que no tengan precio histórico guardado.

```SQL
SELECT I.Nombre, I.idItem
FROM Items I
WHERE I.idItem != ALL(SELECT H.idItem FROM Historia H) 
```

**Alternativa por complemento**:

```SQL
WITH sin_historia AS (
(SELECT I.idItem FROM Items I)
EXCEPT 
(SELECT H.IdItem FROM Historia H)
)
SELECT * FROM Items I WHERE I.idItem IN (SELECT * FROM sin_historia)
```

**Alternativa con `NOT IN`:**
```SQL
WITH sin_historia AS (
(SELECT I.idItem FROM Items I)
EXCEPT 
(SELECT H.IdItem FROM Historia H)
)
SELECT * FROM Items I WHERE I.idItem IN (SELECT * FROM sin_historia)
```

(c) Escribir en SQL una consulta que devuelva el ítem con mayor precio actual junto al
mayor precio histórico del mismo ítem.

```SQL
SELECT I.idItem, I.Precio_actual, MAX(H.Precio)
FROM Items I
    INNER JOIN Historia H
        ON H.idItem = I.idItem
WHERE I.Precio_actual = (SELECT MAX(I2.Precio_actual) FROM Items I2)
GROUP BY I.idItem, I.Precio_actual
```

- Rompe si hay un item nuevo, sin historia, con precio máximo.

Corrección:

```SQL
SELECT I.idItem, I.Precio_actual, MAX(H.Precio)
FROM Items I
    LEFT OUTER JOIN Historia H
        ON H.idItem = I.idItem
WHERE I.Precio_actual = (SELECT MAX(I2.Precio_actual) FROM Items I2)
GROUP BY I.idItem, I.Precio_actual
```
