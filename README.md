# labs_databases

Лабораторные работы по базам данных (PostgreSQL).

| Работа | Файл | Содержание |
| --- | --- | --- |
| 1 | [lab1/lab1_solutions.md](lab1/lab1_solutions.md) | Ключи, ER-диаграммы, нормализация, схема клубов |
| 2 | [lab2/lab2_advanced_ddl.sql](lab2/lab2_advanced_ddl.sql) | Базы, табличные пространства, таблицы, `ALTER`, удаление |
| 3 | [lab3/lab3_advanced_dml.sql](lab3/lab3_advanced_dml.sql) | `INSERT`, `UPDATE`, `DELETE`, `NULL`, `RETURNING` |
| 4 | [lab4/lab4_queries.sql](lab4/lab4_queries.sql) | Запросы, функции, агрегаты, множества, подзапросы |

Условия заданий лежат в [`labs/`](labs/).

## Как запустить SQL

Нужен PostgreSQL и `psql`. Скрипты рассчитаны на суперпользователя: лабораторная 2 создаёт базы и табличные пространства.

Перед лабораторной 2 на сервере должны быть пустые каталоги, принадлежащие пользователю ОС, от которого работает PostgreSQL:

```bash
mkdir -p /data/students /data/courses
chown postgres:postgres /data/students /data/courses
```

Дальше из корня репозитория:

```bash
psql -U postgres -f lab2/lab2_advanced_ddl.sql
psql -U postgres -f lab3/lab3_advanced_dml.sql
psql -U postgres -f lab4/lab4_queries.sql
```

Лабораторная 2 в конце удаляет `university_test` и `university_distributed` и создаёт `university_backup` как копию `university_main`. Повторный запуск упадёт на `CREATE DATABASE`, если эти базы уже есть: скрипт рассчитан на чистый кластер.
