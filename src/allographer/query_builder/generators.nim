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
    result = sqlite_generator.selectByIdSql(this, id, key)
  of "mysql":
    result = mysql_generator.selectByIdSql(this, id, key)
  of "postgres":
    result = postgres_generator.selectByIdSql(this, id, key)


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
    result = sqlite_generator.deleteByIdSql(this, id, key)
  of "mysql":
    result = mysql_generator.deleteByIdSql(this, id, key)
  of "postgres":
    result = postgres_generator.deleteByIdSql(this, id, key)
