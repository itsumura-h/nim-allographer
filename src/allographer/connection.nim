import ./env

when NimMajor == 2:
  when isExistsSqlite:
    import ./v2/query_builder/models/sqlite/sqlite_types; export SQLite3
    import ./v2/query_builder/models/sqlite/sqlite_open; export sqlite_open

  when isExistsPostgres:
    import ./v2/query_builder/models/postgres/postgres_types; export PostgreSQL
    import ./v2/query_builder/models/postgres/postgres_open; export postgres_open

  when isExistsMariadb:
    import ./v2/query_builder/models/mariadb/mariadb_types; export MariaDB
    import ./v2/query_builder/models/mariadb/mariadb_open; export mariadb_open

  when isExistsMysql:
    import ./v2/query_builder/models/mysql/mysql_types; export MySql
    import ./v2/query_builder/models/mysql/mysql_open; export mysql_open

  when isExistsSurrealdb:
    import ./v2/query_builder/models/surreal/surreal_types; export SurrealDB
    import ./v2/query_builder/models/surreal/surreal_open; export surreal_open
elif NimMajor == 1:
  when isExistsSqlite:
    import ./v1/query_builder/models/sqlite/sqlite_types; export SQLite3
    import ./v1/query_builder/models/sqlite/sqlite_open; export sqlite_open

  when isExistsPostgres:
    import ./v1/query_builder/models/postgres/postgres_types; export PostgreSQL
    import ./v1/query_builder/models/postgres/postgres_open; export postgres_open

  when isExistsMariadb:
    import ./v1/query_builder/models/mariadb/mariadb_types; export MariaDB
    import ./v1/query_builder/models/mariadb/mariadb_open; export mariadb_open

  when isExistsMysql:
    import ./v1/query_builder/models/mysql/mysql_types; export MySql
    import ./v1/query_builder/models/mysql/mysql_open; export mysql_open

  when isExistsSurrealdb:
    import ./v1/query_builder/models/surreal/surreal_types; export SurrealDB
    import ./v1/query_builder/models/surreal/surreal_open; export surreal_open
else:
  discard
