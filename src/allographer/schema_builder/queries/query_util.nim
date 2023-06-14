import std/strformat
from std/db_common import DbError

proc notAllowed*(option, typ, column:string) =
  raise newException(DbError, &"{option} is not allowed in {typ} column {column}")
