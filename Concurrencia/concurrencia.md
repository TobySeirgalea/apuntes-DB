# Práctica concurrencia y recuperación

## Ejercicio 1.1

> Dada la siguiente historia (schedule) que es conflicto-serializable transformarla en una historia serial mediante una secuencia de intercambios no conflictivos de acciones adyacentes.

$H_1 = r_1(A);w_1(A);r_2(A);w_2(A);r_1(B);w_1(B);r_2(B);w_2(B)$

![Grafo de precedencia](./images/ej1.1.drawio.svg)

- Como es acíclico $\iff$ la historia es serializable.
- Obtengo un orden topológico del grafo para obtener un posible orden de las transacciones en una historial serial.
- La historia serial equivalente ejecuta primero todas las operaciones de $T_1$ y luego las de $T_2$.

$H_1 \equiv H_S = r_1(A);w_1(A);r_1(B);w_1(B);r_2(A);w_2(A);r_2(B);w_2(B)$

## Repaso teorico

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

>[!IMPORTANT] **Consultar**: El hecho de leer de una que aún no ha sido commiteada es *dirty read*, aunque si ella aborte la que leyó también lo haga ¿sigue siendo *dirty read*?

#### *Lost updates*

Lost Update: Ocurre cuando una transacción $T_1$ lee un item y luego $T_2$ lo escribe (posiblemente basado en una lectura previa), luego $T_1$, basado en su valor leído actualiza el item y commitea. [1]

Patrón: $r_1(x);\dots;w_2(x);\dots;w_1(x);\dots;c_1$ (Lost Update) [1]

>[!IMPORTANT] **Consultar**: ¿Es la única forma en que puede ocurrir *lost update*?¿*dirty write* ($w_1(X);\dots;w_2(X)$) es considerado *lost update*? ¿En el patrón da igual si $T_2$ commiteó o no?

#### *Phantom reads*

Distintas lecturas de un item en una transacción dan resultados distintos porque entre lecturas fue modificado por otra transacción.

### Control de concurrencia

### Esquema lock binario

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

>[!NOTE] ¿Cómo obtener ordenes topológicos?: Buscás el nodo sin aristas de entrada, lo sacás con todas sus aristas salientes y lo ponés en una lista. Repetís el proceso hasta que no te queden nodos y lo tenés.

>[!IMPORTANT] **CONSULTAR**: Si hay ciclo no es serializable?

### Esquema lock ternario

Como las <ins>lecturas de un mismo item por parte de múltiples transacciones no generan conflictos</ins>, incorporamos mecanismo para permitirlas.

- $rl_i(A)$: Lock de lectura compartido.
- $wl_i(A)$: Lock de escritura exclusivo.

| $T_i$ solicita | $T_j$ tiene (rl) | $T_j$ tiene (wl) |
| :------------: | :--------------: | :--------------: |
| **rl**         | ✅ Se lo damos   | ❌ Denegado      |
| **wl**         | ❌ Denegado      | ❌ Denegado      |

*Solo permitimos varios locks de lectura $rl$ en simultáneo*.

#### Historias legales

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

>[!IMPORTANT] **CONSULTAR**: Si hay ciclo no es serializable?

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

>[!IMPORTANT] *Locking* por si solo no garantiza <ins>serializabilidad</ins>, se necesitan protocolos para posicionar lock y unlocks.

### Protocolos de *locking*

#### 2PL (*two phase locking*)

Transacción es 2PL $\iff$ todos los *locks* preceden a la primer operación de *unlock*.

El dos fases viene de: fase de adquisición de locks (*growing phase*) y fase de liberación (*shrinking phase*).

**Teorema serializabilidad con 2PL**
Si todas las transacciones son 2PL, entonces toda historia legal sobre ellas es **SR**, incluso Gen(2PL) $\subset$ OCSR.

#### C2PL (*conservative two phase locking*)

Transacción es C2PL $\iff$ adquiere todos los locks que necesitará al inicio, es decir antes de su primer escritura o lectura.

