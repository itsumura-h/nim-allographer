import std/asyncdispatch
import std/os
import std/json
import std/options
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../../query_builder # TODO: delete after
import ../queries/sqlite/sqlite_query
# import ../queries/mysql/mysql_query
# import ../queries/postgres/postgres_query
import ../queries/query_interface


proc create*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # let generator =
  #   case rdb.driver
  #   of SQLite3:
  #     SqliteQuery.new(rdb).toInterface()
  #   of MySQL, MariaDB:
  #     MysqlQuery.new(rdb).toInterface()
  #   of PostgreSQL:
  #     PostgresQuery.new(rdb).toInterface()
  let generator = SqliteQuery.new(rdb).toInterface()

  # echo generator.repr

  # create migration table
  # マイグレーション履歴テーブルを作成
  let migrationTable = table("_migrations", [
    Column.string("name"),
    Column.text("query"),
    Column.string("checksum").index(),
    Column.datetime("created_at"),
    Column.boolean("status")
  ])
  # テーブルを生成
  generator.createTableSql(migrationTable)
  generator.exec(migrationTable)

  if isReset:
    # delete table in reverse loop in tables
    for i in countdown(tables.len-1, 0):
      let table = tables[i]
      generator.resetMigrationTable(table)
      generator.resetTable(table)

  for table in tables:
    # テーブル名からマイグレーション履歴を検索し、なければ作る
    # create table文をマイグレーション履歴テーブルにinsert
    let history = generator.getHistories(table)
    if history.len == 0 or isReset:
      generator.createTableSql(table)
      generator.execThenSaveHistory(table)

  let res = rdb.table("_migrations").get().waitFor
  for row in res:
    echo row.pretty()
