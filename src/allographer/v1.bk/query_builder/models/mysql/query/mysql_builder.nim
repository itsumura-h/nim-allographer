import std/json
import ../mysql_types
import ./mysql_generator


# ==================== SELECT ====================

proc selectBuilder*(self: MysqlQuery): string =
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
    .queryString

proc selectFirstBuilder*(self: MysqlQuery): string =
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
    .queryString

proc selectFindBuilder*(self: MysqlQuery, key: string): string =
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
    .queryString


# ==================== INSERT ====================

proc insertValueBuilder*(self: MysqlQuery, items: JsonNode): string =
  return self
    .insertSql()
    .insertValueSql(items)
    .queryString

proc insertValuesBuilder*(self: MysqlQuery, rows: openArray[JsonNode]): string =
  return self
    .insertSql()
    .insertValuesSql(rows)
    .queryString


# ==================== UPDATE ====================

proc updateBuilder*(self: MysqlQuery, items: JsonNode): string =
  return self
    .updateSql()
    .updateValuesSql(items)
    .whereSql()
    .orWhereSql()
    .limitSql()
    .offsetSql()
    .queryString


# ==================== DELETE ====================

proc deleteBuilder*(self: MysqlQuery): string =
  return self
    .deleteSql()
    .fromSql()
    .joinSql()
    .leftJoinSql()
    .whereSql()
    .orWhereSql()
    .limitSql()
    .offsetSql()
    .queryString

proc deleteByIdBuilder*(self: MysqlQuery, id: int, key: string): string =
  return self
    .deleteSql()
    .fromSql()
    .deleteByIdSql(id, key)
    .queryString


# ==================== Aggregates ====================

proc countBuilder*(self:MysqlQuery): string =
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
    .queryString

proc maxBuilder*(self:MysqlQuery, column:string): string =
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
    .queryString

proc minBuilder*(self:MysqlQuery, column:string): string =
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
    .queryString

proc avgBuilder*(self:MysqlQuery, column:string): string =
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
    .queryString

proc sumBuilder*(self:MysqlQuery, column:string): string =
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
    .queryString

proc columnBuilder*(self:MysqlQuery): string =
  return self
    .selectSql()
    .fromSql()
    .selectFirstSql()
    .queryString