#### 2PLE o S2PL (*strict two phase locking*)

Transacción es 2PLE $\iff$ es 2PL y no libera ninguno de sus locks de escritura hasta después de realizar commit o abort.

2PLE garantiza que historia es **ST**.

#### 2PLR o SS2PL (*rigurous two phase locking*)

Transacción es 2PLR $\iff$ es 2PL y no libera ninguno de sus locks de escritura o lectura hasta después del commit o abort.

### Deadlocks

*Estado en el cual cada miembro de un grupo de transacciones está esperando que algún otro miembro libere un lock*.

#### Detección de *deadlocks*: Wait-for graph

- Un nodo por cada transacción que tiene un *lock* o espera por uno.
- Una arista entre $T_i$ y $T_j$ si $T_i$ está esperando que $T_j$ libere un lock sobre un item que $T_i$ necesita bloquear. *Arrancás desde final de $H$ y ponés arista si hay un lock previo sobre mismo item*.

Ciclos $\iff$ hay deadlock.

#### Prevención de *deadlocks*

##### Timestamping

Cada transacción $T_i$ tiene un timestamp $TS(T_i)$ es un identificador único basado en orden en el que cada transacción comienza.

**Estrategias**:
Si $T_i$ quiere realizar un lock sobre un item y no puede porque $T_j$ ya tiene un lock previo sobre él, entonces:

- ***Wait-die***:
  - Si $T_i$ es más viejo que $T_j \xrightarrow T_i$ espera.
  - Si $T_i$ es más joven que $T_j \xrightarrow T_i$ aborta y reinicia más tarde con mismo timestamp.
- ***Wound-wait***:
  - Si $T_i$ es más viejo que $T_j \xrightarrow T_j$ aborta y reinicia más tarde con el mismo timestamp.
  - Si $T_i$ más joven que $T_j \xrightarrow T_i$ espera.

>[!NOTE] $TS(T_i) \lt TS(T_j) \iff$ $T_i$ es más viejo que $T_j$.

##### Otros esquemas

- Timeout.
- No waiting (NW).
- Cautious waiting (CW).

## Ejercicio 1.2

> Dadas las siguientes historias (schedules):

### (a) Indicar para cada una si es NoRC, RC, ACA o ST.

Dado que si es **RC** será tanto **ACA** como **ST** conviene primero chequear si es **RC**.

$H_1 = r_1(X);r_4(Y);w_1(X);w_4(X);r_3(X);c_1;w_4(Y);w_3(Y);w_4(Z);c_4;w_3(X);c_3$

- Es **RC** $\iff$ todos commitean luego de aquellos de los que leen.
  - Hay solo 3 lecturas. Primero analizo esas.
    - $r_1(X)$ y $r_4(X)$ no imponen restricciones.
    - $r_3(X)$ significa que $T_3$ lee de $T_4$, por lo que $c_4 \lt c_3$. Lo cual se cumple.
- Es **ACA** $\iff$ nadie lee de una que no haya sido commiteada.
  - No lo es ya que: $w_4(X);r_3(X)$. Por lo tanto no es **ACA** y tampoco podrá ser **ST** pues **ST** $\subset$ **ACA** $\subset$ **RC**.

$H_2=r_1(X);w_2(X);r_1(Y);w_1(X);w_1(Y);c_1;r_2(Z);w_2(Y); c_2$

- Es **RC** $\iff$ todos commitean luego de aquellos de los cuales leen.
  - Hay 3 lecturas. Primero analizo esas.
    - $r_1(X)$, $r_1(Y)$ y $r_2(Z)$ no imponen restricciones porque nadie escribió antes esos items en $H_2$.
  - Como nadie lee de nadie, es **RC** vacuamente ✔.

- Es **ACA** $\iff$ todos leen solo de commiteadas.
  - Como nadie lee de nadie, es **ACA** vacuamente también ✔.

- Es **ST** $\iff$ nadie lee ni escribe item si la última que lo escribió no commiteó o abortó. 
  - No vale, pues en $H_2$ tenemos $w_2(X);r_1(Y);w_1(X)$.
  - $\therefore$ no es **ST**.

