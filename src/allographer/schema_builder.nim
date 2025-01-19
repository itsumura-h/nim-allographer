import ./env


import ./schema_builder/enums; export enums
import ./schema_builder/models/table; export table
import ./schema_builder/models/column; export column

when isExistsSqlite:
  import ./query_builder/models/sqlite/sqlite_types; export SQLite3, SqliteConnections
  import ./schema_builder/usecases/sqlite/create as sqlite_create; export sqlite_create
  import ./schema_builder/usecases/sqlite/alter as sqlite_alter; export sqlite_alter
  import ./schema_builder/usecases/sqlite/drop as sqlite_drop; export sqlite_drop
  import ./schema_builder/usecases/sqlite/create_schema as sqlite_create_schema; export sqlite_create_schema

when isExistsPostgres:
  import ./query_builder/models/postgres/postgres_types; export PostgreSQL, PostgresConnections
  import ./schema_builder/usecases/postgres/create as postgres_create; export postgres_create
  import ./schema_builder/usecases/postgres/alter as postgres_alter; export postgres_alter
  import ./schema_builder/usecases/postgres/drop as postgres_drop; export postgres_drop
  import ./schema_builder/usecases/postgres/create_schema as postgres_create_schema; export postgres_create_schema

when isExistsMariadb:
  import ./query_builder/models/mariadb/mariadb_types; export MariaDB, MariadbConnections
  import ./schema_builder/usecases/mariadb/create as mariadb_create; export mariadb_create
  import ./schema_builder/usecases/mariadb/alter as mariadb_alter; export mariadb_alter
  import ./schema_builder/usecases/mariadb/drop as mariadb_drop; export mariadb_drop
  import ./schema_builder/usecases/mariadb/create_schema as mariadb_create_schema; export mariadb_create_schema

when isExistsMysql:
  import ./query_builder/models/mysql/mysql_types; export MySql, MysqlConnections
  import ./schema_builder/usecases/mysql/create as mysql_create; export mysql_create
  import ./schema_builder/usecases/mysql/alter as mysql_alter; export mysql_alter
  import ./schema_builder/usecases/mysql/drop as mysql_drop; export mysql_drop
  import ./schema_builder/usecases/mysql/create_schema as mysql_create_schema; export mysql_create_schema

when isExistsSurrealdb:
  import ./query_builder/models/surreal/surreal_types; export SurrealDB, SurrealConnections
  import ./schema_builder/usecases/surreal/create as surreal_create; export surreal_create
  import ./schema_builder/usecases/surreal/alter as surreal_alter; export surreal_alter
  import ./schema_builder/usecases/surreal/drop as surreal_drop; export surreal_drop
  import ./schema_builder/usecases/surreal/create_schema as surreal_create_schema; export surreal_create_schema
