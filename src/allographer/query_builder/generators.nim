import json

import ../util
import base
import
  generators/sqlite_generator,
  generators/mysql_generator,
  generators/postgres_generator

# ==================== SELECT ====================

proc selectSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.selectSql(this)
  of "mysql":
    result = mysql_generator.selectSql(this)
  of "postgres":
    result = postgres_generator.selectSql(this)


proc fromSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.fromSql(this)
  of "mysql":
    result = mysql_generator.fromSql(this)
  of "postgres":
    result = postgres_generator.fromSql(this)


proc selectByIdSql*(this:RDB, id:int, key:string): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.selectByIdSql(this, key)
  of "mysql":
    result = mysql_generator.selectByIdSql(this, key)
  of "postgres":
    result = postgres_generator.selectByIdSql(this, key)


proc joinSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.joinSql(this)
  of "mysql":
    result = mysql_generator.joinSql(this)
  of "postgres":
    result = postgres_generator.joinSql(this)


proc whereSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.whereSql(this)
  of "mysql":
    result = mysql_generator.whereSql(this)
  of "postgres":
    result = postgres_generator.whereSql(this)


proc orWhereSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.orWhereSql(this)
  of "mysql":
    result = mysql_generator.orWhereSql(this)
  of "postgres":
    result = postgres_generator.orWhereSql(this)

proc whereBetweenSql*(this:RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.whereBetweenSql(this)
  of "mysql":
    result = mysql_generator.whereBetweenSql(this)
  of "postgres":
    result = postgres_generator.whereBetweenSql(this)

proc whereNotBetweenSql*(this:RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.whereNotBetweenSql(this)
  of "mysql":
    result = mysql_generator.whereNotBetweenSql(this)
  of "postgres":
    result = postgres_generator.whereNotBetweenSql(this)

proc whereInSql*(this:RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.whereInSql(this)
  of "mysql":
    result = mysql_generator.whereInSql(this)
  of "postgres":
    result = postgres_generator.whereInSql(this)


proc whereNotInSql*(this:RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.whereNotInSql(this)
  of "mysql":
    result = mysql_generator.whereNotInSql(this)
  of "postgres":
    result = postgres_generator.whereNotInSql(this)


proc whereNullSql*(this:RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.whereNullSql(this)
  of "mysql":
    result = mysql_generator.whereNullSql(this)
  of "postgres":
    result = postgres_generator.whereNullSql(this)


proc groupBySql*(this:RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.groupBySql(this)
  of "mysql":
    result = mysql_generator.groupBySql(this)
  of "postgres":
    result = postgres_generator.groupBySql(this)


proc havingSql*(this:RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.havingSql(this)
  of "mysql":
    result = mysql_generator.havingSql(this)
  of "postgres":
    result = postgres_generator.havingSql(this)


proc orderBySql*(this:RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.orderBySql(this)
  of "mysql":
    result = mysql_generator.orderBySql(this)
  of "postgres":
    result = postgres_generator.orderBySql(this)


proc limitSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.limitSql(this)
  of "mysql":
    result = mysql_generator.limitSql(this)
  of "postgres":
    result = postgres_generator.limitSql(this)


proc offsetSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.offsetSql(this)
  of "mysql":
    result = mysql_generator.offsetSql(this)
  of "postgres":
    result = postgres_generator.offsetSql(this)


# ==================== INSERT ====================

proc insertSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.insertSql(this)
  of "mysql":
    result = mysql_generator.insertSql(this)
  of "postgres":
    result = postgres_generator.insertSql(this)


proc insertValueSql*(this: RDB, items: JsonNode): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.insertValueSql(this, items)
  of "mysql":
    result = mysql_generator.insertValueSql(this, items)
  of "postgres":
    result = postgres_generator.insertValueSql(this, items)


proc insertValuesSql*(this: RDB, rows: openArray[JsonNode]): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.insertValuesSql(this, rows)
  of "mysql":
    result = mysql_generator.insertValuesSql(this, rows)
  of "postgres":
    result = postgres_generator.insertValuesSql(this, rows)


# ==================== UPDATE ====================

proc updateSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.updateSql(this)
  of "mysql":
    result = mysql_generator.updateSql(this)
  of "postgres":
    result = postgres_generator.updateSql(this)


proc updateValuesSql*(this: RDB, items:JsonNode): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.updateValuesSql(this, items)
  of "mysql":
    result = mysql_generator.updateValuesSql(this, items)
  of "postgres":
    result = postgres_generator.updateValuesSql(this, items)


# ==================== DELETE ====================

proc deleteSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.deleteSql(this)
  of "mysql":
    result = mysql_generator.deleteSql(this)
  of "postgres":
    result = postgres_generator.deleteSql(this)

proc deleteByIdSql*(this: RDB, id: int, key: string): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.deleteByIdSql(this, key)
  of "mysql":
    result = mysql_generator.deleteByIdSql(this, key)
  of "postgres":
    result = postgres_generator.deleteByIdSql(this, key)

# ==================== Aggregates ====================

proc selectCountSql*(this: RDB): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.selectCountSql(this)
  of "mysql":
    result = mysql_generator.selectCountSql(this)
  of "postgres":
    result = postgres_generator.selectCountSql(this)

proc selectMaxSql*(this:RDB, column:string): RDB =
  let driver = util.getDriver()
  case driver:
  of "sqlite":
    result = sqlite_generator.selectMaxSql(this, column)
  of "mysql":
    result = mysql_generator.selectMaxSql(this, column)
  of "postgres":
    result = postgres_generator.selectMaxSql(this, column)