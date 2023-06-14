import std/json
import ../enums
from ./column import Column


type Table* = ref object
  name*: string
  columns*: seq[Column]
  schema*: JsonNode
  query*:seq[string]
  checksum*:string
  migrationType*: TableMigrationType
  previousName*:string


proc createTable(name:string, columns:varargs[Column]):JsonNode =
  let jsonColumns = newJArray()
  for column in columns:
    let jsonSchema = %*{
      "name": column.name,
      "typ": column.typ,
      "isIndex": column.isIndex,
      "isNullable": column.isNullable,
      "isUnsigned": column.isUnsigned,
      "isUnique": column.isUnique,
      "isDefault": column.isDefault,
      "defaultBool": column.defaultBool,
      "defaultInt": column.defaultInt,
      "defaultFloat": column.defaultFloat,
      "defaultString": column.defaultString,
      "defaultJson": column.defaultJson,
      "foreignOnDelete": column.foreignOnDelete,
      "info": column.info
    }
    column.schema = jsonSchema
    jsonColumns.add(jsonSchema)
  return jsonColumns


proc table*(name:string, columns:varargs[Column]):Table =
  let jsonColumns = createTable(name, columns)
  return Table(
    name: name,
    columns: @columns,
    schema: jsonColumns,
    query: newSeq[string](),
    migrationType: CreateTable
  )
