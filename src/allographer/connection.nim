import ./env

when NimMajor == 2:
  when isExistsSqlite:
    import ./v2/query_builder/models/sqlite/sqlite_types; export SQLite3, SqliteConnections
    import ./v2/query_builder/models/sqlite/sqlite_open; export sqlite_open

  when isExistsPostgres:
    import ./v2/query_builder/models/postgres/postgres_types; export PostgreSQL, PostgresConnections
    import ./v2/query_builder/models/postgres/postgres_open; export postgres_open

  when isExistsMariadb:
    import ./v2/query_builder/models/mariadb/mariadb_types; export MariaDB, MariadbConnections
    import ./v2/query_builder/models/mariadb/mariadb_open; export mariadb_open

  when isExistsMysql:
    import ./v2/query_builder/models/mysql/mysql_types; export MySql, MysqlConnections
    import ./v2/query_builder/models/mysql/mysql_open; export mysql_open

  when isExistsSurrealdb:
    import ./v2/query_builder/models/surreal/surreal_types; export SurrealDB, SurrealConnections
    import ./v2/query_builder/models/surreal/surreal_open; export surreal_open
elif NimMajor == 1:
  when isExistsSqlite:
    import ./v1/query_builder/models/sqlite/sqlite_types; export SQLite3, SqliteConnections
    import ./v1/query_builder/models/sqlite/sqlite_open; export sqlite_open

  when isExistsPostgres:
    import ./v1/query_builder/models/postgres/postgres_types; export PostgreSQL, PostgresConnections
    import ./v1/query_builder/models/postgres/postgres_open; export postgres_open

  when isExistsMariadb:
    import ./v1/query_builder/models/mariadb/mariadb_types; export MariaDB, MariadbConnections
    import ./v1/query_builder/models/mariadb/mariadb_open; export mariadb_open

  when isExistsMysql:
    import ./v1/query_builder/models/mysql/mysql_types; export MySql, MysqlConnections
    import ./v1/query_builder/models/mysql/mysql_open; export mysql_open

  when isExistsSurrealdb:
    import ./v1/query_builder/models/surreal/surreal_types; export SurrealDB, SurrealConnections
    import ./v1/query_builder/models/surreal/surreal_open; export surreal_open
else:
  discard
