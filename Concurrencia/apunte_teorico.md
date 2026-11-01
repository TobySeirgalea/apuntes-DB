## Paradigma pesimista (*locking*)

### **Lectura entre transacciones**

Dadas dos transacciones $T_i$ y $T_j$ decimos que $T_i$ lee $X$ de $T_j$ si $T_i$ lee $X$ y $T_j$ fue la última transacción que escribió $X$ y no abortó antes de que $T_i$ lo leyera. i.e.

$$\begin{cases} w_j(X) < r_i(X) \iff T_j  ~escribió~antes~el~elemento~que~lee~T_i \\ a_j \nless r_i(X) \iff T_j~no~abortó \\ (Si~existe~ w_k(X) / w_j(X) \lt w_k(X) \lt r_i(X) \implies a_k \lt r_i(X)) \iff T_j ~es~la~última ~que~escribió~ X ~y~no~abortó \end{cases}$$

### Clasificación de las historias

**Definiciones:**

- *Historia recuperable* (**RC**): Si toda transacción $T_i$ que leyó de $T_j$ y commiteó, entonces $T_j$ commiteó antes. Es decir **solo commitea después de que todas de las que leyó lo hicieron**.
- *Historia avoid cascading abort* (**ACA**): Siempre que una transacción $T_i$ lee de $T_j$, $T_j$ commiteó antes de la lectura. Es decir **solo leo de las que ya commitearon**.
- *Historia strict* (**ST**): Una transacción **solo puede leer o escribir un item si la última que lo escribió ya commiteó o abortó**.

### Schedules rigurosos (**RG**)

Un *schedule* $S$ es riguroso $\iff$ es **ST** y al momento de cada escritura de un item todos sus lectores previos a ella (de otras transacciones) ya abortaron o commitearon.

**Propiedades**:
    - RG $\subset$ SR.
    - RG $\subset$ ST $\subset$ ACA $\subset$ RC.

### **Teorema de la recuperabilidad:**

ST $\subset$ ACA $\subset$ RC

### **Definición de serializabilidad (*SR*)**

Una historia es *serializable* si es conflicto equivalente a una historia serial.

### Anomalías

#### *Dirty reads*

Ocurre cuando se le permite a una transacción leer un item de que ha sido modificado por una transacción que aún no ha sido commiteada.

Patrón: $w_1(X);\dots;r_2(X);\dots;(c_1 or a_1)$ [1]

>[!IMPORTANT]
> **Consultar**: El hecho de leer de una que aún no ha sido commiteada es *dirty read*, aunque no aborte o mi transacción aborte en cascada ¿sigue siendo *dirty read*? RTA: Es un potencial dirty read que si aborta se concreta.

#### *Lost updates*

Lost Update: Ocurre cuando una transacción $T_1$ lee un item y luego $T_2$ lo escribe (posiblemente basado en una lectura previa), luego $T_1$, basado en su valor leído actualiza el item y commitea. [1]

Patrón: $r_1(x);\dots;w_2(x);\dots;w_1(x);\dots;c_1$ (Lost Update) [1]

>[!IMPORTANT]
>**Consultar**: ¿Es la única forma en que puede ocurrir *lost update*?¿*dirty write* ($w_1(X);\dots;w_2(X)$) es considerado *lost update*? RTA: Si. ¿En el patrón da igual si $T_2$ commiteó o no? Sí, el valor de $T_2$ lo pisó $T_1$. Necesitaría multiversión.

#### *Phantom reads*

Distintas lecturas de un item en una transacción dan resultados distintos porque entre lecturas fue modificado por otra transacción.

### Control de concurrencia

#### Esquema lock binario

- $l_i(A)$: Transacción $i$ realiza *lock* sobre item $A$.
- $u_i(A)$: Transacción $i$ libera *lock* sobre item $A$.

#### Historias legales