$H_3=w_1(X);w_2(X);w_2(Y);c_2;w_1(Y);c_1;w_3(X);w_3(Y);c_3$

- Es **RC** $\iff$ todos commitean después de que lo hacen aquellas de las cuales leyeron.
  - Como no hay lecturas nadie lee de nadie y se cumple vacuamente ✔.
- Es **ACA** $\iff$ todos leen de transacciones ya commiteadas.
  - Como no hay lecturas nadie lee de nadie y se cumple vacuamente ✔.
- Es **ST** $\iff$ Nadie lee ni escribe un item hasta que la última que lo escribió haya hecho commit u abortado.
  - No se cumple, $w_1(X);w_2(X)$.
  - $\therefore$ no es **ST**.

$H_4=w_2(X);r_1(X);r_2(Z);r_1(Y);w_2(Y);w_1(Y);c_2;w_1(X);c_1$

- Es **RC** $\iff$ nadie commitea hasta que lo hacen todas aquellas de las cuales leyó.
  - $w_2(X);\dots;r_1(X)$ dice que $T_1$ lee de $T_2$, por lo tanto debería valer que $c_2 < c_1$ lo cual se cumple.
  - El resto de las lecturas son sobre items no escritos en $H_4$ por lo que no imponen restricciones.
  - $\therefore$ es **RC**.
- Es **ACA** $\iff$ nadie lee de alguien que no haya aún commiteado al momento de la lectura.
  - No cumple porque $w_2(X);r_1(X)$ indica que $T_1$ lee de $T_2$ sin que haya commiteado.
  - $\therefore$ No es **ACA** y por lo tanto tampoco es **ST**, pues ST $\subset$ ACA $\subset$ RC.

$H_5=r_1(X);r_4(Y);r_3(X);w_1(X);w_4(Y);w_3(X);c_1;w_3(Y); w_4(Z);c_3;w_4(X);c_4$

- Es **RC** $\iff$ nadie commitea antes que las transacciones de las cuales lee.
  - Nadie lee de nadie porque no tenemos escrituras previas de los items que son leídos en $H_5$. Por lo tanto es **RC** vacuamente.
- Es **ACA** $\iff$ todos leen solo de transacciones ya commiteadas al momento de la lectura.
  - También vale vacuamente porque nadie lee de nadie. Por lo tanto es **ACA**.
- Es **ST** $\iff$ nadie escribe y lee un item hasta que la última que lo escribió haya commiteado o abortado.
  - No se cumple pues en $w_1(X);w_4(Y);w_3(X)$ $T_3$ escribe $X$ y aún no había ni commiteado ni abortado $T_1$, por lo que es una transacción activa.
  - $\therefore$ No es **ST**.

### (b) Indicar cuáles podrían producir un *dirty read* o un *lost update*

**Dirty reads**:

- Si es **ACA** no habrán *dirty reads* porque solo permitimos leer de transacciones ya commiteadas.
- Como **ST** $\subset$ **ACA**, entonces *strict* tampoco las permite.
- Los que son solamente **RC** permiten leer de un item modificado por una transacción, siempre y cuando hagamos commit luego de ella. $\therefore$ No evitan *dirty reads*.
- Los que son **NoRC** también los permiten.
- $\therefore H_1$ y $H_4$ son las únicas que son solo **RC** y no hay ninguna **NoRC**. Así que son las únicas que permiten *dirty reads*.

**Lost updates** (CONSULTARLO):

