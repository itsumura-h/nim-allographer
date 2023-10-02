import std/json
import ../postgres_types
import ./postgres_generator


# ==================== SELECT ====================

proc selectBuilder*(self: PostgresQuery): string =
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

proc selectFirstBuilder*(self: PostgresQuery): string =
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

proc selectFindBuilder*(self: PostgresQuery, key: string): string =
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

proc insertValueBuilder*(self: PostgresQuery, items: JsonNode): string =
  return self
    .insertSql()
    .insertValueSql(items)
    .queryString

proc insertValuesBuilder*(self: PostgresQuery, rows: openArray[JsonNode]): string =
  return self
    .insertSql()
    .insertValuesSql(rows)
    .queryString


# ==================== UPDATE ====================

proc updateBuilder*(self: PostgresQuery, items: JsonNode): string =
  return self
    .updateSql()
    .updateValuesSql(items)
    .whereSql()
    .orWhereSql()
    .limitSql()
    .offsetSql()
    .queryString


# ==================== DELETE ====================

proc deleteBuilder*(self: PostgresQuery): string =
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

proc deleteByIdBuilder*(self: PostgresQuery, id: int, key: string): string =
  return self
    .deleteSql()
    .fromSql()
    .deleteByIdSql(id, key)
    .queryString


# ==================== Aggregates ====================

proc countBuilder*(self:PostgresQuery): string =
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

proc maxBuilder*(self:PostgresQuery, column:string): string =
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

proc minBuilder*(self:PostgresQuery, column:string): string =
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

proc avgBuilder*(self:PostgresQuery, column:string): string =
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

proc sumBuilder*(self:PostgresQuery, column:string): string =
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

proc columnBuilder*(self:PostgresQuery): string =
  return self
    .selectSql()
    .fromSql()
    .selectFirstSql()
    .queryString
