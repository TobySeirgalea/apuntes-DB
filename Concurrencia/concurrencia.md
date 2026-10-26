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

[1] [A Critique of ANSI SQL Isolation Levels](https://arxiv.org/pdf/cs/0701157)