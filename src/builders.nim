import json
from strformat import `&`
import generators


## ==================================================
## SELECT
## ==================================================

proc buildSelectSql*(queryArg: JsonNode): string =
  return selectSql(queryArg)
        .fromSql(queryArg)
        .joinSql(queryArg)
        .whereSql(queryArg)
        .orWhereSql(queryArg)
        .limitSql(queryArg)
        .offsetSql(queryArg)


## ==================================================
## INSERT
## ==================================================

proc insert*(queryArg: JsonNode, items: JsonNode): string =
  return insertSql(queryArg)
          .insertValuesSqlByJsonNode(items)


proc insert*(queryArg: JsonNode, rows: openArray[JsonNode]): string =
  return insertSql(queryArg)
          .insertMultiValuesSql(rows)


proc insertDifferentColumns*(queryArg: JsonNode, rows: openArray[JsonNode]): seq =
  var sqls = @[""]

  for items in rows:
    sqls.add(
      insertSql(queryArg)
      .insertValuesSqlByJsonNode(items)
    )

  sqls.delete(0)
  return sqls
## ==================================================
## UPDATE
## ==================================================

proc update*(queryArg: JsonNode, items: JsonNode): string =
  return updateSql(queryArg)
        .updateValuesSql(items)
        .joinSql(queryArg)
        .whereSql(queryArg)
        .orWhereSql(queryArg)
        .limitSql(queryArg)
        .offsetSql(queryArg)


## ==================================================
## DELETE
## ==================================================

proc delete*(queryArg: JsonNode): string =
  return deleteSql()
        .fromSql(queryArg)
        .joinSql(queryArg)
        .whereSql(queryArg)
        .orWhereSql(queryArg)
        .limitSql(queryArg)
        .offsetSql(queryArg)


proc delete*(queryArg: JsonNode, id: int): string =
  var queryString = deleteSql()
                    .fromSql(queryArg)

  queryString.add(&" WHERE id = {id}")
  return queryString


## ==================================================
## Aggregate
## ==================================================

proc generateCountSql*(queryArg: JsonNode): string =
  return selectCountSql(queryArg)
          .fromSql(queryArg)
          .joinSql(queryArg)
          .whereSql(queryArg)
          .orWhereSql(queryArg)
          .limitSql(queryArg)
          .offsetSql(queryArg)