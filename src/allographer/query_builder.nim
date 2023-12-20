import ./env

when NimMajor == 2:
  import ./v2/query_builder/enums; export enums
  import ./v2/query_builder/error; export error
  
  when isExistsSqlite:
    import ./v2/query_builder/models/sqlite/sqlite_types; export sqlite_types
    import ./v2/query_builder/models/sqlite/sqlite_query; export sqlite_query
    import ./v2/query_builder/models/sqlite/sqlite_exec; export sqlite_exec
    import ./v2/query_builder/models/sqlite/sqlite_transaction; export sqlite_transaction

  when isExistsPostgres:
    import ./v2/query_builder/models/postgres/postgres_types; export postgres_types
    import ./v2/query_builder/models/postgres/postgres_query; export postgres_query
    import ./v2/query_builder/models/postgres/postgres_exec; export postgres_exec
    import ./v2/query_builder/models/postgres/poatgres_transaction; export poatgres_transaction

  when isExistsMariadb:
    import ./v2/query_builder/models/mariadb/mariadb_types; export mariadb_types
    import ./v2/query_builder/models/mariadb/mariadb_query; export mariadb_query
    import ./v2/query_builder/models/mariadb/mariadb_exec; export mariadb_exec
    import ./v2/query_builder/models/mariadb/mariadb_transaction; export mariadb_transaction

  when isExistsMysql:
    import ./v2/query_builder/models/mysql/mysql_types; export mysql_types
    import ./v2/query_builder/models/mysql/mysql_query; export mysql_query
    import ./v2/query_builder/models/mysql/mysql_exec; export mysql_exec
    import ./v2/query_builder/models/mysql/mysql_transaction; export mysql_transaction

  when isExistsSurrealdb:
    import ./v2/query_builder/models/surreal/surreal_types; export surreal_types
    import ./v2/query_builder/models/surreal/surreal_query; export surreal_query
    import ./v2/query_builder/models/surreal/surreal_exec; export surreal_exec
elif NimMajor == 1:
  import ./v1/query_builder/enums; export enums
  import ./v1/query_builder/error; export error

  when isExistsSqlite:
    import ./v1/query_builder/models/sqlite/sqlite_types; export sqlite_types
    import ./v1/query_builder/models/sqlite/sqlite_query; export sqlite_query
    import ./v1/query_builder/models/sqlite/sqlite_exec; export sqlite_exec
    import ./v1/query_builder/models/sqlite/sqlite_transaction; export sqlite_transaction

  when isExistsPostgres:
    import ./v1/query_builder/models/postgres/postgres_types; export postgres_types
    import ./v1/query_builder/models/postgres/postgres_query; export postgres_query
    import ./v1/query_builder/models/postgres/postgres_exec; export postgres_exec
    import ./v1/query_builder/models/postgres/poatgres_transaction; export poatgres_transaction

  when isExistsMariadb:
    import ./v1/query_builder/models/mariadb/mariadb_types; export mariadb_types
    import ./v1/query_builder/models/mariadb/mariadb_query; export mariadb_query
    import ./v1/query_builder/models/mariadb/mariadb_exec; export mariadb_exec
    import ./v1/query_builder/models/mariadb/mariadb_transaction; export mariadb_transaction

  when isExistsMysql:
    import ./v1/query_builder/models/mysql/mysql_types; export mysql_types
    import ./v1/query_builder/models/mysql/mysql_query; export mysql_query
    import ./v1/query_builder/models/mysql/mysql_exec; export mysql_exec
    import ./v1/query_builder/models/mysql/mysql_transaction; export mysql_transaction

  when isExistsSurrealdb:
    import ./v1/query_builder/models/surreal/surreal_types; export surreal_types
    import ./v1/query_builder/models/surreal/surreal_query; export surreal_query
    import ./v1/query_builder/models/surreal/surreal_exec; export surreal_exec
