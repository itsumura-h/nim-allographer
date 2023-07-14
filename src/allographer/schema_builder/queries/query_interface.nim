type IQuery* = tuple
  createMigrationTable:proc()
  createTable:proc(isReset:bool)
  resetMigrationTable:proc()
  resetTable:proc()
  # addColumn:proc(isReset:bool)
  # changeColumn:proc(isReset:bool)
  # renameColumn:proc(isReset:bool)
  # dropColumn:proc(isReset:bool)
  # dropTable:proc(isReset:bool)
