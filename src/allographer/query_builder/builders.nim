import
  std/json,
  ../base,
  ./generators


# ==================== SELECT ====================

proc selectBuilder*(self: Rdb): string =
  return self
    .selectSql()
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
    .sqlString

proc selectFirstBuilder*(self: Rdb): string =
  return self
    .selectSql()
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
    .sqlString

proc selectFindBuilder*(self: Rdb, key: string): string =
  return self
    .selectSql()
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
    .sqlString


# ==================== INSERT ====================

proc insertValueBuilder*(self: Rdb, items: JsonNode): string =
  return self
    .insertSql()
    .insertValueSql(items)
    .sqlString

proc insertValuesBuilder*(self: Rdb, rows: openArray[JsonNode]): string =
  return self
    .insertSql()
    .insertValuesSql(rows)
    .sqlString


# ==================== UPDATE ====================

proc updateBuilder*(self: Rdb, items: JsonNode): string =
  return self
    .updateSql()
    .updateValuesSql(items)
    .whereSql()
    .orWhereSql()
    .limitSql()
    .offsetSql()
    .sqlString


# ==================== DELETE ====================

proc deleteBuilder*(self: Rdb): string =
  return self
    .deleteSql()
    .fromSql()
    .joinSql()
    .leftJoinSql()
    .whereSql()
    .orWhereSql()
    .limitSql()
    .offsetSql()
    .sqlString

proc deleteByIdBuilder*(self: Rdb, id: int, key: string): string =
  return self
    .deleteSql()
    .fromSql()
    .deleteByIdSql(id, key)
    .sqlString


# ==================== Aggregates ====================

proc countBuilder*(self:Rdb): string =
  return self
    .selectCountSql()
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
    .sqlString

proc maxBuilder*(self:Rdb, column:string): string =
  return self
    .selectMaxSql(column)
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
    .sqlString

proc minBuilder*(self:Rdb, column:string): string =
  return self
    .selectMinSql(column)
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
    .sqlString

proc avgBuilder*(self:Rdb, column:string): string =
  return self
    .selectAvgSql(column)
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
    .sqlString

proc sumBuilder*(self:Rdb, column:string): string =
  return self
    .selectSumSql(column)
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
    .sqlString

proc columnBuilder*(self:Rdb): string =
  return self
    .selectSql()
    .fromSql()
    .selectFirstSql()
    .sqlString
