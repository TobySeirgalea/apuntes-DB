# Database security

Fuentes:

- Fundamentals of Database Systems, Ramez Elmasri & Shamkant Navathe, chapter 24.
- Databases complete book, David Ullman (pendiente).

## Amenazas para las bases de datos

- **Pérdida de integridad**: Se pierde si cambios no autorizados son hechos a los datos, ya sea intencionalmente o no. Los cambios pueden ser:
  - Modificación.
  - Borrado.
  - Inserción.
  - Creación.
- **Pérdida de disponibilidad**: Se pierde si no se permite el acceso a quién tiene legítimo derecho a accederlos.
- **Pérdida de confidencialidad**: Se pierde si se permite el acceso a datos por parte de usuarios no autorizados.

## Medidas de control para prevenirlos

- [**Access control**](#access-control): Trata sobre restringir el acceso al sistema de base de datos.
- [**Inference control**](#inference-control): Trata sobre evitar que información sobre individuos sea accedida o pueda ser inferida a través de queries específicas. Más relacionado a bases de datos estadísticas.
- [**Flow control**](#flow-control): Trata sobre evitar que el flujo de circulación de la información pueda alcanzar a usuarios no autorizados. Un canal de información que permite esto es llamado *covert channel/canal encubierto*.
- [**Data encryption**](#data-encryption): Trata sobre encriptar la información que es transmitida por una red de comunicaciones. Al encriptarla la idea es que si es interceptada sea difícil decodificar la información transmitida sin información extra que sólo brindamos al receptor autorizado.

### Access control

El *administrador de la base de datos*(**DBA**) es la autoridad central en el maneja de esta. Por eso tiene acceso a comandos específicos como:

- **Creación de usuarios**: Puede crear cuentas con contraseñas y permitir a grupo de usuarios acceder al **DBMS**.
- **Otorgamiento de privilegios**:
  - Mediante `GRANT`.
  - Es parte de la [autorización discrecional de la **DB**](#mecanismos-de-seguridad-discrecionales).
- **Revocamiento de privilegios**:
  - Mediante `REVOKE` puede revocar privilegios previamente otorgados.
  - Es parte de la [autorización discrecional de la **DB**](#mecanismos-de-seguridad-discrecionales).
- **Asignación de niveles de seguridad**:
  - Asignar a cuentas de usuarios distintos *niveles de seguridad*.
  - Es parte de la [autorización obligatoria de la **DB**](#mecanismos-de-seguridad-obligatorios).

Cuando una persona o grupo quiere acceder al sistema de la base de datos, este se debe contactar con **DBA**, el cual le crea una cuenta con:

- Usuario.
- Contraseña.

Las tareas del **DBMS** incluyen:

- Almacenar usuarios con sus contraseñas y permitir borrarlos.
- Chequear que en cada intento de login estos coincidan con los proporcionados por usuario.
- Llevar registro de todas las operaciones realizadas durante una sesión por un usuario.
  - Se puede realizar añadiendo al *system log* el nombre de usuario y dispositivo desde el que se conectó.
  - Es utilizado para poder realizar *auditorías* a la **DB** y determinar qué usuario intentó realizar algo indebido. Dichos *logs* son llamados *audit trails*.

#### Sensibilidad de la información

- La *sensibilidad de un dato* es una medida de importancia asignada a este por su dueño.
- Podemos usar [mecanismos de control de *access control*](#access-control) para prevenir su acceso.
- Es responsabilidad de **DBA** y *security administrator* determinar:
  - ¿Qué accesos deben ser permitidos a ciertos atributos/columnas de la base de datos o a datos individuales de esta?.
  - ¿Por cuáles categorias de usuarios?.

##### ¿Cuándo un dato pasa a ser sensible?

- *Es inherentemente sensible*: Información sobre salarios o enfermedades.
- *Proviene de una fuente sensible*: La fuente puede indicarlo como sensible.
- *Es declarado sensible*: El dueño del datos lo declara como sensible.
- *Es de un atributo o registro declarado como sensible*: Proviene de un campo de información sensible.
- *Es sensible en relación a datos previamente divulgados*: No es sensible por si mismo, pero sí en relación con otros datos previamente registrados.

##### Factores a tener en cuenta para decidir si es seguro o no revelar un dato

- **Disponibilidad del dato**: No permitir acceso al dato mientras está siendo modificado.
- **Aceptabilidad del acceso al dato**: Denegar acceso a datos por usuarios no autorizados, aunque no acceda a datos sensible porque una solicitud de un usuario no autorizado igualmente puede revelar información sobre los datos sensibles.
- **Garantía de autenticidad**: Tener en cuenta características externas que afectan la autenticidad del acceso, por ejemplo si está intentando acceder fuera del horario laboral. También que las acciones previamente realizadas no puedan combinarse con otras para acabar revelando información sensible.

*Lo ideal es mantener perfecta seguridad con máxima precisión*. Donde:

- **Seguridad**:
  - Mantener datos seguros de ser corrompidos.
  - Acceso a estos adecuadamente controlado.
  - Revelar solo información no sensible.
  - Rechazar toda referencia a información sensible.
- **Precisión**:
  - Proteger toda información sensible.
  - Revelar tanta información no sensible como sea posible.

#### Relación entre seguridad y privacidad

- **Seguridad**:
  - Relacionado al *acceso* a la información.
  - Mecanismos implementados proteger dichos accesos.
  - Es un pilar necesario para la *privacidad*.
- **Privacidad**:
  - Relacionado al *uso apropiado* de la información.
  - Analiza qué tan bien aproxima el uso de la información adquirida por el sistema a las suposiciones explícitas e implícitas de dicho uso.
  - De POV usuario *privacidad* puede ser considerada de dos perpectivas distintas:
    - Prevenir almacenamiento de la información personal.
    - Asegurar uso apropiado de la información personal.
  - Capacidad de personas de controlar los términos en qué su información personal es adquirida y utilizada.

### Inference control

### Flow control

- Regula flujo de información entre objetos, buscando evitar que información de un objeto llegue a otro menos protegido. Un ejemplo de flujo es leer de un objeto $X$ y escribirlo en otro $Y$.
- Una **flow policy** especifica los canales sobre los que la información puede circular. Por ejemplo no permitir flujo de *Confidencial* a *Nonconfidential*.
- Se lo puede implementar extendiendo el mecanismo de *access control* añadiendo clases de seguridad y no permitiendo flujo de objetos de clase más restrictiva a menos.
- Lo *flujos de información* pueden ser:
  - **Implícitos**: Generados por expresiones condicionales.
  - **Explícitos**: Generados por asignaciones directas.
- Mecanismo de control debe asegurar que solo los autorizados se ejecutan.
- Suelen ser implementados diferenciando objetos con *labels* que indican *clase de seguridad* y con reglas sobre cuándo se puede realizar una transferencia entre clases distintas.

#### Covert channel

Canal de información que viola restricciones de seguridad permitiendo flujo de un nivel más alto a uno inferior.

Aunque por *star-property* no se pueda escribir de un archivo de clase de seguridad superior a uno inferior, si estos establecen entre sí un canal de comunicación pueden transmitirse información evitando esos chequeos. Por ejemplo si *U* y *S* se ponen de acuerdo en un programa donde *U"intenta escribir en *S* y recibe un 1 si no puede y un 0 si está permitido. *S* podría usar estos bits de respuesta para enviar su dato a *U* que realiza múltiples consultas y va almacenando los bits de respuesta hasta reconstruir el dato. Este es un canal implícito.

Se pueden clasificar entre:

- **Timing channels**: Información transmitida por *timing* de eventos o procesos. Si una respuesta tarda X tiempo es un 1, sino es un 0. Así con consultas *U* puede recibir el dato que le transmite *S*.
- **Storage channels**: No requiere sincronización temporal. La información se transmite mediante el acceso a la información del sistema de almacenamiento. Por ejemplo *S* crea un archivo para representar un 1 y lo borra para representar un 0. *U* consulta repetidas veces por ese archivo. *S* puede transmitirle un dato a *U* si se coordinan.

Algunos expertos en seguridad creen que evitar que los programadores ganen acceso a datos sensibles del programa cuando ya está en uso regular evitaría estos canales.

### Data encryption

#### Definiciones

- *Encryption*:
  - Convertir datos en *ciphertext* que no pueda ser entendido por personal no autorizado.
  - Aplica *encryption algorithm* a datos usando *encryption key* que debe ser desencriptada con una *decryption key* para recuperar los datos originales.
- *Ciphertext*: Texto encriptado.
- *Plaintext*: Texto con datos intelegibles.
- *Decryption*: Desencriptar.

#### Algoritmos simétricos

- Única clave usada para encriptar y desencriptar.
- Llamado *secret key algorithms* o *content-encryption algorithms*.
- Desventaja: Transmitir la *secret key* de forma segura. Opciones:
  - Derivarla de una contraseña aplicando misma función a string en *sender* y *receiver* (*password-based encryption algorithm*).
- Fortaleza de la clave depende de su tamaño.

#### Algoritmos ansimétricos/public

- Se basa en funciones matemáticas en vez de operaciones y *bit patterns*.
- Se usan dos claves para encriptar y desencriptar.
  - Una **pública** que puede ser transmitida de forma no segura.
  - Una **privada** que no se transmite y es muy difícil de derivar a partir de la pública.
- Funcionamiento:
  - Cada usuario genera un par de claves para usar en encriptación y desencriptación de los mensajes.
  - Cada usuario ubica una de ellas (*public key*) en un registro público u otro archivo accesible. La otra se mantiene *privada*.
  - Si *sender* quiere enviar mensaje privado al receptor, *sender* encripta con la clave pública del receptor.
  - El receptor lo desencripta con su clave privada.

#### Firmas digitales

- Forma asociar marca a un texto.
- La marca debe ser inadulterable.
- Los demás deben poder distiguir si es apócrifa.
- Son diferentes por cada uso. Se logra haciéndolas depender del objeto firmado con un *timestamp*. También debe depender de un número secreto que es unico para el firmador.
- Verificación de firma no debe depender de ningún número secreto.

#### Certificados digitales

- Combinar valor de *public key* con identidad de la persona que tiene la *private key* en un *digital signed statement*.
- *Certification Authority* verifica los certificados.

- Dueño del certificado identificado con un ID incluye su información.
- Incluye su *public key*.
- Incluye fecha emisión certificado.
- Incluye periodo de validez.
- Incluye su ID.
- Lo envía al **CA** (*certification authority*).

## Seguridad de la base de datos y subsistema de autorización

### Mecanismos de seguridad discrecionales

#### Tipos de privilegios en un sistema de DB

- **Account level**: El **DBA** especifica privilegios particulares para cada cuenta. Entre estos se encuentran:
  - `CREATE SCHEMA`: Privilegio para crear esquema o relación base.
  - `CREATE VIEW`: Privilegio para crear vistas.
  - `ALTER`: Privilegio para modificar relaciones (agregar columnas o removerlas).
  - `MODIFY`: Privilegio para `INSERT`, `DELETE`, `UPDATE` sobre tuplas de cualquier relación.
  - `SELECT`: Privilegio para obtener información de cualquier relación vía *select queries*.

- **Relation/table level**: El **DBA** especifica privilegios particulares sobre cada relación o vista de la **DB**.
  - Pueden aplicarse sobre relaciones/tablas o vistas.
  - Se especifica para cada usuario qué acciones puede realizar sobre qué relaciones/tablas o vistas.
  - Se utiliza el método de autorización de *access matrix model* donde en una matriz cada fila representa un sujeto (usuario/cuenta/programa) y cada columna un objeto (relaciones, columnas, registros, vistas, operaciones) y en las celdas se encuentran los tipos de privilegios (read, write, update).
  - Cada relación tiene una **owner account**, que generalmente es la que la creó y *tiene todos los privilegios*, en **PostgreSQL** podemos especificar la **owner account** al crear el esquema.
  - El otorgamiento (`GRANT`) y revocamiento (`REVOKE`) de permisos corresponde a la **owner account**.
  - Entre los privilegios que puede otorgar la **owner account** se encuentran:
    - **SELECT privilege**: Permite aplicar `SELECT` sobre la relación.
      - Para crear una *vista* se debe tener este privilegio sobre todas las relaciones de esta.
      - Podemos usar *vistas* para permitirle a una cuenta privilegios sobre solo unos atributos de una relación o solo unas tuplas.
    - **Modification privileges**: Incluye tres privilegios:
      - `DELETE`.
      - `UPDATE`, podemos especificar solo algunos atributos si queremos.
      - `INSERT`, podemos especificar solo algunos atributos si queremos.
    - **References privilege**: Permite a la cuenta referenciar a la relación al definir *integrity constraints*.

Si queremos especificar atributos sobre los que se pueda realizar `SELECT` o `DELETE` podemos crear una *vista* con solo esos atributos y otorgar permisos de `SELECT` o `DELETE` completos sobre esa *vista*.

#### Propagación de privilegios

- Los privilegios pueden ser otorgados con la opción `GRANT OPTION` o sin ella.
- En caso de tenerla, pueden otorgar ese mismo privielgio, sobre la relación que lo recibieron, a cualquier otra cuenta.
- Esto permite encadenar cesión de privilegios.
- La **owner account** no sabe hasta qué cuentas se propagó el privilegio.
- En caso de que alguno de la cadena reciba un `REVOKE` sobre ese privilegio y relación, entonces todos aquellos a los que este se los cedió reciben el `REVOKE` en *cascada* por parte del **DBMS**.
- **DBMS** debe llevar registro de todos  privilegios otorgados y de dónde provienen
- Una cuenta puede tener un mismo privilegio otorgado por más de una cuenta. No perderá dicho privilegio a menos que todas las que se lo otorgaron reciban `REVOKE`.

##### Limitando la propagación

Estas técnicas no están implementadas por todas los **DBMS** y no son parte del *standar **SQL***.

- Limitar *propagación horizontal*: Se puede especificar un número $i$ de cuentas a las que la cuenta receptora del privilegio se lo puede compartir y solo se lo puede compartir a cuentas con un $i$ menor.
- Limitar *propagación vertical*: Cada cuenta tiene un número de profundidad de cada privilegio recibido $j$. Si $j=0$, entonces no tiene privilegio. Si $j>0$, entonces solo puede compartirle el privilegio a otra con un $j$ menor al suyo.

### Mecanismos de seguridad obligatorios

- Permite clasificar usuarios y datos en clases de seguridad.
- Normalmente se combina con los [mecanismos discrecionales](#mecanismos-de-seguridad-discrecionales).
- No todos los **DBMS** lo proveen.
- Las clases de seguridad típicas son:
  - *Top Secret(TS)*:
  - *Secret(S)*:
  - *Confidencial(C)*:
  - *Unclassified(U)*:
  - Cumplen que *TS* $>=$ *S* $>=$ *C* $>=$ *U*.
- Las restricciones de acceso a datos son:
  - **Simple security property**: Ningún *sujeto*(usuario, cuenta, programa) $S$ puede leer un *objeto*(relación, tupla, columna, vista, operación) $O$ a menos que *class*($S$) $>=$ *class*($O$).
  - **Star property**: Ningún *sujeto* $S$ puede escribir un *objeto* $O$ a menos que *class*($S$) $<=$ *class*($O$). Sino podríamos leer y copiar el contenido de una clase superior $S$ a otra inferior $O$ y ser leído por todos los de la misma clase que $O$ cuando originalmente no se podía.
- Se consideran a los *atributos* y a las *tuplas* como *data objects* permitiéndoles tener una *clase de seguridad*.
- Una relación en este esquema *multinivel* con $n$ *atributos* se representa como $R(A_{1}, C_{1}, A_{2}, C_{2}, ..., A_{n}, C_{n}, TC)$ donde cada $A_{i}$ es un *atributo*, cada $C_{i}$ su *clase de seguridad* y $TC$ es la mayor *clase de seguridad* entre las de los $C_{i}$ de la *tupla*.
- La *primary key* se conoce como *apparent key*.

#### Filtering

*Filtering* ocurre cuando declaramos una tupla en un nivel superior y evitamos almacenarla en las de nivel inferior.

#### *Polyinstantiation*

Ocurre cuando múltiples tuplas tienen la misma *apparent key* pero distintos valores para los otros atributos para usuarios de distintos *niveles de seguridad*. Si un usuario de nivel inferior quiere escribir un atributo pero ese atributo tiene un valor distinto en un nivel superior lo dejamos escribirlo en su nivel.

#### Reglas de integridad

- *Entity integrity rule*:
  - *Todos los atributos que son miembros de una apparent key no deben ser null y deben tener la misma clase de seguridad en cada tupla individual*.
  - *Todos los demás atributos de la tupla deben tener una clase de seguridad mayor o igual que la de la apparent key*.
  $therefore$ el usuario puede ver la *apparent key"si puede ver cualquier atributo de la tupla.
- *Null integrity rule*: ...
- *Interinstance integrity*: Si un valor de una tupla puede ser *filtrado* (derivado) de un nivel superior, entonces basta solo almacenarla en ese nivel superior.
- El sistema no puede rechazar intentos de sobreescritura de datos de niveles superiores por parte de inferiores ya que eso les permite inferir que ese atributo tiene un valor no nulo en nivel superior y sería permitir *covert channel**.

| *Discretionary access control* | *Mandatory access control* |
| ------------------------------ | -------------------------- |
|  Más flexible   |  Más rígido, requiere clasificación estricta en *clases de seguridad*     |
|  No controla como se propaga la información una vez se accede por un usuario autorizado. Por lo tanto propenso a *Trojan horses*   |  Previene flujo ilegal de la información    |
|     |      |

#### Role based access control

- Asociar permisos y privilegios a roles que se asignan a usuarios en vez de a usuarios directamente.
- Los roles se pueden crear con `CREATE ROLE` y destruir con `DESTROY ROLE`.
- Se les puede asignar privilegios con `GRANT` y revocarlos con `REVOKE`.
- Algunas **DBMS** requieren que los roles sean **mutuamente exclusivos**. Esta puede ser de dos tipos:
  - *authorization time exclusion* (static): Dos roles mutuamente exclusivos no pueden ser parte de la autorización de un usuario al mismo tiempo.
  - *runtime exclusion* (dynamic): Puede ser asignados al mismo usuario pero no pueden ser activados al mismo tiempo.
- Otros usan parcialmente exclusivos o completamente exclusivos.
- La autenticación de los usuarios de las personas y la gestión de su acceso a información confidencial es tarea del *identity management*.

##### Jerarquías de roles

- Son ordenes parciales. Tener un rol te da también los inferiores en jerarquía.

#### Row level access control

- Se asigna un *label* a cada fila que almacena información sobre la sensibilidad de sus datos.
- Los usuarios también tiene un nivel de sensibilidad de datos que pueden acceder/manipular.
- Los *labels* evitan acceso y modificación de datos de un usuario con un nivel de sensibilidad mayor al de la fila.
- Se define una **Label Security Policy** que cubre a ciertos datos.
  - Esta contempla penalidades y medidas de respuesta.
  - Las diseñan managers y gente de RRHH.
  - Las interpreta y convierte en *labels* el **Label Security Administrator**, que también define *labels* con sensibilidad de cada fila de datos y usuarios.
- Se aplica sobre los [mecanismos de seguridad discrecionales](#mecanismos-de-seguridad-discrecionales), una vez estos permiten el acceso se realiza el chequeo de *labels*.

#### XML access control

- La sintáxis de firmas **XML** y las especificaciones de procesamiento describen una sintáxis **XML** para asociar ***XML** docs* con firmas criptográficas.
- También definen procedimientos para verificarlas y mecanismos de *countersigning* (agregar otra firma) y transformaciones llamados *canonizaciones* para garantizar que dos documentos produzcan mismo  ontenido para firma aunque varien un poco.
- Solo partes especiíficas del ***XML** tree* pueden ser firmadas.
- El contenido encriptado y la información adicional se representan en **XML** y puede ser procesado con herramientas para **XML**.

#### Access control policies en web e-commerce

- Se debe proteger no solo datos sino conocimiento y experiencia.
- Mecanismo de *access control* debe soportar proteger objetos variados.
- Deben soportar ***Content-based access control***: Las políticas de *access control* tienen en cuenta al objeto protegido.
- Las políticas de *access control* deben realizarse en base a características y cualificaciones del usuario en vez de datos individuales de este. Por ejemplo apoyarse en el uso de *credenciales* que aportan solo propiedades relevantes para propósitos de seguridad, en vez de IDs.

## Ataques a bases de datos

Algunos de los más frecuentes son:

- **Escalado de privilegios no autorizado**: Explotando una vulnerabilidad, un usuario intenta aumentar sus privilegios.
- **Abuso de privilegios**: Un usuario con privilegios otorgados se rebela realiza un ataque.
- **Denial of Service**: Ataque que intenta evitar acceso a recursos por parte de otros usuarios.
- **Weak authentication**: Si el esquema de autenticación es débil, un usuario puede tomar la identidad de uno legítimo y obtener sus credenciales para acceder al sistema.
- [**SQL injection**](#sql-injection).

### SQL Injection

Consiste en inyectar vía input un string que cambie o manipule un *SQL statement* para afectar a la **DB**. Algunos tipos de este ataque son:

- **SQL Manipulation**: Modifica un comando **SQL** de la aplicación.
- **Code injection**: Añade comandos **SQL** adicionales.
- **Function call injection**: Se añade una función propia de la **DB** o *syscall* del **SO** como input aprovechando que no se lo sanitiza. Así motor de **DB** o **SO** lo ejecuta. Por ejemplo en un `TRANSLATE` poner un llamado a una URL que al ser llamada retorna el código malicioso, conseguimos ponerlo dentro del dato que será enviado al servidor.

#### Riesgos

Algunos incluyen:

- **Database Fingerprinting**: Averiguar tipo de **DBMS** utilizado y usar ataques específicos para él.
- **Denial of Service**: Inundar servidor con request evitando acceso de usuarios o borrar infomación.
- **Bypassing authentication**: Ganar acceso a la **DB** como usuario autorizado y hacer lo que quiera.
- **Identificar parámetros inyectables**: Conseguir información sobre el tipo y estructura del backend de la app. Usualmente porque error's page son muy descriptivas.
- **Ejecutar comandos remotos**: Ejecutar los comandos que quiera en la **DB**.
- **Realizar escalado de privilegios**.

#### Técnicas de protección

Algunas incluyen:

- **Bind variables (*parameterized statements*)**: En vez de poner directo el input del usuario en la query poner parámetros y luego reemplazarlos con funciones específicas para reemplazarlos por los valores del usuario hechos strings. Así input de usuario no es parte de la query sino que se lo trata como texto.
- **Filtering input (*input validation*)**: Remover *escape characters* del input. Si te comés de sacar alguno quedás expuesto.
- **Function security**: Limitar las funciones de la base de datos, tanto estándar como personalizadas.

### Supervivencia de la información

Un **DBMS** debe:

- Realizar máximo esfuerzo por prevenir ataques.
- Detecar los ataques.
- *Confinamiento*: Eliminar acceso del atacante al sistema y asilar el problema para que no se expanda.
- *Reporte de daños*: Determinar el alcance del ataque, incluyendo funciones falladas y datos corrompidos.
- *Reconfiguración*: Realizar reconfiguración para permitir continuar operaciones en modo degradado mientras se realizan las tareas de recuperación.
- *Repair*: Recuperar datos corruptos o perdidos, reparar daños en sistema para recuperar funcionamiento normal.
- *Fault treatement*: Identificar debilidades explotadas en ataque y tomar acciones para prevenir futuro ocurrencia.