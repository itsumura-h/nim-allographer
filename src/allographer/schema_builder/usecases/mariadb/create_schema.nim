import std/asyncdispatch
import std/strutils
import std/strformat
import std/json
import std/tables
import std/re
import std/os
import ../../../utils/snake_to_camel
import ../../../query_builder/models/mariadb/mariadb_types
import ../../../query_builder/models/mariadb/mariadb_query
import ../../../query_builder/models/mariadb/mariadb_exec


proc getTableInfo(rdb: MariaDBConnections): Future[Table[string, seq[tuple[name: string, typ: string]]]] {.async.} =
  ## get table info
  var tablesInfo = initTable[string, seq[tuple[name: string, typ: string]]]()

  # get table list
  let tables = await rdb.raw(
    "SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE()"
  ).get()
  
  for table in tables:
    let tableName = table["table_name"].getStr()

    if tableName == "_allographer_migrations":
      continue
    
    # get column info
    let query = 
      """SELECT column_name, data_type 
          FROM information_schema.columns 
          WHERE table_name = ? 
          AND table_schema = DATABASE()
          ORDER BY ordinal_position
      """
      .replace(re"\s{2,}", " ")
    
    let columns = rdb.raw(query, %*[tableName]).get().await
    
    var columnInfo: seq[tuple[name: string, typ: string]]
    for col in columns:
      columnInfo.add((
        name: col["column_name"].getStr(),
        typ: col["data_type"].getStr()
      ))
    
    tablesInfo[tableName] = columnInfo

  return tablesInfo

proc generateSchemaCode(tablesInfo: Table[string, seq[tuple[name: string, typ: string]]]): string =
  ## generate schema.nim code
  var code = "import std/json"
  
  for tableName, columns in tablesInfo.pairs:
    let tableNameCamel = tableName.snakeToCamel()
    code.add("\n\n")
    code.add(&"type {tableNameCamel}Table* = object\n")
    code.add(&"  ## {tableName}\n")
    for col in columns:
      let nimType = 
        case col.typ.toLower()
        of "tinyint":
          "bool"
        of "smallint", "mediumint", "int", "bigint":
          "int"
        of "char", "varchar", "tinytext", "text", "mediumtext", "longtext", "blob", "enum", "date", "datetime", "time", "timestamp":
          "string"
        of "float", "double", "decimal":
          "float"
        of "json":
          "JsonNode"
        else:
          "string" # default
      code.add &"  {col.name}*: {nimType}\n"

  return code

proc createSchema*(rdb: MariaDBConnections, schemaPath="") {.async.} =
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