- $T_i$ solo puede leer o escribir item $A$ si antes realizó *lock* sobre $A$ y aún no lo liberó.
- Si $T_i$ realiza *lock* sobre un elemento debe liberarlo posteriormente.
- Si $T_i$ desea obtener *lock* sobre elemento lockeado por otra $T_j$, debe esperar a que esta lo libere.

#### Grafo precedencia lock binario

- Un nodo por cada $T_i$ de $H$ historia legal.
- $T_i \xrightarrow{A} T_j$ si $T_i$ realiza $l_i(A)$ y luego $T_j$ realiza $l_j(A)$.

$H$ es **SR** $\iff$ grafo de precedencia no tiene ciclos.

Órdenes topológicos del grafo de precedencia dan orden de *historia serial equivalente*

>[!NOTE]
>¿Cómo obtener ordenes topológicos?: Buscás el nodo sin aristas de entrada, lo sacás con todas sus aristas salientes y lo ponés en una lista. Repetís el proceso hasta que no te queden nodos y lo tenés.

#### Esquema lock ternario

Como las <ins>lecturas de un mismo item por parte de múltiples transacciones no generan conflictos</ins>, incorporamos mecanismo para permitirlas.

- $rl_i(A)$: Lock de lectura compartido.
- $wl_i(A)$: Lock de escritura exclusivo.

| $T_i$ solicita | $T_j$ tiene (rl) | $T_j$ tiene (wl) |
| :------------: | :--------------: | :--------------: |
| **rl**         | ✅ Se lo damos   | ❌ Denegado      |
| **wl**         | ❌ Denegado      | ❌ Denegado      |

*Solo permitimos varios locks de lectura $rl$ en simultáneo*.

##### Historias legales

**Requisitos de consistencia**:

- Todo $r_i(X)$ debe ser precedido por $rl_i(X)$ sin $u_i(X)$ intermedio. *No podés leer sin el lock de lectura sobre ese item*.
- Todo $w_i(X)$ debe ser precedido por $wl_i(X)$ sin $u_i(X)$ intermedio. *No podés escribir sin el lock de escritura sobre ese item*.
- Todos los locks deben ser seguidos por un unlock del mismo elemento. *En algún momento lo tenés que liberar*.

**Requisitos de legalidad**:

- Si $wl_i(X)$ aparece en una historia, entonces no puede haber luego un $wl_j(X)$ o $rl_j(X)$ para $j \neq i$ sin que haya primero un $u_i(X)$. *Si solicitaste lock de escritura sobre un item nadie lo puede leer ni escribir hasta que lo liberes*.

- Si $rl_i(X)$ aparece en una historia, entonces no puede haber luego un $wl_ij(X)$ para $j \neq i$ sin que haya primero un $u_i(X)$. *Si alguien tiene el lock de lectura sobre un item, no podés recibir el de escritura sobre el mismo hasta que esa lo libere*.

#### Grafo precedencia

- Nodo por cada $T_i$.
- Si $T_i$ hace un $rl_i(X)$ o $wl_i(X)$ y luego $T_j$, con $i \neq j$ hace un $wl_j(X)$ en $H$, ponés $T_i \xrightarrow T_j$. *Si pediste lock (lectura o escritura) sobre item y otra lo escribe después, entonces ponés arista*.
- Si $T_i$ hace un $wl_i(X)$ y luego $T_j$, con $i \neq j$ hace un $rl_j(X)$ en $H$, ponés $T_i \xrightarrow T_j$. *Si escribiste un item y otra lo quiere leer, ponés arista*.

#### *Lock upgrading/downgrading*

- **Upgrading lock**: Pasar de lock de lectura compartido a uno exclusivo de escritura.
- **Downgrading lock**: Pasar de lock de escritura exclusivo a uno de lectura compartido.

**Problema**: Solo concedemos la actualización si es la única transacción con ese lock sobre el item. En el caso *downgrading* sabemos que es el único que lo posee por ser exclusivo, pero en *upgrading* no, ya que varios pueden tener compartido el de lectura y ninguna puede hacer el *upgrading* hasta que las demás lo liberen.

#### *Update locking*

