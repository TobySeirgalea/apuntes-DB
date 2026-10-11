# Práctica NoSQL

## Modelado

### Ejercicio 2

En este modelo cada grupo tiene una lista con las claves (idUsuario) de sus miembros y cada usuario tiene una lista con las claves (idGrupo) a los que pertenece.

![Ejercicio 1 a](./images/ej1a.drawio.svg)

En este modelo cada grupo guarda una lista con las claves (idUsuario) de sus miembros y cada usuario tiene un documento incrustado con la información del grupo al que pertenece.

![Ejercicio 1 b](./images/ej1b.drawio.svg)

En este modelo cada usuario tiene un documento incrustado con la información de su grupo, pero no nos permite dado un grupo obtener sus miembros.

![Ejercicio 1 c](./images/ej1c.drawio.svg)

### Ejercicio 3