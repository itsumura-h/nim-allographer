import strformat
from db_common import DbError

proc notAllowed*(option, typ, column:string) =
  raise newException(DbError, &"{option} is not allowed in {typ} column {column}")
