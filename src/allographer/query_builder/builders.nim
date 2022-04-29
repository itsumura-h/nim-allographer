import json

import ../base, generators


# ==================== SELECT ====================

proc selectBuilder*(self: Rdb): Rdb =
  return self.selectSql()
        .fromSql()
        .joinSql()
        .leftJoinSql()
        .whereSql()
        .orWhereSql()
        .whereBetweenSql()
        .whereBetweenStringSql()
        .whereNotBetweenSql()
        .whereNotBetweenStringSql()
        .whereInSql()
        .whereNotInSql()
        .whereNullSql()
        .groupBySql()
        .havingSql()
        .orderBySql()
        .limitSql()
        .offsetSql()

proc selectFirstBuilder*(self: Rdb): Rdb =
  return self.selectSql()
        .fromSql()
        .joinSql()
        .leftJoinSql()
        .whereSql()
        .orWhereSql()
        .whereBetweenSql()
        .whereBetweenStringSql()
        .whereNotBetweenSql()
        .whereNotBetweenStringSql()
        .whereInSql()
        .whereNotInSql()
        .whereNullSql()
        .groupBySql()
        .havingSql()
        .orderBySql()
        .selectFirstSql()
        .offsetSql()

proc selectFindBuilder*(self: Rdb, key: string): Rdb =
  return self.selectSql()
        .fromSql()
        .joinSql()
        .leftJoinSql()
        .whereSql()
        .orWhereSql()
        .whereBetweenSql()
        .whereBetweenStringSql()
        .whereNotBetweenSql()
        .whereNotBetweenStringSql()
        .whereInSql()
        .whereNotInSql()
        .whereNullSql()
        .selectByIdSql(key)


# ==================== INSERT ====================

proc insertValueBuilder*(self: Rdb, items: JsonNode): Rdb =
  return self.insertSql()
        .insertValueSql(items)

proc insertValuesBuilder*(self: Rdb, rows: openArray[JsonNode]): Rdb =
  return self.insertSql()
        .insertValuesSql(rows)


# ==================== UPDATE ====================

proc updateBuilder*(self: Rdb, items: JsonNode): Rdb =
  return self.updateSql()
        .updateValuesSql(items)
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()


# ==================== DELETE ====================

proc deleteBuilder*(self: Rdb): Rdb =
  return self.deleteSql()
        .fromSql()
        .joinSql()
        .leftJoinSql()
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()

proc deleteByIdBuilder*(self: Rdb, id: int, key: string): Rdb =
  return self.deleteSql()
        .fromSql()
        .deleteByIdSql(id, key)


# ==================== Aggregates ====================

proc countBuilder*(self:Rdb): Rdb =
  return self.selectCountSql()
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

proc maxBuilder*(self:Rdb, column:string): Rdb =
  return self.selectMaxSql(column)
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

proc minBuilder*(self:Rdb, column:string): Rdb =
  return self.selectMinSql(column)
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

proc avgBuilder*(self:Rdb, column:string): Rdb =
  return self.selectAvgSql(column)
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

proc sumBuilder*(self:Rdb, column:string): Rdb =
  return self.selectSumSql(column)
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

proc columnBuilder*(self:Rdb):Rdb =
  return self.selectSql()
        .fromSql()
        .selectFirstSql()
