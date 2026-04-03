import ./env

import ./query_builder/libs/database_url
export DatabaseUrl, DatabaseUrlQuery, ParsedDatabaseUrl, asDatabaseUrl, parseDatabaseUrl, databaseName, sqliteDatabasePath, portOrDefault, requireDatabaseUrlScheme

when isExistsSqlite:
  import ./query_builder/models/sqlite/sqlite_types; export SQLite3, SqliteConnections, SqlitePreparedContext
  import ./query_builder/models/sqlite/sqlite_open; export sqlite_open

when isExistsPostgres:
  import ./query_builder/models/postgres/postgres_types; export PostgreSQL, PostgresConnections, PostgresPreparedContext
  import ./query_builder/models/postgres/postgres_open; export postgres_open

when isExistsMariadb:
  import ./query_builder/models/mariadb/mariadb_types; export MariaDB, MariadbConnections, MariadbPreparedContext
  import ./query_builder/models/mariadb/mariadb_open; export mariadb_open

when isExistsMysql:
  import ./query_builder/models/mysql/mysql_types; export MySql, MysqlConnections, MysqlPreparedContext
  import ./query_builder/models/mysql/mysql_open; export mysql_open

when isExistsSurrealdb:
  import ./query_builder/models/surreal/surreal_types; export SurrealDB, SurrealConnections, SurrealPreparedContext
  import ./query_builder/models/surreal/surreal_open; export surreal_open
