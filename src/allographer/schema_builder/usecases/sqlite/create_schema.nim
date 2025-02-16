import std/asyncdispatch
import std/strutils
import std/strformat
import std/json
import std/tables
import std/os
import ../../../utils/snake_to_camel
import ../../../query_builder/models/sqlite/sqlite_types
import ../../../query_builder/models/sqlite/sqlite_query
import ../../../query_builder/models/sqlite/sqlite_exec

proc getTableInfo(rdb: SqliteConnections): Future[Table[string, seq[tuple[name: string, typ: string]]]] {.async.} =
  ## get table info
  var tablesInfo = initTable[string, seq[tuple[name: string, typ: string]]]()
  
  try:
    # get table list
    let tables = await rdb.raw(
      "SELECT name as table_name FROM sqlite_master WHERE type = 'table'"
    ).get()
    
    for table in tables:
      let tableName = table["table_name"].getStr()
      
      # get column info
      let columns = rdb.raw("PRAGMA table_info(?)", %*[tableName])
        .get()
        .await
      
      var columnInfo: seq[tuple[name: string, typ: string]]
      for col in columns:
        columnInfo.add((
          name: col["name"].getStr(),
          typ: col["type"].getStr()
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
    if tableName == "sqlite_sequence":
      continue

    let tableNameCamel = tableName.snakeToCamel()
    code.add("\n\n")
    code.add(&"type {tableNameCamel}Table* = object\n")
    code.add(&"  ## {tableName}\n")
    for col in columns:
      let nimType = 
        case col.typ.toLower()
        of "integer":
          "int"
        of "varchar", "text", "blob", "date", "datetime", "time":
          "string"
        of "tinyint":
          "bool"
        of "numeric", "real":
          "float"
        of "json":
          "JsonNode"
        else:
          "string" # default
      code.add &"  {col.name}*: {nimType}\n"

  return code

proc createSchema*(rdb: SqliteConnections, schemaPath="") {.async.} =
  ## if schemaPath is not specified, the schema will be generated in the current directory
  ## 
  ## Default schema file name is `getCurrentDir() / "schema.nim"`
  try:
    let tablesInfo = await rdb.getTableInfo()
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
