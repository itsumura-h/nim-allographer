import ../query_interface
import ./postgres_query_type
import ./create_migration_table
import ./create_table
import ./reset_table
import ./add_column


proc toInterface*(self:PostgresService):IQuery =
  return (
    createMigrationTable:proc() = self.createMigrationTable(),
    createTable:proc(isReset:bool) = self.createTable(isReset),
    resetMigrationTable:proc() = self.resetMigrationTable(),
    resetTable:proc() = self.resetTable(),
    addColumn:proc(isReset:bool) = self.addColumn(isReset)
  )
