import ../../../query_builder/models/sqlite/sqlite_types
# import ../../../query_builder/surreal/surreal_types
import ../../queries/schema_interface
import ../../queries/sqlite/sqlite_query_type
import ../../queries/sqlite/sqlite_query_impl
# import ../../queries/postgres/postgres_query_type
# import ../../queries/postgres/postgres_query_impl
# import ../../queries/mysql/mysql_query_type
# import ../../queries/mysql/mysql_query_impl
# import ../../queries/surreal/surreal_query_type
# import ../../queries/surreal/surreal_query_impl
import ../../models/table
import ../../models/column


proc createSchema*(rdb:SqliteConnections, table:Table):ISchema =
  return SqliteSchema.new(rdb, table).toInterface()


proc createSchema*(rdb:SqliteConnections, table:Table, column:Column):ISchema =
  return SqliteSchema.new(rdb, table, column).toInterface()


# proc createSchema*(rdb:SurrealDb, table:Table):ISchema =
#   return SurrealQuery.new(rdb, table).toInterface()


# proc createSchema*(rdb:SurrealDb, table:Table, column:Column):ISchema =
#   return SurrealQuery.new(rdb, table, column).toInterface()
