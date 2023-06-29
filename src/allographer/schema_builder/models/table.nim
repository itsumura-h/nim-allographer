import std/json
import std/sequtils
import ../enums
from ./column import Column, toSchema


type Table* = ref object
  name*: string
  columns*: seq[Column]
  query*:seq[string]
  checksum*:string
  previousName*:string
  migrationType*: TableMigrationType
  usecaseType*:UsecaseType


proc toSchema*(self:Table):JsonNode =
  let columns = self.columns.map(
    proc(column:Column):JsonNode =
      return column.toSchema()
  )
  return %*{
    "name":self.name,
    "columns": columns,
    "previousName": self.previousName,
    "migrationType": self.migrationType,
    "usecaseType": self.usecaseType
  }

# proc createTable(name:string, columns:varargs[Column]):JsonNode =
#   for column in columns:
#     let jsonSchema = %*{
#       "name": column.name,
#       "typ": column.typ,
#       "isIndex": column.isIndex,
#       "isNullable": column.isNullable,
#       "isUnsigned": column.isUnsigned,
#       "isUnique": column.isUnique,
#       "isDefault": column.isDefault,
#       "defaultBool": column.defaultBool,
#       "defaultInt": column.defaultInt,
#       "defaultFloat": column.defaultFloat,
#       "defaultString": column.defaultString,
#       "defaultJson": column.defaultJson,
#       "foreignOnDelete": column.foreignOnDelete,
#       "info": column.info
#     }
#     column.schema = jsonSchema
#     jsonColumns.add(jsonSchema)
#   return jsonColumns


proc table*(name:string, columns:varargs[Column]):Table =
  # let jsonColumns = createTable(name, columns)
  return Table(
    name: name,
    columns: @columns,
    query: newSeq[string](),
    migrationType: CreateTable
  )
