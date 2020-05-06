import strformat
import ../table
import ../migrates/sqlite_migrate

proc generate*(table:Table):seq =
  echo "======================="
  # echo table.repr
  var sql = newSeq[string](table.columns.len)
  # var columnString = ""
  for i, column in table.columns:
    # if i > 0: columnString.add(", ")
    # columnString.add(
    #   generateColumnString(column)
    # )
    var columnString = generateColumnString(column)
    sql.add(&"ALTER TABLE {table.name} ADD COLUMN {columnString}\n")
  return sql