Para solucionar el problema del *deadlock por upgrading* agregamos el ***update lock***, $ul_i(X)$ que da privilegio de lectura pero no de escritura, con la ventaja de ser el único que puede solicitar *upgrading* a *write lock*.

| $T_i$ solicita | $T_j$ tiene (rl) | $T_j$ tiene (wl) | $T_j$ tiene (ul) |
| :------------: | :--------------: | :--------------: | :--------------: |
| **rl**         | ✅ Se lo damos   | ❌ Denegado      | ❌ Denegado      |
| **wl**         | ❌ Denegado      | ❌ Denegado      | ❌ Denegado      |
| **ul**         | ✅ Se lo damos   | ❌ Denegado      | ❌ Denegado      |

*Solo le concedemos el $ul(X)$ si nadie lo tiene y nadie tiene $wl(X)$*.

>[!NOTE]
> Una transacción con un *shared lock* pero sin un *update lock* no puede recibir un *write lock*, incluso aunque en general no prohibimos que una transacción tenga múltiples locks sobre un elemento, por ejemplo de lectura y escritura en simultáneo. [2](pag. 945)

- Si ya hay transacciones que tienen un *read lock* sobre el ítem y otra nos solicita un *upgrade lock* sobre el mismo ítem → se lo concedemos.
- Una vez concedimos a una transacción un *update lock* sobre un ítem, ya no concedemos más locks de ningún tipo sobre ese ítem a cualquier transacción que nos lo solicite hasta que el que tiene el *update lock* lo libere.
  - ¿Por qué? Porque la idea es que, aunque debamos denegarle el *upgrading* a escritura sobre el ítem a la transacción que tiene el *update lock* porque otras tienen un *read lock* sobre el mismo ítem, eventualmente estas terminarán y podremos permitir que el poseedor de *upgrade lock* promocione a *write lock* y pueda escribir. Si siguiéramos otorgando *read locks* a otras transacciones podríamos generar *starvation* sobre la transacción con el *update lock*.

>[!IMPORTANT]
> En el *update lock* pueden varios tener locks de lectura no upgradeables a lock de lectura y uno solo tener el upgradeable no? RTA: Si. En dicho caso, los que tienen locks de lectura compartidos no upgradeables qué pasa cuando el que tiene el upgradeable quiere convertirlo en lock de escritura? lo liberan automaticamente o el upgradeable debe esperar a que lo hagan ellos manualmente? La matriz permite que si tenes uno de lectura y solicitan el de ul lo reciba por lo que acabarían conviviendo los de lectura con los ul? RTA: Sí, puede haber convivencia entre *read locks* y *update lock* sobre un mismo elemento. Lo que no puede pasar es que una vez entregué un *update lock* sobre un ítem, siga entregano *read locks* sobre él. Si el *update lock* debe esperar a que los *read locks* disponibles lo liberen o no es decisión de implementación. En *Wound-Die* y *Wait-Die* se vé.

>[!IMPORTANT]
> *Locking* por si solo no garantiza <ins>serializabilidad</ins>, se necesitan protocolos para posicionar lock y unlocks.

### Protocolos de *locking*

#### 2PL (*two phase locking*)

Transacción es 2PL $\iff$ todos los *locks* preceden a la primer operación de *unlock*.

El dos fases viene de: fase de adquisición de locks (*growing phase*) y fase de liberación (*shrinking phase*).

>[!NOTE]
> Si se permite *lock conversion*, entonces el *lock's upgrading* (pasar de *read lock* a *write lock*) debe realizarse en la fase de *growing*, mientras que el *downgranding* (pasar de *write lock* a *read lock*) debe realizarse en la fase de *shrinking*[3] (pag. 782).

**Teorema serializabilidad con 2PL**
Si todas las transacciones son 2PL, entonces toda historia legal sobre ellas es **SR**, incluso Gen(2PL) $\subset$ OCSR.

>[!NOTE]
>Todos los *schedules* que permite **2PL** son serializables, pero no permite a todos los que son serializables, i.e. correcto pero no completo.[3]