- Si permito leer de una que aún no commiteó, entonces pueden ocurrir *lost updates* si se opera de forma *interleaved* con esa transacción. Por lo tanto si es **RC** y no **ACA** o si es **NoRC**, debo chequear eso.
- Si es **ACA** no habrán *lost updates*, ya que solo leo de transacciones que ya commitearon.
- En $H_1$ hay *lost update* en $w_1(X);w_4(X)$ y $r_4(Y);\dots;w_4(Y);w_3(Y)$.
- En $H_2$ hay *lost update* $r_1(X);w_2(X);r_1(Y);w_1(X)$ porque se pierde lo que haya escrito en $X$ $T_2$.
- En $H_3$ también porque en $w_1(X);w_2(X)$ se pisa el valor que escribió $T_1$.
- En $H_4$ también en $w_2(Y);w_1(Y)$ y en $w_2(X);\dots;w_1(X)$.
- En $H_5$ también en $w_1(X);w_4(Y);w_3(X);c_1;w_3(Y)$ tenés dos.

## Ejercicio 1.3

> Clasificar según recuperabilidad las siguientes historias:

$H_1=r_1(X);r_2(Z);r_1(Z);r_3(X);r_3(Y);w_1(X);c_1;w_3(Y);c_3;r_2(Y);w_2(Z);w_2(Y);c_2$

- Es **RC** $\iff$ todas las transacciones solo commitean después de aquellas de las cuales leen.
  - El único read que impone restricciones por ser sobre un item escrito por otra transacción de la historia es $r_2(Y)$, el cual lee de $T_3$ y commitea después que ella. $\therefore$ es **RC**.
- Es **ACA** $\iff$ solo tiene lecturas de transacciones ya commiteadas.
  - La única lectura que impone restricciones es $r_3(Y)$ que lee de $T_3$ pero comitteó justo antes. $\therefore$ es **ACA**.
- Es **ST** $\iff$ toda escritura o lectura sobre un item se hace luego de que la que lo escribió haya commiteado o abortado.
  - $r_2(Y)$ que lee de $T_3$ que había commiteado justo antes.
  - $w_2(Y)$ escribe el mismo item que antes había escrito $T_3$ con $w_3(Y)$, pero lo hace después del commit de $T_3$.
  - $\therefore$ es **ST**.
- Es *schedule riguroso RG* $\iff$ es **ST** y al momento de cada escritura de un item todos sus lectores (de otras transacciones) ya abortaron o commitearon.
  - No porque $T_3$ lee $X$ y no commiteó ni abortó al momento de que $T_1$ lo intenta escribir. $\therefore$ no es **RG**.

$H_2=r_1(X);r_2(Z);r_1(Z);r_3(X);r_3(Y);w_1(X);w_3(Y);r_2(Y);w_2(Z);w_2(Y);c_1;c_2;c_3$

- Es **RC** $\iff$ todas las transacciones commitean luego de aquellas de las cuales leen.
  - Por $w_3(Y);r_2(Y)$, $T_2$ lee de $T_3$, pero $c_3 > c_2$, por lo que $T_2$ lee de $T_3$ y commitea antes. $\therefore$ no es **RC**. Luego como RG $\subset$ ST $\subset$ ACA $\subset$ RC, no cae en ninguna de esas categorías y es **NoRC**.

$H_3=r_1(X);r_2(Z);r_3(X);r_1(Z);r_2(Y);r_3(Y);w_1(X);c_1;w_2(Z);w_3(Y);w_2(Y);c_3;c_2$

- Es **RC** $\iff$ todas las transacciones commitean después de aquellas de las cuales leen.
  - Nadie lee de nadie porque todas las lecturas están antes que todas las escrituras. $\therefore$ es **RC** y también **ACA**, ya que vacuamente todos solo leen de transacciones commiteadas.
- Es **ST** $\iff$ todas las lecturas o escrituras de un item se hacen ya cuando la transacciones que escribieron su último valor están commiteadas o abortadas.
  - No se cumple por $w_3(Y);w_2(Y)$. $\therefore$ no es **ST** ni **RG**, ya que **RG** $\subset$ **ST**.

## Ejercicio 1.4

> Dadas las siguientes transacciones:
> $T_1 = w_1(B);r_1(C);w_1(C);$
> $T_2 = r_2(D);r_2(B);w_2(C);$

### Dar una historia $H_1$ que no sea **RC**

