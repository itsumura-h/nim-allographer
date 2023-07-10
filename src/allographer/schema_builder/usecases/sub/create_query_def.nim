import ../../../query_builder/rdb/rdb_types
import ../../queries/query_interface
import ../../queries/sqlite/sqlite_query_type
import ../../queries/sqlite/sqlite_query_impl
import ../../queries/postgres/postgres_query_type
import ../../queries/postgres/postgres_query_impl
import ../../queries/mysql/mysql_query_type
import ../../queries/mysql/mysql_query_impl
import ../../models/table
import ../../models/column


proc createQuery*(rdb:Rdb, table:Table):IQuery =
  case rdb.driver
  of SQLite3:
    return SqliteQuery.new(rdb, table).toInterface()
  of PostgreSQL:
    return PostgresQuery.new(rdb, table).toInterface()
  of MySQL, MariaDB:
    return MysqlQuery.new(rdb, table).toInterface()


proc createQuery*(rdb:Rdb, table:Table, column:Column):IQuery =
  case rdb.driver
  of SQLite3:
    return SqliteQuery.new(rdb, table, column).toInterface()
  of PostgreSQL:
    return PostgresQuery.new(rdb, table, column).toInterface()
  of MySQL, MariaDB:
    return MysqlQuery.new(rdb, table, column).toInterface()
