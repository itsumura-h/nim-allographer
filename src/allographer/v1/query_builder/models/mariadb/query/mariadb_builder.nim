import std/json
import ../mariadb_types
import ./mariadb_generator


# ==================== SELECT ====================

proc selectBuilder*(self: MariadbQuery): string =
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

proc selectFirstBuilder*(self: MariadbQuery): string =
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

proc selectFindBuilder*(self: MariadbQuery, key: string): string =
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

proc insertValueBuilder*(self: MariadbQuery, items: JsonNode): string =
  return self
    .insertSql()
    .insertValueSql(items)
    .queryString

proc insertValuesBuilder*(self: MariadbQuery, rows: openArray[JsonNode]): string =
  return self
    .insertSql()
    .insertValuesSql(rows)
    .queryString


# ==================== UPDATE ====================

proc updateBuilder*(self: MariadbQuery, items: JsonNode): string =
  return self
    .updateSql()
    .updateValuesSql(items)
    .whereSql()
    .orWhereSql()
    .limitSql()
    .offsetSql()
    .queryString


# ==================== DELETE ====================

proc deleteBuilder*(self: MariadbQuery): string =
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

proc deleteByIdBuilder*(self: MariadbQuery, id: int, key: string): string =
  return self
    .deleteSql()
    .fromSql()
    .deleteByIdSql(id, key)
    .queryString


# ==================== Aggregates ====================

proc countBuilder*(self:MariadbQuery): string =
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

proc maxBuilder*(self:MariadbQuery, column:string): string =
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

proc minBuilder*(self:MariadbQuery, column:string): string =
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

proc avgBuilder*(self:MariadbQuery, column:string): string =
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

proc sumBuilder*(self:MariadbQuery, column:string): string =
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

proc columnBuilder*(self:MariadbQuery): string =
  return self
    .selectSql()
    .fromSql()
    .selectFirstSql()
    .queryString