- Para que no sea **RC** debemos permitir que una transacción lea de otra pero commitee antes que ella.
- Podríamos usar que $T_1$ lea de $T_2$ con $w_2(C);\dots;r_1(C);\dots;c_1;\dots;c_2$ o que $T_2$ lea de $T_1$ con $w_1(B);\dots;r_2(B);\dots;c_2;\dots;c_1$.

Opción 1:

$r_2(D);r_2(B);w_2(C);w_1(B);r_1(C);w_1(C);c_1;c_2$

Opción 2:

$w_1(B);r_1(C);w_1(C);r_2(D);r_2(B);w_2(C);c_2;c_1$.

### Dar una historia $H_2$ que sea **ACA** pero no **ST**

- Para que sea **ACA** pero no **ST** debo leer solo de ya commiteadas y no (leer o escribir items tales que la última transacción que la escribió ya commiteó o abortó).
- La única combinación posible es leer solo de ya commiteadas, pero escribir items tales que la última que lo escribió aún no commiteó ni abortó.
- ¿Cómo podría romper **ST** con escrituras? $w_2(C);(no~c_2);w_1(C)$.
- Planteo eso y voy rellenando huecos:

$H=r_2(D);r_2(B);w_2(C);w_1(B);w_1(C);c_2;r_1(C);c_1$

Alternativa:

$H=r_2(D);r_2(B);w_1(B);w_2(C);c_2;r_1(C);w_1(C);c_1$

### Dar una historia $H_3$ que sea **ST**

- $H=T_1;c_1:T_2;c_2$ cumple por ser serial.

## Ejercicio 2.1

> Dada las siguientes transacciones escritas como Read/Write:
>
> $T_1 = r_1(A);w_1(A);r_1(A);w_1(B) \\ T_2 = r_2(A);w_2(A);r_2(B);w_2(B)$
>
> **Nota:**  Si bien ambas parecen iguales en realidad pueden realizar operaciones diferentes sobre los ítems leídos.

### (a) Incorporar locks para que llevarlas a un modelo con locking binario

- Encerramos cada lectura $r_i(X)$ con $l_i(X);r_i(X);ul_i(X)$.
- Encerramos cada escritura $w_i(X)$ con $l_i(X);w_i(X);ul_i(X)$.

$T_1 = l_1(A);r_1(A);ul_1(A);l_1(A);w_1(A);ul_1(A);l_1(A);r_1(A);ul_1(A);l_1(B);w_1(B);ul_1(B). \\ T_2 = l_2(A);r_2(A);ul_2(A);l_2(A);w_2(A);ul_2(A);l_2(B);r_2(B);ul_2(B);l_2(B);w_2(B);ul_2(B)$.

### (b) Realizar una historia legal pero no serializable

- Para que sea no serializable quiero que su grafo de precedencia tenga un ciclo.
- En su grafo de precedencia tenemos arista de $T_i$ a $T_j$ si $T_i$ realiza $l_i(A)$ y luego $T_j$ realiza $l_j(A)$.
- Para la arista de $T_1 \xrightarrow{A} T_2$ ubico primero $r_1(A);w_1(A)$ y luego $r_2(A);w_2(A)$.
- Para la arista  $T_2 \xrightarrow{B} T_1$ ubico primero $r_2(B);w_2(B)$ y luego $r_1(B);w_1(B)$.

$H=l_1(A);r_1(A);w_1(A);ul_1(A);l_2(A);r_2(A);w_2(A);ul_2(A);l_2(B);r_2(B);w_2(B);ul_2(B);l_1(B);r_1(B);w_1(B);ul_1(B)$

![Ciclo en el grafo de precedencia](./images/ej2.1.drawio.svg)

$H$ es una historia legal, pero no serializable.

## Ejercicio 2.2

> Dadas las siguientes transacciones que deben ser ejecutadas en forma concurrente, indicar una historia legal en el cual se produzca un dirty read:
>
> $T_1 = l_1(A);A = A + 2;l_1(B);B = A + 5;u_1(B);u_1(A);l_1(C);C = 2 ∗ C;u_1(C) \\ T_2 = l_2(A);A = A + 1;l_2(E);E = A + 8;l_2(D);u_2(E);D = D/5; u_2(A);u_2(D)$

