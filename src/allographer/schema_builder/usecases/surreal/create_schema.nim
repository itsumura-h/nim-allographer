import std/asyncdispatch
import std/strutils
import std/strformat
import std/json
import std/tables
import std/os
import ../../../utils/snake_to_camel
import ../../../query_builder/models/surreal/surreal_types
import ../../../query_builder/models/surreal/surreal_query
import ../../../query_builder/models/surreal/surreal_exec


proc getTableInfo(rdb: SurrealConnections): Future[Table[string, seq[tuple[name: string, typ: string]]]] {.async.} =
  ## get table info from SurrealDB
  var tablesInfo = initTable[string, seq[tuple[name: string, typ: string]]]()
  
  try:
    # Get all tables using SurrealDB's INFO statement
    let dbResponse = rdb.raw("INFO FOR DB").info().await
    let dbInfo = dbResponse[0]["result"]["tb"].getFields()
    var tables:seq[string]
    for key, _ in dbInfo.pairs:
      if key == "_allographer_migrations":
        continue
      if key == "_autoincrement_sequences":
        continue
      tables.add(key)

    for tableName in tables:
      # Get field definitions for each table
      let tableResponse = rdb.raw(&"INFO FOR TABLE {tableName}").info().await
      let fields = tableResponse[0]["result"]["fd"].getFields()

      var columnInfo: seq[tuple[name: string, typ: string]]
      for fieldName, fieldDef in fields.pairs:
        columnInfo.add((
          name: fieldName,
          typ: fieldDef.getStr().split(" ")[6]
        ))

      tablesInfo[tableName] = columnInfo
  
  except Exception as e:
    echo "Error fetching table info: ", e.msg
    raise

  return tablesInfo


proc generateSchemaCode(tablesInfo: Table[string, seq[tuple[name: string, typ: string]]]): string =
  ## generate schema.nim code
  var code = "import std/json"
  
  for tableName, columns in tablesInfo.pairs:
    if tableName == "_allographer_migrations":
      continue

    let tableNameCamel = tableName.snakeToCamel()
    code.add("\n\n")
    code.add(&"type {tableNameCamel}Table* = object\n")
    code .add(&"  ## {tableName}\n")
    for col in columns:
      let nimType = 
        case col.typ.toLower()
        of "int":
          "int"
        of "string", "datetime":
          "string"
        of "bool":
          "bool"
        of "decimal", "float":
          "float"
        of "type":
          "JsonNode"
        else:
          "string" # default
      code.add &"  {col.name}*: {nimType}\n"

  return code


proc createSchema*(rdb: SurrealConnections, schemaPath="") {.async.} =
  ## if schemaPath is not specified, the schema will be generated in the current directory
  ## 
  ## Default schema file name is `getCurrentDir() / "schema.nim"`
  try:
    let tablesInfo = rdb.getTableInfo().await
    let schemaCode = generateSchemaCode(tablesInfo)

    let schemaFilePath =
      if schemaPath == "":
        getCurrentDir() / "schema.nim"
      else:
        schemaPath
    
    writeFile(schemaFilePath, schemaCode)
    echo "schema generated successfully in ", schemaFilePath
  except Exception as e:
    echo "Error generating schema: ", e.msg
    raise
