import json

import base, generators


# ==================== SELECT ====================

proc selectBuilder*(this: Rdb): Rdb =
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

proc selectFirstBuilder*(this: Rdb): Rdb =
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
        .selectFirstSql()
        .offsetSql()

proc selectFindBuilder*(this: Rdb, id: int, key: string): Rdb =
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
        .selectByIdSql(id, key)


# ==================== INSERT ====================

proc insertValueBuilder*(this: Rdb, items: JsonNode): Rdb =
  return this.insertSql()
        .insertValueSql(items)

proc insertValuesBuilder*(this: Rdb, rows: openArray[JsonNode]): Rdb =
  return this.insertSql()
        .insertValuesSql(rows)


# ==================== UPDATE ====================

proc updateBuilder*(this: Rdb, items: JsonNode): Rdb =
  return this.updateSql()
        .updateValuesSql(items)
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()


# ==================== DELETE ====================

proc deleteBuilder*(this: Rdb): Rdb =
  return this.deleteSql()
        .fromSql()
        .joinSql()
        .leftJoinSql()
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()

proc deleteByIdBuilder*(this: Rdb, id: int, key: string): Rdb =
  return this.deleteSql()
        .fromSql()
        .deleteByIdSql(id, key)


# ==================== Aggregates ====================

proc countBuilder*(this:Rdb): Rdb =
  return this.selectCountSql()
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

proc maxBuilder*(this:Rdb, column:string): Rdb =
  return this.selectMaxSql(column)
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

proc minBuilder*(this:Rdb, column:string): Rdb =
  return this.selectMinSql(column)
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

proc avgBuilder*(this:Rdb, column:string): Rdb =
  return this.selectAvgSql(column)
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

proc sumBuilder*(this:Rdb, column:string): Rdb =
  return this.selectSumSql(column)
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