- **Dirty read** es si lees de una transacción que aún no commiteó.
- La unica variable que escriben ambos es $A$ y ambas inician con esa escritura, por lo que $T_1$ y $T_2$ nos quedan divididas por ella.

$T_1' =l_1(A);A = A + 2;l_1(B);B = A + 5;u_1(B);u_1(A);$
$T_1''=l_1(C);C = 2 ∗ C;u_1(C)$
$T_2' =l_2(A);A = A + 1;l_2(E);E = A + 8;l_2(D);u_2(E);D = D/5; u_2(A)$
$T_2''=u_2(D)$

Cualquier ejecución de $T_1';T_2'$ o $T_2';T_1'$ va a hacer que una utilice el valor modificado por la otra en lugar del original de $A$ que hubiera utilizado si no se ejecutaran concurrentemente.

Las siguientes serían algunas de la posibles:

$H=T_1';T_2';T_1'';T_2''$
$H=T_1';T_2';T_2'';T_1''$
$H=T_2';T_1';T_2'';T_1''$
$H=T_2';T_1';T_1'';T_2''$

## Ejercicio 2.3

> Considerando la siguiente historia con el modelo introductorio de LOCK/UNLOCK
>
> ![Historia enunciado 2.3](./images/tabla_enunciado_ej2.3.png)

### (a) Determinar si es serializable

- Para chequear si es serializable armamos el grafo de precedencia acorde al modelo, en este caso es el de *lock binario* y vemos si tiene ciclos, en dicho caso será no serializable, caso contrario será serializable.
- Un nodo por cada transacción.
- Una arista $T_i \xrightarrow{X} T_j$ si $T_j$ tiene un lock sobre $X$ luego del de $T_i$.

![Grafo de precedencia](./images/ej2.3_grafo_precedencia.drawio.svg)

Es acíclico $\therefore$ es serializable.

### (b) En caso afirmativo, proponer un *schedule* serial equivalente

Para obtener un *schedule* serial equivalente computo su orden topológico.

$H_S=T_1;T_4;T_2;T_3$ sería uno de los posibles.
$H_S=T_4;T_1;T_2;T_3$ sería otro.

## Ejercicio 2.4

