## nim c -r -d:ssl example/sqlite_binary.nim

import std/asyncdispatch
import std/httpclient
import std/json
import std/streams
import ../src/allographer/query_builder/rdb/databases/database_types
import ../src/allographer/query_builder/rdb/databases/sqlite/sqlite_rdb
import ../src/allographer/query_builder/rdb/databases/sqlite/sqlite_lib
import ../src/allographer/query_builder/rdb/databases/sqlite/sqlite_impl


type Column = object
  name:string
  typ:string

proc main(){.async.} =
  let client = newAsyncHttpClient()
  let response = client.getContent("https://nim-lang.org/assets/img/twitter_banner.png").await
  let imageStream = newStringStream(response)
  let binaryImage = imageStream.readAll()
  # echo binaryImage

  var db: PSqlite3
  discard sqlite_rdb.open("/root/project/db.sqlite3", db)
  # echo db.repr
  db.exec("DROP TABLE IF EXISTS \"test\"", @[], 30).await
  db.exec("""
    CREATE TABLE IF NOT EXISTS "test" (
      'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      'blob' BLOB,
      'int' INTEGER,
      'float' NUMERIC,
      'str' VARCHAR
    )
  """, @[], 30).await

  var query = ""
  var stmt: PStmt
  var dbRows: DbRows
  var res:bool
  # get column row
  query = "PRAGMA table_info(\"test\")"
  var columns = newSeq[Column]()
  for row in db.instantRows(dbRows, query, newSeq[string]()):
    columns.add(Column(name:row[1], typ:row[2]))

  # insert data
  query = "INSERT INTO \"test\"(\"blob\", \"int\", \"float\", \"str\") VALUES (?, ?, ?, ?)"
  let arg = %*{"blob": binaryImage, "int": 100, "float": 1.1, "str": "alice"}
  if prepare_v2(db, query.cstring, query.len.cint, stmt, nil) == SQLITE_OK:
    var argCount = 1
    for (key, value) in arg.pairs:
      defer: argCount.inc()
      for column in columns:
        if column.name == key:
          case column.typ
          of "INTEGER":
            let value = value.getInt
            discard bind_int64(stmt, argCount.int32, value)
          of "NUMERIC", "REAL":
            let value = value.getFloat
            discard bind_double(stmt, argCount.int32, value.float64)
          of "BLOB":
            let value = value.getStr
            discard bind_blob(stmt, argCount.int32, value.unsafeAddr, value.len.int32, SQLITE_TRANSIENT)
          else:
            let value = value.getStr
            discard bind_text(stmt, argCount.int32, value.cstring, value.len.int32, SQLITE_TRANSIENT)
          break
    let x = step(stmt)
    if x in {SQLITE_DONE, SQLITE_ROW}:
      res = finalize(stmt) == SQLITE_OK
    else:
      discard finalize(stmt)
      res = false
  if not res:
    dbError(db)

main().waitFor
