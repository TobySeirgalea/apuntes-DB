# Optimización

## Apuntes lectura *SQL Server execution plans 3rd edition*








### ¿Rol del *execution plan* en optimización de DB?

> *SQL Server execution plans 3rd edition*: "Neither is the execution plan the first place to look, if you need to tune performance on a production system. You'll check for misconfigurations of servers or database settings, you'll look for obvious points of resource contention on the server, which may be causing severe locking and blocking problems, and so on. At this point, if performance is still slow, you'll likely have narrowed the cause down to a few "hot" tables and one or two queries on those tables. Then, you can examine the plans and look for possible causes of the problem. However, execution plans are not necessarily designed to help the occasional user find the cause of a query problem quickly, in the heat of firefighting poor SQL Server performance. You need first to have invested time in learning the "language" of the plan and how to read it, and what led SQL Server to choose that plan, and those operators, to execute your query."