import std/json
import ../surreal_types
import ./surreal_generator


# ==================== SELECT ====================

proc selectBuilder*(self: SurrealQuery): string =
  return self
    .selectSql()
    .fromSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    # .whereBetweenStringSql()
    .whereNotBetweenSql()
    # .whereNotBetweenStringSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    #.havingSql()
    .orderBySql()
    .limitSql()
    .startSql()
    .fetchSql()
    .parallelSql()
    .queryString


proc selectFirstBuilder*(self: SurrealQuery): string =
  return self
    .selectSql()
    .fromSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    # .whereBetweenStringSql()
    .whereNotBetweenSql()
    # .whereNotBetweenStringSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    #.havingSql()
    .orderBySql()
    .selectFirstSql() # LIMIT
    .startSql()
    .fetchSql()
    .parallelSql()
    .queryString


proc selectFindBuilder*(self: SurrealQuery, id:SurrealId, key: string): string =
  return self
    .selectSql()
    .fromSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    # .whereBetweenStringSql()
    .whereNotBetweenSql()
    # .whereNotBetweenStringSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .selectByIdSql(id, key) # LIMIT
    .fetchSql()
    .parallelSql()
    .queryString


# ==================== INSERT ====================

proc insertValueBuilder*(self: SurrealQuery, items: JsonNode): string =
  return self
    .insertSql()
    .insertValueSql(items)
    .parallelSql()
    .queryString

proc insertValuesBuilder*(self: SurrealQuery, items: openArray[JsonNode]): string =
  return self
    .insertSql()
    .insertValuesSql(items)
    .parallelSql()
    .queryString


# ==================== UPDATE ====================

proc updateBuilder*(self:SurrealQuery, items:JsonNode):string =
  return self
    .updateSql()
    .updateValuesSql(items)
    .whereSql()
    .orWhereSql()
    .limitSql()
    .startSql()
    .parallelSql()
    .queryString


proc updateMergeBuilder*(self:SurrealQuery, id:string, items:JsonNode):string =
  return self
    .updateMergeSql(id, items)
    # .whereSql()
    # .orWhereSql()
    # .limitSql()
    # .startSql()
    .parallelSql()
    .queryString


# ==================== DELETE ====================

proc deleteBuilder*(self: SurrealQuery): string =
  return self
    .deleteSql()
    .fromSql()
    .whereSql()
    .orWhereSql()
    .limitSql()
    .startSql()
    .queryString

proc deleteByIdBuilder*(self: SurrealQuery, id: string): string =
  return self
    .deleteSql()
    .deleteByIdSql(id)
    .queryString


# ==================== Aggregates ====================

proc countBuilder*(self:SurrealQuery): string =
  let sql = self
    .selectCountSql()
    .fromSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    .whereNotBetweenSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    #.havingSql()
    .orderBySql()
    .limitSql()
    .startSql()
    .fetchSql()
    .parallelSql()
    .queryString
  return sql & " GROUP ALL"

proc selectAvgBuilder*(self:SurrealQuery, column:string): string =
  return self
    .selectAvgSql(column)
    .fromSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    .whereNotBetweenSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    #.havingSql()
    .orderBySql()
    .limitSql()
    .startSql()
    .fetchSql()
    .parallelSql()
    .groupAllSql()
    .queryString

proc selectSumBuilder*(self:SurrealQuery, column:string): string =
  return self
    .selectSumSql(column)
    .fromSql()
    .whereSql()
    .orWhereSql()
    .whereBetweenSql()
    .whereNotBetweenSql()
    .whereInSql()
    .whereNotInSql()
    .whereNullSql()
    .groupBySql()
    #.havingSql()
    .orderBySql()
    .limitSql()
    .startSql()
    .fetchSql()
    .parallelSql()
    .groupAllSql()
    .queryString
