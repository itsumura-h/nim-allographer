import db_sqlite, db_mysql, db_postgres, json
from strformat import `&`
from strutils import parseInt
import builders
import generators


## ==================================================
## SELECT
## ==================================================

proc getSqlCheck*(queryArg: JsonNode): string =
  return buildSelectSql(queryArg)


proc get*(queryArg: JsonNode, db: proc): seq =
  let queryString = buildSelectSql(queryArg)

  try:
    echo queryString
    var queryResult = db().getAllRows(sql queryString)
    result = queryResult
  except:
    result = @[]

  db().close()


proc first*(queryArg: JsonNode, db: proc): seq =
  let queryString = buildSelectSql(queryArg)

  try:
    echo queryString
    result = db().getRow(sql queryString)
  except:
    result = @[]

  db().close()


proc find*(queryArg: JsonNode, id: int, db: proc): seq =
  var queryString = selectSql(queryArg)
                    .fromSql(queryArg)

  queryString.add(&" WHERE id = {$id}")

  try:
    echo queryString
    result = db().getRow(sql queryString)
  except:
    result = @[""]
  
  db().close()


## ==================================================
## exec
## ==================================================

proc exec*(sqlStringArg: string, db: proc) =
  echo sqlStringArg
  db().exec(sql sqlStringArg)
  db().close()


proc exec*(sqlStringArrayArg: openArray[string], db: proc) =
  for sqlString in sqlStringArrayArg:
    echo sqlString
    db().exec(sql sqlString)
  db().close()


## ==================================================
## Aggregate
## ==================================================

proc count*(queryArg: JsonNode, db: proc): int =
  var queryString = generateCountSql(queryArg)

  try:
    echo queryString
    result = db().getValue(sql queryString).parseInt()
  except:
    result = 0

  db().close()

proc countColumns*(queryArg: JsonNode, db: proc): seq =
  var queryString = generateCountSql(queryArg)

  try:
    echo queryString
    result = db().getRow(sql queryString)
  except:
    result = @[""]

  db().close()