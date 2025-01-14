import std/json

type IntRelation* = object
  ## IntRelation
  id*: int


type StrRelation* = object
  ## StrRelation
  uuid*: string


type User* = object
  ## user
  created_at*: int
  email*: string
  id*: string
  name*: string
  password*: string
  updated_at*: int


type Types* = object
  ## Types
  bigInteger*: int
  binary*: string
  boolean*: bool
  char*: string
  created_at*: string
  date*: string
  datetime*: string
  decimal*: float
  deleted_at*: string
  double*: float
  enumField*: string
  float*: float
  id*: int
  int_relation_id*: string
  integer*: int
  json*: JsonNode
  longText*: string
  mediumInteger*: int
  mediumText*: string
  smallInteger*: int
  str_relation_id*: string
  string*: string
  text*: string
  timestamp*: string
  updated_at*: string
  uuid*: string


type Post* = object
  ## post
  content*: string
  created_at*: int
  id*: string
  title*: string
  updated_at*: int
  user_id*: string
