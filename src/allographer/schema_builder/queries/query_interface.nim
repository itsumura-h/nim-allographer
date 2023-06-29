import std/json
import ../../query_builder/rdb/rdb_types
import ../models/column
import ../models/table

type IQuery* = tuple
  createMigrationTable:proc()
  createTable:proc(isReset:bool)
  resetMigrationTable:proc()
  resetTable:proc()
  addColumn:proc(isReset:bool)
  changeColumn:proc(isReset:bool)
  renameColumn:proc(isReset:bool)
  deleteColumn:proc(isReset:bool)
  dropTable:proc(isReset:bool)
