import ./env

when NimMajor == 2:
  import ./v2/schema_builder/enums; export enums
  import ./v2/schema_builder/models/table; export table
  import ./v2/schema_builder/models/column; export column

  when isExistsSqlite:
    import ./v2/query_builder/models/sqlite/sqlite_types; export SQLite3, SqliteConnections
    import ./v2/schema_builder/usecases/sqlite/create as sqlite_create; export sqlite_create
    import ./v2/schema_builder/usecases/sqlite/alter as sqlite_alter; export sqlite_alter
    import ./v2/schema_builder/usecases/sqlite/drop as sqlite_drop; export sqlite_drop
    import ./v2/schema_builder/usecases/sqlite/create_schema as sqlite_create_schema; export sqlite_create_schema

  when isExistsPostgres:
    import ./v2/query_builder/models/postgres/postgres_types; export PostgreSQL, PostgresConnections
    import ./v2/schema_builder/usecases/postgres/create as postgres_create; export postgres_create
    import ./v2/schema_builder/usecases/postgres/alter as postgres_alter; export postgres_alter
    import ./v2/schema_builder/usecases/postgres/drop as postgres_drop; export postgres_drop
    import ./v2/schema_builder/usecases/postgres/create_schema as postgres_create_schema; export postgres_create_schema

  when isExistsMariadb:
    import ./v2/query_builder/models/mariadb/mariadb_types; export MariaDB, MariadbConnections
    import ./v2/schema_builder/usecases/mariadb/create as mariadb_create; export mariadb_create
    import ./v2/schema_builder/usecases/mariadb/alter as mariadb_alter; export mariadb_alter
    import ./v2/schema_builder/usecases/mariadb/drop as mariadb_drop; export mariadb_drop
    import ./v2/schema_builder/usecases/mariadb/create_schema as mariadb_create_schema; export mariadb_create_schema

  when isExistsMysql:
    import ./v2/query_builder/models/mysql/mysql_types; export MySql, MysqlConnections
    import ./v2/schema_builder/usecases/mysql/create as mysql_create; export mysql_create
    import ./v2/schema_builder/usecases/mysql/alter as mysql_alter; export mysql_alter
    import ./v2/schema_builder/usecases/mysql/drop as mysql_drop; export mysql_drop
    import ./v2/schema_builder/usecases/mysql/create_schema as mysql_create_schema; export mysql_create_schema

  when isExistsSurrealdb:
    import ./v2/query_builder/models/surreal/surreal_types; export SurrealDB, SurrealConnections
    import ./v2/schema_builder/usecases/surreal/create as surreal_create; export surreal_create
    import ./v2/schema_builder/usecases/surreal/alter as surreal_alter; export surreal_alter
    import ./v2/schema_builder/usecases/surreal/drop as surreal_drop; export surreal_drop
    import ./v2/schema_builder/usecases/surreal/create_schema as surreal_create_schema; export surreal_create_schema
elif NimMajor == 1:
  import ./v1/schema_builder/enums; export enums
  import ./v1/schema_builder/models/table; export table
  import ./v1/schema_builder/models/column; export column

  when isExistsSqlite:
    import ./v1/query_builder/models/sqlite/sqlite_types; export SQLite3, SqliteConnections
    import ./v1/schema_builder/usecases/sqlite/create as sqlite_create; export sqlite_create
    import ./v1/schema_builder/usecases/sqlite/alter as sqlite_alter; export sqlite_alter
    import ./v1/schema_builder/usecases/sqlite/drop as sqlite_drop; export sqlite_drop

  when isExistsPostgres:
    import ./v1/query_builder/models/postgres/postgres_types; export PostgreSQL, PostgresConnections
    import ./v1/schema_builder/usecases/postgres/create as postgres_create; export postgres_create
    import ./v1/schema_builder/usecases/postgres/alter as postgres_alter; export postgres_alter
    import ./v1/schema_builder/usecases/postgres/drop as postgres_drop; export postgres_drop

  when isExistsMariadb:
    import ./v1/query_builder/models/mariadb/mariadb_types; export MariaDB, MariadbConnections
    import ./v1/schema_builder/usecases/mariadb/create as mariadb_create; export mariadb_create
    import ./v1/schema_builder/usecases/mariadb/alter as mariadb_alter; export mariadb_alter
    import ./v1/schema_builder/usecases/mariadb/drop as mariadb_drop; export mariadb_drop

  when isExistsMysql:
    import ./v1/query_builder/models/mysql/mysql_types; export MySql, MysqlConnections
    import ./v1/schema_builder/usecases/mysql/create as mysql_create; export mysql_create
    import ./v1/schema_builder/usecases/mysql/alter as mysql_alter; export mysql_alter
    import ./v1/schema_builder/usecases/mysql/drop as mysql_drop; export mysql_drop

  when isExistsSurrealdb:
    import ./v1/query_builder/models/surreal/surreal_types; export SurrealDB, SurrealConnections
    import ./v1/schema_builder/usecases/surreal/create as surreal_create; export surreal_create
    import ./v1/schema_builder/usecases/surreal/alter as surreal_alter; export surreal_alter
    import ./v1/schema_builder/usecases/surreal/drop as surreal_drop; export surreal_drop


