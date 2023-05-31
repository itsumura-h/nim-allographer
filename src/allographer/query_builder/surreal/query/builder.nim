import std/json
import ../surreal_types
import ./generator


# ==================== SELECT ====================

proc selectBuilder*(self: SurrealDb): string =
  return self
    .selectSql()
    .fromSql()
    .whereSql()
    .orWhereSql()
    # .whereBetweenSql()
    # .whereBetweenStringSql()
    # .whereNotBetweenSql()
    # .whereNotBetweenStringSql()
    # .whereInSql()
    # .whereNotInSql()
    # .whereNullSql()
    .groupBySql()
    # .havingSql()
    .orderBySql()
    .limitSql()
    .startSql()
    .fetchSql()
    .parallelSql()
    .queryString


proc selectFirstBuilder*(self: SurrealDb): string =
  return self
    .selectSql()
    .fromSql()
    .whereSql()
    .orWhereSql()
    # .whereBetweenSql()
    # .whereBetweenStringSql()
    # .whereNotBetweenSql()
    # .whereNotBetweenStringSql()
    # .whereInSql()
    # .whereNotInSql()
    # .whereNullSql()
    .groupBySql()
    # .havingSql()
    .orderBySql()
    .selectFirstSql() # LIMIT
    .startSql()
    .fetchSql()
    .parallelSql()
    .queryString


proc selectFindBuilder*(self: SurrealDb, key: string): string =
  return self
    .selectSql()
    .fromSql()
    .whereSql()
    .orWhereSql()
    # .whereBetweenSql()
    # .whereBetweenStringSql()
    # .whereNotBetweenSql()
    # .whereNotBetweenStringSql()
    # .whereInSql()
    # .whereNotInSql()
    # .whereNullSql()
    .selectByIdSql(key) # LIMIT
    .fetchSql()
    .parallelSql()
    .queryString


# ==================== INSERT ====================

proc insertValueBuilder*(self: SurrealDb, items: JsonNode): string =
  return self
    .insertSql()
    .insertValueSql(items)
    .parallelSql()
    .queryString

proc insertValuesBuilder*(self: SurrealDb, items: openArray[JsonNode]): string =
  return self
    .insertSql()
    .insertValuesSql(items)
    .parallelSql()
    .queryString


# ==================== UPDATE ====================

proc updateBuilder*(self:SurrealDb, items:JsonNode):string =
  return self
    .updateSql()
    .updateValuesSql(items)
    .whereSql()
    .orWhereSql()
    .limitSql()
    .startSql()
    .parallelSql()
    .queryString


proc updateMergeBuilder*(self:SurrealDb, id:string, items:JsonNode):string =
  return self
    .updateMergeSql(id, items)
    # .whereSql()
    # .orWhereSql()
    # .limitSql()
    # .startSql()
    .parallelSql()
    .queryString
