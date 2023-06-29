type RdbTypeKind* = enum
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

type ForeignOnDelete* = enum
  RESTRICT
  CASCADE
  SET_NULL
  NO_ACTION

type UsecaseType* = enum
  Create
  Alter
  Drop

type TableMigrationType* = enum
    CreateTable
    ChangeTable
    RenameTable
    DropTable

type ColumnMigrationType* = enum
    AddColumn
    ChangeColumn
    RenameColumn
    DeleteColumn
