import std/strformat
from std/db_common import DbError

proc notAllowedOption*(option, typ, column:string) =
  ## {option} is not allowed in {typ} column {column}
  raise newException(DbError, &"{option} is not allowed in {typ} column {column}")

proc notAllowedTypeInChange*(typ:string) =
  ## Change to {typ} type is not allowed
  raise newException(DbError, &"Change to {typ} type is not allowed")