# ==================================================

# import ./v2/schema_builder/enums; export enums
# import ./v2/schema_builder/models/table; export table
# import ./v2/schema_builder/models/column; export column

# when isExistsSqlite:
#   import ./v2/query_builder/models/sqlite/sqlite_types; export SQLite3, SqliteConnections
#   import ./v2/schema_builder/usecases/sqlite/create as sqlite_create; export sqlite_create
#   import ./v2/schema_builder/usecases/sqlite/alter as sqlite_alter; export sqlite_alter
#   import ./v2/schema_builder/usecases/sqlite/drop as sqlite_drop; export sqlite_drop
#   import ./v2/schema_builder/usecases/sqlite/create_schema as sqlite_create_schema; export sqlite_create_schema

# when isExistsPostgres:
#   import ./v2/query_builder/models/postgres/postgres_types; export PostgreSQL, PostgresConnections
#   import ./v2/schema_builder/usecases/postgres/create as postgres_create; export postgres_create
#   import ./v2/schema_builder/usecases/postgres/alter as postgres_alter; export postgres_alter
#   import ./v2/schema_builder/usecases/postgres/drop as postgres_drop; export postgres_drop
#   import ./v2/schema_builder/usecases/postgres/create_schema as postgres_create_schema; export postgres_create_schema

# when isExistsMariadb:
#   import ./v2/query_builder/models/mariadb/mariadb_types; export MariaDB, MariadbConnections
#   import ./v2/schema_builder/usecases/mariadb/create as mariadb_create; export mariadb_create
#   import ./v2/schema_builder/usecases/mariadb/alter as mariadb_alter; export mariadb_alter
#   import ./v2/schema_builder/usecases/mariadb/drop as mariadb_drop; export mariadb_drop
#   import ./v2/schema_builder/usecases/mariadb/create_schema as mariadb_create_schema; export mariadb_create_schema

# when isExistsMysql:
#   import ./v2/query_builder/models/mysql/mysql_types; export MySql, MysqlConnections
#   import ./v2/schema_builder/usecases/mysql/create as mysql_create; export mysql_create
#   import ./v2/schema_builder/usecases/mysql/alter as mysql_alter; export mysql_alter
#   import ./v2/schema_builder/usecases/mysql/drop as mysql_drop; export mysql_drop
#   import ./v2/schema_builder/usecases/mysql/create_schema as mysql_create_schema; export mysql_create_schema

# when isExistsSurrealdb:
#   import ./v2/query_builder/models/surreal/surreal_types; export SurrealDB, SurrealConnections
#   import ./v2/schema_builder/usecases/surreal/create as surreal_create; export surreal_create
#   import ./v2/schema_builder/usecases/surreal/alter as surreal_alter; export surreal_alter
#   import ./v2/schema_builder/usecases/surreal/drop as surreal_drop; export surreal_drop
#   import ./v2/schema_builder/usecases/surreal/create_schema as surreal_create_schema; export surreal_create_schema
