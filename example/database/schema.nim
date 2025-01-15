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


type AuthTable* = object
  ## auth
  id*: int
  auth*: string


type TypeUniqueTable* = object
  ## TypeUnique
  num*: int
  str*: string


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
  time*: string
  timestamp*: string
  created_at*: string
  updated_at*: string
  deleted_at*: string
  binary*: string
  boolean*: bool
  enumField*: string
  json*: string
  int_relation_id*: int
  str_relation_id*: string


type PostTable* = object
  ## post
  id*: string
  title*: string
  content*: string
  user_id*: string
  created_at*: int
  updated_at*: int


type TypeIndexTable* = object
  ## TypeIndex
  index1*: int
  index2*: int
  string*: string
  relation_id*: int


type RelationTable* = object
  ## relation
  id*: int
