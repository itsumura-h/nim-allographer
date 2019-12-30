import json

import base, generators


# ==================== SELECT ====================

proc selectBuilder*(this: RDB): RDB =
  return this.selectSql()
        .fromSql()
        .joinSql()
        .leftJoinSql()
        .whereSql()
        .orWhereSql()
        .whereBetweenSql()
        .whereNotBetweenSql()
        .whereInSql()
        .whereNotInSql()
        .whereNullSql()
        .groupBySql()
        .havingSql()
        .orderBySql()
        .limitSql()
        .offsetSql()

proc selectFirstBuilder*(this: RDB): RDB =
  return this.selectSql()
        .fromSql()
        .joinSql()
        .whereSql()
        .orWhereSql()
        .whereBetweenSql()
        .whereNotBetweenSql()
        .whereInSql()
        .whereNotInSql()
        .whereNullSql()
        .groupBySql()
        .havingSql()
        .orderBySql()
        .selectFirstSql()
        .offsetSql()

proc selectFindBuilder*(this: RDB, id: int, key: string): RDB =
  return this.selectSql()
        .fromSql()
        .selectByIdSql(id, key)


# ==================== INSERT ====================

proc insertValueBuilder*(this: RDB, items: JsonNode): RDB =
  return this.insertSql()
        .insertValueSql(items)

proc insertValuesBuilder*(this: RDB, rows: openArray[JsonNode]): RDB =
  return this.insertSql()
        .insertValuesSql(rows)


# ==================== UPDATE ====================

proc updateBuilder*(this: RDB, items: JsonNode): RDB =
  return this.updateSql()
        .updateValuesSql(items)
        .joinSql()
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()


# ==================== DELETE ====================

proc deleteBuilder*(this: RDB): RDB =
  return this.deleteSql()
        .fromSql()
        .joinSql()
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()

proc deleteByIdBuilder*(this: RDB, id: int, key: string): RDB =
  return this.deleteSql()
        .fromSql()
        .deleteByIdSql(id, key)


# ==================== Aggregates ====================

proc countBuilder*(this:RDB): RDB =
  return this.selectCountSql()
    .fromSql()
    .joinSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    .whereNotBetweenSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    .havingSql()
    .orderBySql()
    .limitSql()
    .offsetSql()

proc maxBuilder*(this:RDB, column:string): RDB =
  return this.selectMaxSql(column)
    .fromSql()
    .joinSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    .whereNotBetweenSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    .havingSql()
    .orderBySql()
    .limitSql()
    .offsetSql()

proc minBuilder*(this:RDB, column:string): RDB =
  return this.selectMinSql(column)
    .fromSql()
    .joinSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    .whereNotBetweenSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    .havingSql()
    .orderBySql()
    .limitSql()
    .offsetSql()

proc avgBuilder*(this:RDB, column:string): RDB =
  return this.selectAvgSql(column)
    .fromSql()
    .joinSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    .whereNotBetweenSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    .havingSql()
    .orderBySql()
    .limitSql()
    .offsetSql()

proc sumBuilder*(this:RDB, column:string): RDB =
  return this.selectSumSql(column)
    .fromSql()
    .joinSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    .whereNotBetweenSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    .havingSql()
    .orderBySql()
    .limitSql()
    .offsetSql()