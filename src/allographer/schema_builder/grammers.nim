import json, strutils

type
  Table* = ref object
    name*: string
    columns*: seq[Column]
    construction*: JsonNode
    query*: string
    checksum*:string
    migrationType*: TableMigrationType
    previousName*:string

  Column* = ref object
    name*: string
    typ*: RdbTypekind
    isIndex*: bool
    isNullable*: bool
    isUnsigned*: bool
    isUnique*: bool
    isDefault*: bool
    defaultBool*: bool
    defaultInt*: int
    defaultFloat*: float
    defaultString*: string
    defaultJson*: JsonNode
    foreignOnDelete*: ForeignOnDelete
    info*: JsonNode
    query*: string
    checksum*:string
    construction*:JsonNode
    # alter table
    migrationType*:ColumnMigrationType
    previousName*:string

  RdbTypekind* = enum
    # int
    rdbIncrements = "rdbIncrements"
    rdbInteger = "rdbInteger"
    rdbSmallInteger = "rdbSmallInteger"
    rdbMediumInteger = "rdbMediumInteger"
    rdbBigInteger = "rdbBigInteger"
    # float
    rdbDecimal = "rdbDecimal"
    rdbDouble = "rdbDouble"
    rdbFloat = "rdbFloat"
    # char
    rdbUuid = "rdbUuid"
    rdbChar = "rdbChar"
    rdbString = "rdbString"
    # text
    rdbText = "rdbText"
    rdbMediumText = "rdbMediumText"
    rdbLongText = "rdbLongText"
    # date
    rdbDate = "rdbDate"
    rdbDatetime = "rdbDatetime"
    rdbTime = "rdbTime"
    rdbTimestamp = "rdbTimestamp"
    rdbTimestamps = "rdbTimestamps"
    rdbSoftDelete = "rdbSoftDelete"
    # others
    rdbBinary = "rdbBinary"
    rdbBoolean = "rdbBoolean"
    rdbEnumField = "rdbEnumField"
    rdbJson = "rdbJson"
    rdbForeign = "rdbForeign"
    rdbStrForeign = "rdbStrForeign"

  ForeignOnDelete* = enum
    RESTRICT
    CASCADE
    SET_NULL
    NO_ACTION

  TableMigrationType* = enum
    CreateTable
    ChangeTable
    RenameTable
    DropTable

  ColumnMigrationType* = enum
    AddColumn
    ChangeColumn
    RenameColumn
    DeleteColumn


proc newColumn():Column =
  return Column(
    defaultJson: newJNull(),
    info: newJNull(),
    construction: newJNull()
  )

proc new(_:type Column, jsonColumn:JsonNode):Column =
  let defaultJson =
    if jsonColumn["defaultJson"].kind == JNull:
      newJNull()
    else:
      jsonColumn["defaultJson"].getStr.parseJson

  let column = newColumn()
  column.name = jsonColumn["name"].getStr
  column.typ = parseEnum[RdbTypekind](jsonColumn["typ"].getStr)
  column.isIndex = jsonColumn["isIndex"].getBool
  column.isNullable = jsonColumn["isNullable"].getBool
  column.isUnsigned = jsonColumn["isUnsigned"].getBool
  column.isUnique = jsonColumn["isUnique"].getBool
  column.isDefault = jsonColumn["isDefault"].getBool
  column.defaultBool = jsonColumn["defaultBool"].getBool
  column.defaultInt = jsonColumn["defaultInt"].getInt
  column.defaultFloat = jsonColumn["defaultFloat"].getFloat
  column.defaultString = jsonColumn["defaultString"].getStr
  column.defaultJson = defaultJson
  column.foreignOnDelete = parseEnum[ForeignOnDelete](jsonColumn["foreignOnDelete"].getStr)
  return column

proc createTable(name:string, columns:varargs[Column]):JsonNode =
  let jsonColumns = newJArray()
  for column in columns:
    let jsonConstruction = %*{
      "name": column.name,
      "typ": column.typ,
      "isIndex": column.isIndex,
      "isNullable": column.isNullable,
      "isUnsigned": column.isUnsigned,
      "isDefault": column.isDefault,
      "isUnique": column.isUnique,
      "defaultBool": column.defaultBool,
      "defaultInt": column.defaultInt,
      "defaultFloat": column.defaultFloat,
      "defaultString": column.defaultString,
      "defaultJson": column.defaultJson,
      "foreignOnDelete": column.foreignOnDelete,
      "info": column.info
    }
    column.construction = jsonConstruction
    jsonColumns.add(jsonConstruction)
  return jsonColumns

proc table*(name:string, columns:varargs[Column]):Table =
  let jsonColumns = createTable(name, columns)
  return Table(
    name: name,
    columns: @columns,
    construction: jsonColumns,
    query: "",
    migrationType: CreateTable
  )

proc rename*(src, dest:string):Table =
  return Table(
    name: dest,
    columns: newSeq[Column](),
    construction: newJObject(),
    query: "",
    migrationType: RenameTable,
    previousName: src
  )

