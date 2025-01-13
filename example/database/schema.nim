import std/json

type IntRelation* = object
  ## IntRelation
  id*: int


type StrRelation* = object
  ## StrRelation
  uuid*: string


type User* = object
  ## user
  id*: string
  name*: string
  email*: string
  password*: string
  created_at*: int
  updated_at*: int


type Post* = object
  ## post
  id*: string
  title*: string
  content*: string
  user_id*: string
  created_at*: int
  updated_at*: int


type Types* = object
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
  time*: string
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
