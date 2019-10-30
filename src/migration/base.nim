import json

type
  Schema* = ref object
    tables*: seq[Table]

  Table* = ref object
    name*: string
    columns*: seq[Column]

  Column* = ref object
    name*: string
    typ*: RdbTypekind
    isNullable*: bool
    isUnsigned*: bool
    isDefault*: bool
    defaultBool*: bool
    defaultInt*: int
    defaultFloat*: float
    defaultString*: string
    foreignOnDelete*: ForeignOnDelete
    info*: JsonNode

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

  ForeignOnDelete* = enum
    RESTRICT = "RESTRICT"
    CASCADE = "CASCADE"
    SET_NULL = "SET_NULL"
    NO_ACTION = "NO_ACTION"