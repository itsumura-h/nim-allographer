import db_common, json

type 
  Model* = ref object
    name*: string
    columns*: seq[Column]

  Column* = ref object
    name*: string
    typ*: DbTypeKind
    isNullable*: bool
    isUnsigned*: bool
    isDefault*: bool
    defaultBool*: bool
    defaultInt*: int
    defaultFloat*: float
    defaultString*: string
    info*: JsonNode
