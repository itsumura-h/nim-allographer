import std/json
import std/strutils
import std/sequtils
import ../enums
from ./column import Column, toSchema


type Table* = ref object
  name*: string
  columns*: seq[Column]
  primary*: seq[string]
  query*:seq[string]
  checksum*:string
  previousName*:string
  migrationType*: TableMigrationType
  usecaseType*:UsecaseType


proc table*(name:string, columns:varargs[Column]):Table =
  return Table(
    name: name,
    columns: @columns,
    query: newSeq[string](),
    migrationType: CreateTable
  )

proc table*(name:string, columns:seq[Column], primary:seq[string] = @[]):Table =
  return Table(
    name: name,
    columns: @columns,
    primary: @primary,
    query: newSeq[string](),
    migrationType: CreateTable
  )


proc toSchema*(self:Table):JsonNode =
  let columns = self.columns.map(
    proc(column:Column):JsonNode =
      return column.toSchema()
  )
  return %*{
    "name":self.name,
    "columns": columns,
    "primary": self.primary,
    "previousName": self.previousName,
    "migrationType": self.migrationType,
    "usecaseType": self.usecaseType
  }

proc smallName*(self:Table):string =
  ## TableName -> tablename
  return self.name.toLowerAscii()

proc renameTo*(self:Table, name:string):Table =
  let previousName = self.name
  self.name = name
  self.previousName = previousName
  self.migrationType = RenameTable
  return self