#### C2PL (*conservative two phase locking*)

Transacción es C2PL $\iff$ adquiere todos los locks que necesitará al inicio, es decir antes de su primer escritura o lectura, si no los puede adquirir, entonces toda la transacción espera hasta que se pueda.

>[!NOTE]
> Es protocolo *deadlock free*.[3]

>[!NOTE]
> Difícil de aplicar porque requiere conocer de antemano todos los items que una transacción lee y escribe.[3]

#### 2PLE o S2PL (*strict two phase locking*)

Transacción es 2PLE $\iff$ es 2PL y no libera ninguno de sus locks de escritura hasta después de realizar commit o abort.

>[!NOTE]
>2PLE garantiza que historia es **ST**.[3]

>[!NOTE]
>No es *deadlock free*.[3]

>[!IMPORTANT]
> 2PLE garantiza que historia es **ST**: ¿significa que toda historia compuesta por transacciones 2PLE es ST?

>[!IMPORTANT]
> Necesariamente debe liberarlos después que los de lectura? RTA: No hay restricción sobre eso.


#### 2PLR o SS2PL (*rigurous two phase locking*)

Transacción es 2PLR $\iff$ es 2PL y no libera ninguno de sus locks de escritura o lectura hasta después del commit o abort.

>[!NOTE]
> También garantiza que historia es **ST**.[3]

### Deadlocks

*Estado en el cual cada miembro de un grupo de transacciones está esperando que algún otro miembro libere un lock*.

Dos enfoques:

- [Deadlock detection](#detección-de-deadlocks-wait-for-graph).
- [Deadlock prevention](#prevención-de-deadlocks).

¿Cuándo conviene cada uno?[3]

- Si sabés que hay poca interferencia o que es poco probable → deadlock detection.
- Si hay mucha interferencia o es muy probable → deadlock prevention.

#### Detección de *deadlocks*: Wait-for graph

- Un nodo por cada transacción que tiene un *lock* o espera por uno.
- Una arista entre $T_i$ y $T_j$ si $T_i$ está esperando que $T_j$ libere un lock sobre un item que $T_i$ necesita bloquear. *Arrancás desde final de $H$ y ponés arista si hay un lock previo sobre mismo item*. ![Aristas en wait for graph](./images/aristas_en_wait_for_graph.drawio.svg)
- Una vez $T_j$ libera el recurso, borramos la arista.

Ciclos $\iff$ estamos en estado de *deadlock*.

##### ¿Cada cuanto lo chequeamos?

Tradeoff entre evitar excesivo *overhead* y detectar *deadlocks* a tiempo.

##### Si hay *deadlock*... ¿a quién rajamos?

Priorizar no sacar a la que lleva más progreso.

#### Prevención de *deadlocks*

##### Timestamping

Cada transacción $T_i$ tiene un timestamp $TS(T_i)$ es un identificador único basado en orden en el que cada transacción comienza.

**Estrategias**:
Si $T_i$ quiere realizar un lock sobre un item y no puede porque $T_j$ ya tiene un lock previo sobre él, entonces:

- ***Wait-die***:
  - Si $T_i$ es más viejo que $T_j \xrightarrow T_i$ espera.
  - Si $T_i$ es más joven que $T_j \xrightarrow T_i$ aborta y reinicia más tarde <ins>con mismo *timestamp*</ins>.
- ***Wound-wait***:
  - Si $T_i$ es más viejo que $T_j \xrightarrow T_j$ aborta y reinicia más tarde <ins>con el mismo *timestamp*</ins>.
  - Si $T_i$ más joven que $T_j \xrightarrow T_i$ espera.

>[!NOTE]
> Es reiniciar con el mismo timestamp lo que reduce cada vez más las chances de que vuelva a ser abortada, impidiendo **starvation**.[3]

>[!NOTE]
> $TS(T_i) \lt TS(T_j) \iff$ $T_i$ es más viejo que $T_j$.

>[!NOTE]
> *Wait-Die* y *Wound-Wait* son *deadlock free*.[3]

##### Otros esquemas

- Timeout.
- No waiting (NW): Si no puede obtener lock que necesita → la abortan y que se reinicie después de un periodo de tiempo. Genera muchos *aborts*.
- Cautious waiting (CW): Querés un ítem que tiene otra transacción $T ^\prime$, si esa no está esperando un ítem que tiene otra, entonces te dejo esperar, sino *abort* y intentá más tarde. Es *deadlock free*.

## Paradigma pesimista

**Clave**: Asumir que no ocurrirá comportamiento no serializable y solo actuar para reparar el problema cuando aparece una violación.

**Métodos**:

- [*Timestamping*](#timestamping).
- [*Timestamping multiversión*](#timestamping-multiversión).
- [*Validación*](#validacion).

>[!NOTE]
> *Concurrency control techniques based on timestamp ordering do not use locks; hence, *deadlocks cannot occur*.*[3]

### Timestamping

- Cada transacción $T$ tiene un *timestamp* $TS(T)$ asociado. $TS(...)$ debe dar un <ins>orden total (<)</ins>.
- Se asume que el orden en que llegan las transacciones es el orden serial en el que debe parecer que se ejecutan.

#### Estructuras necesarias

- *Scheduler* debe mantener:
  - Tabla [Transacciones activas, *timestamp*].
  - Tabla con entradas [X, RT(X), WT(X), C(X)] para cada X ítem de la DB. Donde:
    - RT(X): *timestamp* de último lector de X.
    - WT(X): *timestamp* de último escritor de X.
    - C(X): *commit bit* es $1 \iff$ último que escribió X ya commiteó.

>[!NOTE]
> C(X) sirve para evitar [*dirty reads*](#dirty-reads).

>[!NOTE]
> Un [*dirty read*](#dirty-reads) es físicamente realizable, ya que se lee después de que la transacción previo escribió el valor, el tema es que si esa aborta, la lectora tiene datos correspondientes a una transacción abortada, por lo que nunca existió para la DB.

#### Escrituras *tentativas*

Si una transacción $T$ escribe ítem $X$ y luego aborta, entonces se pone C(X) = 0, se reestablecen los valores de $X$ y de WT(X) a los previos a la escritura de $T$.

#### Comportamiento físicamente irrealizable

*Scheduler* debe mantener el invariante de que cada operación (lectura o escritura) que ocurre también habría ocurrido si se ejecutaban las transacciones por completo en el momento de su *timestamp*, es decir no viola el *timestamp order*. Dicho comportamiento se considera **físicamente irrealizable**.

**Comportamientos irrealizables:**

- *read too late*:
  - $TS(T) \lt WT(X)$, $T quiere leer $X$ pero su valor ya lo pisó otra transacción posterior a $T$.
- *write too late*:
  - $WT(X) \lt TS(T) \lt RT(X)$, una transacción posterior a $T$ ya leyó $X$ y en $X$ está el valor previo a la ejecución de $T$, por lo que si $T$ tenía que escribir llegó tarde.
- *Thomas write rule*:
  - Si una transacción posterior $U$ a vos (transacción $T$) ya escribió su valor en un item que tenés que escribir, no hace falta que escribas.
  - ¿Y los que tenían que leer el valor que yo ($T$) iba a escribir en ese item?: Si alguien tiene que leer el valor que vos escribirías y no el de $U$, entonces esa transacción iría después que $T$ y antes que $U$, pero al leer el item que ya fue escrito por $U$ que es posterior a ella, habría sido abortada, por lo que no leyó el valor de $U$.

#### Operaciones del *scheduler*

El *scheduler* para garantizar que solo ocurran **comportamientos físicamente realizables** puede:

- Permitir una operación (lectura, escritura o commit).
- Abortar una transacción (si hay comportamiento irrealizable) y reiniciarla con <ins>nuevo *timestamp*</ins> (*rollback*).
- Retrasar la transacción.

#### Algoritmo del *scheduler* (strict timestamp ordering)

- $T$ quiere leer $X$:
  - Si $TS(T) \geq WT(X)$ *lectura es físicamente realizable*.
    - Si $C(X) == 1$, entonces que lea y ponemos $RT(X) := TS(T)$.
    - Sino, retrasar $T$ hasta que $C(X) == 1$ o la que escribe $X$ aborte (ya que ese valor iba a leer $T$).
  - Si $TS(T) \lt WT(X)$ [*read too late*](#comportamiento-físicamente-irrealizable) se hace **rollback**, es decir se aborta e reinicia con nuevo *timestamp*.
- $T$ quiere escribir $X$:
  - Si $TS(T) \geq RT(X) \land TS(T) \geq WT(X)$, *escritura es físicamente realizable*.
    - Escribimos valor en $X$.
    - Ponemos $T$ como última escritora de $X$, $WT(X) = TS(T)$.
    - Ponemos *commit bit* en false, porque aún no commiteamos, $C(X) := 0$.
  - Si $TS(T) \geq RT(X)$, pero $TS(T) \lt WT(X)$, es decir podés escribir pero alguien posterior a vos ya escribió.
    - Si $C(X) == 1$, entonces el que es posterior pero ya escribió encima commiteó, por lo que no hace falta que escribas.
    - Si $C(X) := 0$, entonces el que escribió y iría después en orden serial aún no commiteó, por lo que tenés que esperar hasta que commitee o aborte.
      - Si aborta ponés tu valor.
      - Si commitea te salteas la escritura.
  - Si $TS(T) \lt RT(X)$ querés escribir un valor pero las transacciones posteriores ya leyeron el previo, entonces dejamos que ellas continuen y vos hacés *rollback*.
- $T$ quiere hacer *commit* $C_{T}$:
  - Buscás todos los items $X$ que escribió $T$ y les ponés $C(X) := 1$ y permitís continuar a todas las transacciones que estén esperando el *commit* de $T$.
- $T$ quiere hacer *abort* o hay que hacer *rollback*:
  - A todos los que estaban esperando al *commit* de $T$ porque leían o escribían un item que $T$ también escribió, entonces deben reintentar su operación.

>[!NOTE]
> Este algoritmo garantiza serialización e historias **ST**.[3]

>[!NOTE]
> Las esperas no generan *deadlocks* ya que solo se espera a una única transacción con timestamp menor, i.e. previa.[3]

Timestamping suele ser mejor cuando hay muchas lecturas y es raro que una transacción trate de leer y escribir el mismo ítem.

Si hay muchos conflictos conviene *locking*.

### Timestamping multiversión

- Mantiene versiones históricas de los ítems y permite leerlas.
- Evita *aborts* por *read too late*.
- Asumiendo que cada transacción escribe un ítem solo una vez, denotamos a la versión creada por $w_i(X)$ como $X_i$.
- Cliente no se entera de que hay versiones ni nada.
- Hay *garbage collector* de versiones.

#### Función de versión

Dada una lectura de un ítem te dice qué operación escribió ese valor.

#### Historias multiversión

<details>
<summary>Definición de historial multiversión y orden</summary>

$T = \{t_1, \dots, t_n\}$ es un par $m = (\operatorname{op}(m), <_m)$ donde $<_m$ es un orden en $\operatorname{op}(m)$ y:

* (a) $\operatorname{op}(m) = \bigcup_{i=1}^{n} h(\operatorname{op}(t_i))$ para alguna función de versión $h$,
* (b) para todo $t \in T$ y todo $p, q \in \operatorname{op}(t): p <_t q \implies h(p) <_m h(q)$,
* (c) si $h(r_j(x)) = r_j(x_i)$, $i \neq j$, y $c_j$ está en $m$, entonces $c_i$ está en $m$ y $c_i <_m c_j$.

</details>

#### **Lectura entre transacciones** (revisited)

Una transacción $T_j$ lee de otra $T_i$ en la historia $m \iff r_j(X_i) \in op(m)$. *Es decir si lee una versión escrita por la otra transacción*.  

#### *view equivalencia*

Dos *schedules multiversión* $m$ y $m^{\prime}$ con las mismas transacciones son *view equivalentes*  ($m \approx_{v} m^{\prime}$) si todas sus transacciones leen de las mismas transacciones.

#### *Multiversión view serializable* (MVSR)

Sea $m$ una *historia multiversión*, se dice que $m$ es *multiversión
view serializable* si existe una historia $m^{\prime}$ serial monoversión tal que $m \approx_{v} m^{\prime}$

>[!NOTE]
> Decidir si una historia es *MVSR* es NP-Completo

##### Grafo MVSG (*Grafo de Serialización Multiversión*)

- $<<$ es el orden en que aparecerían las escrituras en la serial equivalente.
- Los nodos son las transacciones commiteadas de $m$.
- Aristas:
  - $r_k(x_j) \in op(m)$, agregar $t_j \xrightarrow t_k$, *arista hacia la transacción de la que lees*.
  - Para las operaciones $r_k(x_j), w_i(x_i)$ de las transacciones commiteadas con $k, i, j$ distintos, si $x_i << x_j$, agregar $t_i \xrightarrow t_j$ y si $x_i << x_j$. *arista de las que escribieron versiones previas a la transacción cuya versión es leída*
  - Para las operaciones $r_k(x_j), w_i(x_i)$ de las transacciones commiteadas con $k, i, j$ distintos, si $x_j << x_i$ agregar $t_k \xrightarrow t_i$. *arista de las que leen versiones previas a las transacciones que generan nuevas versiones del item*

>[!IMPORTANT]
> Historia multiversión $m$ es **MVSR** $\iff$ existe orden de versiones $<<$ tal que $MVSG(m, <<)$ es acíclico

#### *Multiversión conflicto serializable* (MCSR)

- Pertenencia es [chequeable en $\mathcal{P}$](#chequeo-de-pertenencia-a-mcsr).
- *MCSR* $\subset$ *MVSR*.
- Historia $m$ es *MCSR* si hay *historia monoversión serial* para el mismo conjunto de transacciones en el que todos los pares de operaciones en [*conflicto multiversión*](#definición-de-conflicto-en-multiversión) ocurren en mismo orden que en $m$.

##### Definición de conflicto en multiversión

Par de pasos $r_i(x_j)$ y $w_k(x_k)$ tales que $r_i(x_j) \lt_{m} w_k(x_k)$, es decir, *lecturas de versión de un ítem previas a escritura de una nueva versión del ítem*. Están en conflicto porque no puedo permitarlas sin que *schedule* pierda correctitud.

##### Transformaciones

Es intercambiar el orden de pasos adyacentes pero sin invertir el orden de un [par de conflicto multiversión](#definición-de-conflicto-en-multiversión) (read-write).

##### Historia multiversión reducible

Son las que pueden mediante [transformaciones](#transformaciones) en una *historia serial monoversión*.

##### Chequeo de pertenencia a MCSR

- Nodos para cada transacción.
- $t_i \xrightarrow{} t_j$ si existe $r_i(x_j)$ y $w_k(x_k)$ para el mismo ítem $X$ tal que $r_i(x_j) \lt_{m} w_k(x_k)$.
- $m$ es [*MCSR*](#multiversión-conflicto-serializable-mcsr) $\iff$ grafo es acíclico.

>[!NOTE]
>Orden topológico no nos da historia monoversión serial equivalente

#### Protocolos

Los posibles protocolos son:

- [*Multiversion Timestamp Ordering* (**MVTO**)](#multiversion-timestamp-ordering-mvto)
- [*Multiversion Two Phase Locking* (**MV2PL**)](#multiversion-two-phase-locking-mv2pl)
- [*Read Only Multiversion* (**ROMV**)](#read-only-multiversion-romv)

##### Multiversion Timestamp Ordering (**MVTO**)

- Cada operación lleva el *timestamp* de la transacción que la creó.
- Lecturas nunca se rechazan.
- En caso de lecturas $r_i(X)$ pasamos a tener $r_i(X_k)$ con $X_k$ versión leída, que debe cumplir $TS(T_k) \lt TS(T_i)$, es decir *ser previa*.
- En caso de escrituras $w_i(X)$:
  - Si $r_j(x_k)$ tal que $$ ya existe en el *schedule*, entonces rechazamos $w_i(X)$ y abortamos $T_i$ por [*write too late*](#comportamiento-físicamente-irrealizable). Es decir, *si una transacción posterior ya leyó valor escrito por una previa a nosotros, nos abortan*.
  - Sino transformamos $w_i(X)$ en $w_i(X_i)$ y la ejecutamos. Es decir, *creamos nueva versión*.
- En *commits* $c_i$, lo retrasamos hasta que todas las transacciones $t_j$ que escribieron nuevas versiones de lo que leyó $t_i$ commiteen. (Evita [*dirty reads*](#dirty-reads))

##### Multiversion Two Phase Locking (**MV2PL**)

>[!IMPORTANT]
> Al igual que [2VPL](#2pl-two-phase-locking) no evita *deadlocks*. (2V2PL tampoco)

- Protocolo basado en *locking*, usa [*2PL riguroso*](#2plr-o-ss2pl-rigurous-two-phase-locking)
- Los ítems $X$ tienen:
  - *Versiones commiteadas*: Escritas por transacciones commiteadas.
  - <a id="version_actual_mv2pl">*Versión actual*</a>: Versión commiteada escrita por la última transacción commiteada.
  - <a id="version_no_commiteada_mv2pl">*Versiones no commiteadas*: Creadas por transacciones activas</a>.

###### Paso final de una transacción

Último paso antes del *commit* o el *commit* mismo.

###### Protocolo

- Si es paso final de $T_i$, esta se retrasa hasta que commiteen:
  - Todas las transacciones de las que leyó alguna versión.
  - Todas las que leyeron la versión actual de un ítem que escribió $T_i$
- Si el paso no es final en $T_i$:
  - Lectura $r(x)$ se ejecuta inmediatamente, recibiendo [versión actual](#version_actual_mv2pl) del ítem solicitado, o [versión no commiteada](#version_no_commiteada_mv2pl).
  - Escritura $w(X)$ se ejecuta solo cuando la última que escribió $X$ commiteó, i.e. ya no hay otra [versión no commiteada](#version_no_commiteada_mv2pl) de $X$.

###### Protocolo 2V2PL

- Mantiene como máximo 2 versiones de cualquier dato en cualquier momento.
- Una vez $T_i$ commitea podemos eliminar su versión no commiteada y considerarla como versión commiteada.
- Las lecturas solo pueden leer [versiones actuales](#version_actual_mv2pl), por lo tanto *commiteadas*.

##### Read Only Multiversion (**ROMV**)

- Combinar simplicidad [2PL](#2pl-two-phase-locking) o de [timestamp simple](#timestamping) con multiversiones.
- Transacciones puede ser:
  - De actualización:
    - Sigue [2PL](#2pl-two-phase-locking).
    - Cada escritura crea nueva versión en vez de sobreescribir.
    - Versiones tienen tiempo del commit de la transacción como *timestamp*.
  - De *read only*:
    - Siguen protocolo similar al [*MVTO*](#multiversion-timestamp-ordering-mvto)
    - *Timestamp* asignado al inicio de transacción.
    - Transacciones siempre acceden a última versión commiteada al iniciar.
  - Lectores leen solo versiones ya commiteadas.
  - Trasacciones de actualización no se benefician del versionado.

[1] [A Critique of ANSI SQL Isolation Levels](https://arxiv.org/pdf/cs/0701157)

[2] [Molina, Ullman, Widom Database systems: The Complete Book]

[3] [ Ramez A Elmasri y Shamkant B. Navathe
Fundamentals of Database Systems]