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
