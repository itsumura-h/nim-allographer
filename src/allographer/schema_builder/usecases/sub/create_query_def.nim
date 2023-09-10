import ../../queries/schema_interface

import ../../../query_builder/models/sqlite/sqlite_types
import ../../queries/sqlite/sqlite_query_type
import ../../queries/sqlite/sqlite_query_impl

import ../../../query_builder/models/postgres/postgres_types
import ../../queries/postgres/postgres_query_type
import ../../queries/postgres/postgres_query_impl

import ../../../query_builder/models/mariadb/mariadb_types
import ../../queries/mariadb/mariadb_query_type
import ../../queries/mariadb/mariadb_query_impl

import ../../../query_builder/models/mysql/mysql_types
import ../../queries/mysql/mysql_query_type
import ../../queries/mysql/mysql_query_impl

import ../../../query_builder/models/surreal/surreal_types
import ../../queries/surreal/surreal_query_type
import ../../queries/surreal/surreal_query_impl

import ../../models/table
import ../../models/column


proc createSchema*(rdb:SqliteConnections, table:Table):ISchema =
  return SqliteSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:SqliteConnections, table:Table, column:Column):ISchema =
  return SqliteSchema.new(rdb, table, column).toInterface()


proc createSchema*(rdb:PostgresConnections, table:Table):ISchema =
  return PostgresSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:PostgresConnections, table:Table, column:Column):ISchema =
  return PostgresSchema.new(rdb, table, column).toInterface()


proc createSchema*(rdb:MariadbConnections, table:Table):ISchema =
  return MariadbSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:MariadbConnections, table:Table, column:Column):ISchema =
  return MariadbSchema.new(rdb, table, column).toInterface()


proc createSchema*(rdb:MysqlConnections, table:Table):ISchema =
  return MysqlSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:MysqlConnections, table:Table, column:Column):ISchema =
  return MysqlSchema.new(rdb, table, column).toInterface()


proc createSchema*(rdb:SurrealConnections, table:Table):ISchema =
  return SurrealSchema.new(rdb, table).toInterface()


proc createSchema*(rdb:SurrealConnections, table:Table, column:Column):ISchema =
  return SurrealSchema.new(rdb, table, column).toInterface()
