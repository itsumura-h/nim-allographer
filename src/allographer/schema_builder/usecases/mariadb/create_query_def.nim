import ../../../env
import ../../queries/schema_interface
import ../../../query_builder/models/mariadb/mariadb_types
import ../../queries/mariadb/mariadb_query_type
import ../../queries/mariadb/mariadb_query_impl
import ../../models/table
import ../../models/column


proc createSchema*(rdb:MariadbConnections, table:Table):ISchema =
  when isExistsMariadb:
    return MariadbSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:MariadbConnections, table:Table, column:Column):ISchema =
  when isExistsMariadb:
    return MariadbSchema.new(rdb, table, column).toInterface()