proc drop*(name:string):Table =
  return Table(
    name: name,
    columns: newSeq[Column](),
    construction: newJObject(),
    query: "",
    migrationType: DropTable,
  )

proc new*(_:type Table, jsonTable:JsonNode):Table =
  var columns:seq[Column]
  for jsonColumns in jsonTable["construction"].getStr.parseJson:
    columns.add(Column.new(jsonColumns) )
  return table(jsonTable["name"].getStr, columns)


# =============================================================================
# int
# =============================================================================
proc increments*(_:type Column, name:string): Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbIncrements
  return column

proc integer*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbInteger
  return column

proc smallInteger*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbSmallInteger
  return column


proc mediumInteger*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbMediumInteger
  return column

proc bigInteger*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbBigInteger
  return column

# =============================================================================
# float
# =============================================================================
proc decimal*(_:type Column, name:string, maximum:int, digit:int): Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbDecimal
  column.info = %*{
    "maximum": maximum,
    "digit": digit
  }
  return column


proc double*(_:type Column, name:string, maximum:int, digit:int):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbDouble
  column.info = %*{
    "maximum": maximum,
    "digit": digit
  }
  return column

proc float*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbFloat
  return column

# =============================================================================
# char
# =============================================================================
proc char*(_:type Column, name:string, maxLength:int): Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbChar
  column.info = %*{
    "maxLength": maxLength
  }
  return column

proc string*(_:type Column, name:string, length=255):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbString
  column.info = %*{"maxLength": length}
  return column

proc uuid*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbUuid
  column.isUnique = true
  column.isIndex = true
  column.info = %*{"maxLength": 255}
  return column

proc text*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbText
  return column

proc mediumText*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbMediumText
  return column

proc longText*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbLongText
  return column

# =============================================================================
# date
# =============================================================================
proc date*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbDate
  return column

proc datetime*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbDatetime
  return column

proc time*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbTime
  return column

proc timestamp*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbTimestamp
  return column

proc timestamps*(_:type Column):Column =
  let column = newColumn()
  column.typ = rdbTimestamps
  return column

proc softDelete*(_:type Column):Column =
  let column = newColumn()
  column.typ = rdbSoftDelete
  return column

# =============================================================================
# others
# =============================================================================
proc binary*(_:type Column, name:string): Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbBinary
  return column

proc boolean*(_:type Column, name:string): Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbBoolean
  return column

proc enumField*(_:type Column, name:string, options:openArray[string]):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbEnumField
  column.info = %*{
    "options": options
  }
  return column

proc json*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.typ = rdbJson
  return column

# =============================================================================
# Foreign
# =============================================================================
proc foreign*(_:type Column, name:string):Column =
  let column = newColumn()
  column.name = name
  column.previousName = name
  column.typ = rdbForeign
  column.isIndex = true
  return column

proc strForeign*(_:type Column, name:string, length=255):Column =
  let column = newColumn()
  column.name = name
  column.previousName = name
  column.typ = rdbStrForeign
  column.isIndex = true
  column.info = %*{"maxLength": length}
  return column

proc reference*(self:Column, column:string):Column =
  if self.info.kind == JNull:
    self.info = %*{"column": column}
  else:
    self.info["column"] = %column
  return self

proc on*(self:Column, table:string):Column =
  self.info["table"] = %*table
  return self

proc onDelete*(self:Column, kind:ForeignOnDelete):Column =
  self.foreignOnDelete = kind
  return self

# =============================================================================
# options
# =============================================================================
proc default*(c: Column, value:bool): Column =
  c.isDefault = true
  c.defaultBool = value
  return c

proc default*(c: Column, value:int): Column =
  c.isDefault = true
  c.defaultInt = value
  return c

proc default*(c: Column, value:float): Column =
  c.isDefault = true
  c.defaultFloat = value
  return c

proc default*(c: Column, value:string): Column =
  c.isDefault = true
  c.defaultString = value
  return c

proc default*(c: Column, value:JsonNode): Column =
  c.isDefault = true
  c.defaultJson = value
  return c

proc default*(c: Column):Column =
  c.isDefault = true
  return c

proc index*(c: Column):Column =
  c.isIndex = true
  return c

proc nullable*(c: Column): Column =
  c.isNullable = true
  return c

proc unique*(c: Column): Column =
  c.isUnique = true
  return c

proc unsigned*(c: Column): Column =
  c.isUnsigned = true
  return c

# =============================================================================
# alter table
# =============================================================================
proc add*(c: Column): Column =
  c.migrationType = AddColumn
  return c

proc change*(c: Column): Column =
  c.migrationType = ChangeColumn
  return c

proc renameColumn*(_:type Column, src, dest:string): Column =
  let column = newColumn()
  column.name = dest  
  column.previousName = src
  column.migrationType = RenameColumn
  return column

proc deleteColumn*(_:type Column, name:string): Column =
  let column = newColumn()
  column.name = name
  column.migrationType = DeleteColumn
  return column
