import ../../../query_builder/rdb/rdb_types
import ../../../query_builder/surreal/surreal_types
import ../../queries/query_interface
# import ../../queries/sqlite/sqlite_query_type
# import ../../queries/sqlite/sqlite_query_impl
# import ../../queries/postgres/postgres_query_type
# import ../../queries/postgres/postgres_query_impl
# import ../../queries/mysql/mysql_query_type
# import ../../queries/mysql/mysql_query_impl
import ../../queries/surreal/surreal_query_type
import ../../queries/surreal/surreal_query_impl
import ../../models/table
import ../../models/column


# proc createQuery*(rdb:Rdb, table:Table):IQuery =
#   # return MysqlQuery.new(rdb, table).toInterface()
#   case rdb.driver
#   of SQLite3:
#     return SqliteQuery.new(rdb, table).toInterface()
#   of PostgreSQL:
#     return PostgresQuery.new(rdb, table).toInterface()
#   of MySQL, MariaDB:
#     return MysqlQuery.new(rdb, table).toInterface()


# proc createQuery*(rdb:Rdb, table:Table, column:Column):IQuery =
#   # return MysqlQuery.new(rdb, table, column).toInterface()
#   case rdb.driver
#   of SQLite3:
#     return SqliteQuery.new(rdb, table, column).toInterface()
#   of PostgreSQL:
#     return PostgresQuery.new(rdb, table, column).toInterface()
#   of MySQL, MariaDB:
#     return MysqlQuery.new(rdb, table, column).toInterface()


proc createQuery*(rdb:SurrealDb, table:Table):IQuery =
  return SurrealQuery.new(rdb, table).toInterface()


proc createQuery*(rdb:SurrealDb, table:Table, column:Column):IQuery =
  return SurrealQuery.new(rdb, table, column).toInterface()
