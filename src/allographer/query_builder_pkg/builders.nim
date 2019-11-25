import json

import base, generators


# ===================== SELECT ====================

proc selectBuilder*(this: RDB): RDB =
  return this.selectSql()
        .fromSql()
        .joinSql()
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()

proc selectFindBuilder*(this: RDB, id: int): RDB =
  return this.selectSql()
        .fromSql()
        .selectByIdSql(id)


# ===================== INSERT ====================

proc insertValueBuilder*(this: RDB, items: JsonNode): RDB =
  return this.insertSql()
        .insertValueSql(items)

proc insertValuesBuilder*(this: RDB, rows: openArray[JsonNode]): RDB =
  return this.insertSql()
        .insertValuesSql(rows)


# ===================== UPDATE ====================

proc updateBuilder*(this: RDB, items: JsonNode): RDB =
  return this.updateSql()
        .updateValuesSql(items)
        .joinSql()
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()


# ===================== DELETE ====================

proc deleteBuilder*(this: RDB): RDB =
  return this.deleteSql()
        .fromSql()
        .joinSql()
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()

proc deleteByIdBuilder*(this: RDB, id: int): RDB =
  return this.deleteSql()
        .fromSql()
        .deleteByIdSql(id)
