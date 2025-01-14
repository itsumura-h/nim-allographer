import std/json

type IntRelationTable* = object
  ## IntRelation
  id*: int


type StrRelationTable* = object
  ## StrRelation
  uuid*: string


type UserTable* = object
  ## user
  id*: string
  name*: string
  email*: string
  password*: string
  created_at*: int
  updated_at*: int


type PostTable* = object
  ## post
  id*: string
  title*: string
  content*: string
  user_id*: string
  created_at*: int
  updated_at*: int


type TypesTable* = object
  ## Types
  id*: int
  integer*: int
  smallInteger*: int
  mediumInteger*: int
  bigInteger*: int
  decimal*: float
  double*: float
  float*: float
  uuid*: string
  char*: string
  string*: string
  text*: string
  mediumText*: string
  longText*: string
  date*: string
  datetime*: string
  timestamp*: string
  created_at*: string
  updated_at*: string
  deleted_at*: string
  binary*: string
  boolean*: bool
  enumField*: string
  json*: JsonNode
  int_relation_id*: int
  str_relation_id*: string