> Dadas las transacciones del [ejercicio 2.1](#ejercicio-21) llevarlas a un modelo de *locking binario* tal que ambas sean 2PL.
>
> $T_1 = r_1(A);w_1(A);r_1(B);w_1(B) \\ T_2 = r_2(A);w_2(A);r_2(B);w_2(B)$

- Para que ambas sean **2PL** deben cumplir que adquieran todos sus locks antes del primer unlock.
- Versión 2PL de $T_1=l_1(A);r_1(A);w_1(A);l_1(B);r_1(B);w_1(B);ul_1(A);ul_1(B)$.
- Versión 2PL de $T_2=l_2(A);r_2(A);w_2(A);l_2(B);r_2(B);w_2(B);ul_2(A);ul_2(B)$.
- Ahora dado que ambas son **2PL**, toda historia legal sobre ellas es **SR**, por lo tanto serializable.

## Ejercicio 2.5

> Dadas las siguientes transacciones:
>
> $T_1=l_1(A);l_1(B);u_1(A);u_1(B); \\ T_2=l_2(B);l_2(A);u_2(B);u_2(A);$

### (a) Responder: ¿Cumplen las transacciones $T_1$ y $T_2$ con 2PL?

Sí, las transacciones $T_1$ y $T_2$ cumplen con 2PL porque adquieren todos sus locks antes de liberar el primer lock.

### (b) Realizar un entrelazado tal que se produzca un *deadlock*

- $l_1(A);l_2(B);$ ya te genera un *deadlock* porque $T_1$ tiene el lock sobre $A$ pero no puede continuar sin adquirir el lock sobre $B$ y al mismo tiempo $T_2$, que tiene el lock sobre $B$, no puede continuar sin adquirir el de $A$. Así que ninguno llega avanzar.
- Completamos el *schedule* para formar una historia, de las varias posibles.

$H=l_1(A);l_2(B);l_1(B);l_2(A);u_1(A);u_1(B);u_2(B);u_2(A)$

>[!NOTE] Notar que dadas transacciones 2PL, podemos tener una historia que no lo sea.

## Ejercicio 3.1

> Dadas las siguientes transacciones $T_1$ y $T_2: \\$
> $T_1=wl_1(A);A = A + 1;wl_1(B);B = A + B;u_1(A);u_1(B) \\ T_2=rl_2(A);wl_2(C);C = A + 1;wl_2(D);D = 1;u_2(A);u_2(D);u_2(C)$.

### (a) Construir un *schedule* legal serializable que no sea serial

- Estamos en *locking ternario*.
- Para construir un *schedule* legal serializable que no sea serial debemos encontrar un intercalamiento de $T_1$ y $T_2$ tal que su *grafo de precedencia* sea *acíclico*.
- En el *grafo de precedencia* del modelo *locking ternario* tenemos:
  - Un nodo por cada transacción.
  - Una arista de $T_i \xrightarrow{X} T_j$ piden lock sobre mismo item y al menos una de ellas es un *write lock*.
  - $T_1$ pide lock sobre $A$ y $B$.
  - $T_2$ pide lock sobre $A, C$ y $D$.
  - El único item que me genera una arista entre las transacciones es $A$. Pero como me genera una sola arista, ningún intercalamiento que sea un *schedule* legal me generará un ciclo, por lo que son serializables.
  - Propongo $H=wl_1(A);A = A + 1;wl_1(B);B = A + B;u_1(A);rl_2(A);wl_2(C);C = A + 1;wl_2(D);D = 1;u_2(A);u_2(D);u_2(C);u_1(B)$, que sería ejecutar $T_1$ hasta que libera el lock sobre $A$, luego ejecutar $T_2$ y finalmente liberar el lock de $T_1$ sobre $B$.

### (b) Responder: ¿Cumplen las transacciones $T_1$ y $T_2$ con 2PL?

- $T_1$ sí cumple con 2PL, pues adquiere todos sus locks antes de liberar el primero.
- $T_2$ también.

## Ejercicio 3.2

> Dadas las transacciones $T_1$ , $T_2$ , $T_3$ y $T_4$ con el siguiente entrelazado:
> ![Tabla enunciado ejercicio 3.2](./images/tabla_enunciado_ej3.2.png)

### (a) Determinar si es serializable y, en caso afirmativo, proponer las correspondientes historias seriales equivalentes

- De nuevo, estamos en esquema *locking ternario*.
- Construimos el grafo de precedencia y vemos si es acícliclo, en dicho caso es una historia serializable (**SR**).
  - Ponemos un nodo por cada transacción.
  - Una arista de $T_i \xrightarrow{X} T_j$ si ambas lockean el mismo recurso y al menos una de ellas es un *write lock*, vemos la historia en orden ascendente temporalmente.

![Tabla para saber de donde salen las aristas](./images/ej3.2_tabla.drawio.svg)

![Grafo de precedencia](./images/ej3.2.grafo.drawio.svg)

Es acíclico, por lo tanto la historia es serializable. Obtengo una historia serial equivalente a partir de un orden topológico del grafo:

- $T_2$ es el único sin aristas de entrada, lo saco y lo pongo primero en el orden.
- Al eliminar $T_2$ el único que queda sin aristas de entrada es $T_3$. Lo saco y añado al orden.
- Al eliminar $T_3$ el único que queda sin aristas de entrada es $T_1$, lo saco y añado al orden.
- Saco y añado al orden a $T_4$.

Orden topológico: $T_2, T_3, T_1, T_4 \therefore H \equiv H_s = T_2;T_3;T_1;T_4$.


[1] [A Critique of ANSI SQL Isolation Levels](https://arxiv.org/pdf/cs/0701157)