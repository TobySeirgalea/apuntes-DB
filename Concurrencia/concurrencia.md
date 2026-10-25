# Práctica concurrencia y recuperación

## Ejercicio 1.1

> Dada la siguiente historia (schedule) que es conflicto-serializable transformarla en una historia serial mediante una secuencia de intercambios no conflictivos de acciones adyacentes.

$H_1 = r_1(A);w_1(A);r_2(A);w_2(A);r_1(B);w_1(B);r_2(B);w_2(B)$

![Grafo de precedencia](./images/ej1.1.drawio.svg)

- Como es acíclico $\iff$ la historia es serializable.
- Obtengo un orden topológico del grafo para obtener un posible orden de las transacciones en una historial serial.
- La historia serial equivalente ejecuta primero todas las operaciones de $T_1$ y luego las de $T_2$.

$H_1 \equiv H_S = r_1(A);w_1(A);r_1(B);w_1(B);r_2(A);w_2(A);r_2(B);w_2(B)$

>[!IMPORTANT]
>**Lectura entre transacciones**
>Dadas dos transacciones $T_i$ y $T_j$ decimos que $T_i$ lee $X$ de $T_j$ si $T_i$ lee $X$ y $T_j$ fue la última transacción que escribió $X$ y no abortó antes de que $T_i$ lo leyera. i.e.
>
>$$\begin{cases} w_j(X) < r_i(X) \iff T_j ~escribió~antes~el~elemento~que~lee~T_i \\a_j \nless r_i(X) \iff T_j~no~abortó \\(Si~existe~ w_k(X) / w_j(X) \lt w_k(X) \lt r_i(X) \implies a_k \lt r_i(X)) \iff T_j ~es~la~última ~que~escribió~ X ~y~no~abortó \end{cases}$$

>[!IMPORTANT]
>**Definiciones:**
>
> - *Historia recuperable* (**RC**): Si toda transacción $T_i$ que leyó de $T_j$ y commiteó, entonces $T_j$ commiteó antes. Es decir **solo commitea después de que todas de las que leyó lo hicieron**.
> - *Historia avoid cascading abort* (**ACA**): Siempre que una transacción $T_i$ lee de $T_j$, $T_j$ commiteó antes de la lectura. Es decir **solo leo de las que ya commitearon**.
> - *Historia strict* (**ST**): Una transacción **solo puede leer o escribir un item si la última que lo escribió ya commiteó o abortó**.

>[!IMPORTANT]
> **Teorema de la recuperabilidad:**
> ST $\subset$ ACA $\subset$ RC

>[!IMPORTANT]
>**Serializabilidad (*SR*)**
>Una historia es *serializable* si es conflicto equivalente a una historia serial.

## Ejercicio 1.2

> Dadas las siguientes historias (schedules):

### (a) Indicar para cada una si es NoRC, RC, ACA o ST.

Dado que si es **RC** será tanto **ACA** como **ST** conviene primero chequear si es **RC**.

$H_1 = r_1(X);r_4(Y);w_1(X);w_4(X);r_3(X);c_1;w_4(Y);w_3(Y);w_4(Z);c_4;w_3(X);c_3$

- Es **RC** $\iff$ todos commitean luego de aquellos de los que leen.
  - Hay solo 3 lecturas. Primero analizo esas.
    - $r_1(X)$ y $r_4(X)$ no imponen restricciones.
    - $r_3(X)$ significa que $T_3$ lee de $T_4$, por lo que $c_4 \lt c_3$. Lo cual se cumple.
  - $\therefore$ es **ST** $\subset$ **ACA** $\subset$ **RC**.

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
  - También vale vacuamente porque nadie lee de nadie. Por lo tanto es **RC**.
- Es **ST** $\iff$ nadie escribe y lee un item hasta que la última que lo escribió haya commiteado o abortado.
  - No se cumple pues en $w_1(X);w_4(Y);w_3(X)$ $T_3$ escribe $X$ y aún no había ni commiteado ni abortado $T_1$, por lo que es una transacción activa.
  - $\therefore$ No es **ST**.

### (b) Indicar cuáles podrían producir un *dirty read* o un *lost update*
