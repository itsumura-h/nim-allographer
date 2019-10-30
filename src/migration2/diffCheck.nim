import json
import schema, table, column

type DiffCheck* = ref object
export DiffCheck


proc generateJsonSchema(this:DiffCheck, tablesArg:varargs[Table]) =
  var tables = %*[]
  for table in tablesArg:

    var columns = %*[]
    for column in table.columns:
      columns.add(%*{
        "name": column.name,
        "typ": column.typ,
        "isNullable": column.isNullable,
        "isUnsigned": column.isUnsigned,
        "isDefault": column.isDefault,
        "defaultBool": column.defaultBool,
        "defaultInt": column.defaultInt,
        "defaultFloat": column.defaultFloat,
        "defaultString": column.defaultString,
        "foreignOnDelete": column.foreignOnDelete,
        "info": if column.info != nil: $column.info else: ""
      })

    tables.add(
      %*{"name": table.name, "columns": columns}
    )

  block:
    let f = open("tmp.json", FileMode.fmAppend)
    f.write(tables.pretty())
    defer:
      f.close()

proc generateMigrateTable(this:DiffCheck) =
  try:
    Schema().create([
      Table().create("migrations", [
        Column().increments("id"),
        Column().json("schema")
      ])
    ])
  except:
    echo getCurrentExceptionMsg()


proc check*(this:DiffCheck, tablesArg:varargs[Table]) =
  this.generateJsonSchema(tablesArg)
  this.generateMigrateTable()