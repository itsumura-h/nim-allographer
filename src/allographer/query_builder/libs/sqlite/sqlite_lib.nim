import std/macros
import ../../error
import ../../models/database_types
import ./sqlite_rdb


proc dbQuote(s: string): string =
  ## Escapes the `'` (single quote) char to `''`.
  ## Because single quote is used for defining `VARCHAR` in SQL.
  runnableExamples:
    doAssert dbQuote("'") == "''''"
    doAssert dbQuote("A Foobar's pen.") == "'A Foobar''s pen.'"

  if s == "null":
    return "NULL"
  result = newStringOfCap(s.len * 2 + 2)
  result.add('\'')
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc sqliteQuoteIdent*(name: string): string =
  ## `PRAGMA` 等で使う SQLite の二重引用符識別子（内部の `"` は `""` にエスケープ）。
  result = newStringOfCap(name.len + 2)
  result.add('"')
  for c in name:
    if c == '"':
      result.add("\"\"")
    else:
      result.add(c)
  result.add('"')

proc dbError*(db: PSqlite3) {.noreturn.} =
  ## Raises a `DbError` exception.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##    if not db.tryExec(sql"SELECT * FROM not_exist_table"):
  ##      dbError(db)
  ##    db.close()
  var e: ref DbError
  new(e)
  e.msg = $errmsg(db)
  raise e

proc dbFormat*(formatstr: string, args: varargs[string]): string =
  var a = 0
  result = newStringOfCap(formatstr.len + args.len * 8)
  var segStart = 0
  for j in 0 ..< formatstr.len:
    if formatstr[j] == '?':
      if j > segStart:
        result.add(formatstr[segStart ..< j])
      result.add(dbQuote(args[a]))
      inc(a)
      segStart = j + 1
  if segStart < formatstr.len:
    result.add(formatstr[segStart ..< formatstr.len])

proc setupQuery(db: PSqlite3, query: string, args: varargs[string]): PStmt =
  assert(not db.isNil, "Database not connected.")
  var q = dbFormat(query, args)
  if prepare_v2(db, q.cstring, q.len.cint, result, nil) != SQLITE_OK: dbError(db)

proc toTypeKind(t: var DbType; x: int32) =
  case x
  of SQLITE_INTEGER:
    t.kind = dbInt
    t.size = 8
  of SQLITE_FLOAT:
    t.kind = dbFloat
    t.size = 8
  of SQLITE_BLOB: t.kind = dbBlob
  of SQLITE_NULL: t.kind = dbNull
  of SQLITE_TEXT: t.kind = dbVarchar
  else: t.kind = dbUnknown

proc setColumnsStaticMeta*(columns: var DbColumns; x: PStmt) =
  ## ステップ前でも列名・宣言型・テーブル名は取得できる（行に依存しない）。
  let L = column_count(x)
  setLen(columns, L.int)
  for i in 0'i32 ..< L:
    columns[i].name = $column_name(x, i)
    columns[i].typ.name = $column_decltype(x, i)
    columns[i].tableName = $column_table_name(x, i)

proc setColumnsRuntimeTypes*(columns: var DbColumns; x: PStmt) =
  ## 行ごとに変わりうるのは `column_type` のみ。
  let L = column_count(x)
  for i in 0'i32 ..< L:
    toTypeKind(columns[i].typ, column_type(x, i))

iterator instantRows*(db: PSqlite3; dbRows: var DbRows; query: string, args: seq[string]): InstantRow
                      {.tags: [ReadDbEffect].} =
  ## Similar to `instantRows iterator <#instantRows.i,DbConn,SqlQuery,varargs[string,]>`_,
  ## but sets information about columns to `columns`.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    var columns: DbColumns
  ##    for row in db.instantRows(columns, sql"SELECT * FROM my_table"):
  ##      discard
  ##    echo columns[0]
  ##
  ##    # Output:
  ##    # (name: "id", tableName: "my_table", typ: (kind: dbNull,
  ##    # notNull: false, name: "INTEGER", size: 0, maxReprLen: 0, precision: 0,
  ##    # scale: 0, min: 0, max: 0, validValues: @[]), primaryKey: false,
  ##    # foreignKey: false)
  ##
  ##    db.close()
  var stmt = setupQuery(db, query, args)
  try:
    var columns: DbColumns
    setColumnsStaticMeta(columns, stmt)
    while step(stmt) == SQLITE_ROW:
      setColumnsRuntimeTypes(columns, stmt)
      dbRows.add(columns)
      yield stmt
  finally:
    if finalize(stmt) != SQLITE_OK: dbError(db)

iterator instantRowsPlain*(db: PSqlite3; query: string, args: seq[string]): InstantRow
                      {.tags: [ReadDbEffect].} =
  var stmt = setupQuery(db, query, args)
  try:
    while step(stmt) == SQLITE_ROW:
      yield stmt
  finally:
    if finalize(stmt) != SQLITE_OK: dbError(db)

iterator instantRows*(db: PSqlite3, dbRows: var DbRows, sqliteStmt: PStmt): InstantRow
                      {.tags: [ReadDbEffect,WriteDbEffect].} =
  var sqliteStmt = sqliteStmt
  try:
    var columns: DbColumns
    setColumnsStaticMeta(columns, sqliteStmt)
    while step(sqliteStmt) == SQLITE_ROW:
      setColumnsRuntimeTypes(columns, sqliteStmt)
      dbRows.add(columns)
      yield sqliteStmt
  finally:
    if finalize(sqliteStmt) != SQLITE_OK: dbError(db)

proc getColumns*(db: PSqlite3; dbRows: var DbRows; query: string, args: seq[string]):seq[string] =
  var stmt = setupQuery(db, query, args)
  try:
    var i:int32 = 0
    while true:
      let name = column_name(stmt, i)
      if name.len == 0: break
      result.add($name)
      i.inc()
  finally:
    if finalize(stmt) != SQLITE_OK: dbError(db)

  return result

proc len*(row: InstantRow): int32 {.inline.} =
  ## Returns number of columns in a row.
  ##
  ## See also:
  ## * `instantRows iterator <#instantRows.i,DbConn,SqlQuery,varargs[string,]>`_
  ##   example code
  column_count(row)

proc `[]`*(row: InstantRow, col: int32): string {.inline.} =
  ## Returns text for given column of the row.
  ##
  ## See also:
  ## * `instantRows iterator <#instantRows.i,DbConn,SqlQuery,varargs[string,]>`_
  ##   example code
  $column_text(row, col)

template dbBindParamError*(paramIdx: int, val: varargs[untyped]) =
  ## Raises a `DbError` exception.
  var e: ref DbError
  new(e)
  e.msg = "error binding param in position " & $paramIdx
  raise e

proc bindParam*(ps: PStmt, paramIdx: int, val: string, copy = true) =
  ## Binds a string to the specified paramIndex.
  ## if copy is true then SQLite makes its own private copy of the data immediately
  if bind_text(ps, paramIdx.int32, val.cstring, val.len.int32, if copy: SQLITE_TRANSIENT else: SQLITE_STATIC) != SQLITE_OK:
    dbBindParamError(paramIdx, val)
