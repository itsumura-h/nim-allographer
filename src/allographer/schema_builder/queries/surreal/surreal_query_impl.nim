import ../query_interface
import ./surreal_query_type
import ./create_migration_table
import ./create_table
import ./reset_table
import ./add_column
import ./change_column
import ./rename_column
import ./drop_column
import ./rename_table
import ./drop_table


proc toInterface*(self:SurrealQuery):IQuery =
  return (
    createMigrationTable:proc() = self.createMigrationTable(),
    createTable:proc(isReset:bool) = self.createTable(isReset),
    resetMigrationTable:proc() = self.resetMigrationTable(),
    resetTable:proc() = self.resetTable(),
    addColumn:proc(isReset:bool) = self.addColumn(isReset),
    changeColumn:proc(isReset:bool) = self.changeColumn(isReset),
    renameColumn:proc(isReset:bool) = self.renameColumn(isReset),
    dropColumn:proc(isReset:bool) = self.dropColumn(isReset),
    renameTable:proc(isReset:bool) = self.renameTable(isReset),
    dropTable:proc(isReset:bool) = self.dropTable(isReset)
  )
