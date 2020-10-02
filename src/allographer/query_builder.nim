import
  query_builder/base,
  query_builder/grammars,
  query_builder/exec,
  query_builder/transaction,
  connection

export
  base,
  grammars,
  exec,
  transaction,
  connection

let db = db()

when getDriver() == "sqlite":
  proc rdb*():RDB =
    return RDB(db:db)
when getDriver() == "postgres":
  let pool = pool()

  proc rdb*():RDB =
    return RDB(
      db:db,
      pool: pool
    )
when getDriver() == "mysql":
  proc rdb*():RDB =
    return RDB()