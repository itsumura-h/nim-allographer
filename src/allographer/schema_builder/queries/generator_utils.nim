import strformat
when (NimMajor, NimMinor) <= (1, 6):
  from db_common import DbError
else:
  from db_connector/db_common import DbError

proc notAllowed*(option, typ, column:string) =
  raise newException(DbError, &"{option} is not allowed in {typ} column {column}")
