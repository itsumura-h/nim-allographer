import json

type
  Model* = ref object
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
    info*: JsonNode

  RdbTypekind* = enum
    # int
    rdbIncrements,
    rdbInteger,
    rdbSmallInteger,
    rdbMediumInteger,
    rdbBigInteger,
    # float
    rdbDecimal,
    rdbDouble,
    rdbFloat,
    # char
    rdbChar,
    rdbString,
    # text
    rdbText,
    rdbMediumText,
    rdbLongText,
    # date
    rdbDate,
    rdbDatetime,
    rdbTime,
    rdbTimestamp,
    rdbTimestamps,
    rdbSoftDelete,
    # others
    rdbBinary,
    rdbBoolean,
    rdbEnumField,
    rdbJson,
    rdbForeign
