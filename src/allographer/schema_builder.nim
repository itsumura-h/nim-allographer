import ./env
import ./schema_builder/enums; export enums
import ./schema_builder/models/table; export table
import ./schema_builder/models/column; export column

when isExistsSqlite:
  import ./schema_builder/usecases/sqlite/create as sqlite_crate; export sqlite_crate
  import ./schema_builder/usecases/sqlite/alter as sqlite_alter; export sqlite_alter
  import ./schema_builder/usecases/sqlite/drop as sqlite_drop; export sqlite_drop

when isExistsPostgres:
  import ./schema_builder/usecases/postgres/create as postgres_crate; export postgres_crate
  import ./schema_builder/usecases/postgres/alter as postgres_alter; export postgres_alter
  import ./schema_builder/usecases/postgres/drop as postgres_drop; export postgres_drop

when isExistsMariadb:
  import ./schema_builder/usecases/mariadb/create as mariadb_crate; export mariadb_crate
  import ./schema_builder/usecases/mariadb/alter as mariadb_alter; export mariadb_alter
  import ./schema_builder/usecases/mariadb/drop as mariadb_drop; export mariadb_drop

when isExistsMysql:
  import ./schema_builder/usecases/mysql/create as mysql_crate; export mysql_crate
  import ./schema_builder/usecases/mysql/alter as mysql_alter; export mysql_alter
  import ./schema_builder/usecases/mysql/drop as mysql_drop; export mysql_drop

when isExistsSurrealdb:
  import ./schema_builder/usecases/surreal/create as surreal_crate; export surreal_crate
  import ./schema_builder/usecases/surreal/alter as surreal_alter; export surreal_alter
  import ./schema_builder/usecases/surreal/drop as surreal_drop; export surreal_drop

# import ./schema_builder/usecases/create; export create
# import ./schema_builder/usecases/alter; export alter
# import ./schema_builder/usecases/drop; export drop
