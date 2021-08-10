import macros
import ../base
import ../rdb/sqlite

proc dbQuote(s: string): string =
  ## Escapes the `'` (single quote) char to `''`.
  ## Because single quote is used for defining `VARCHAR` in SQL.
  runnableExamples:
    doAssert dbQuote("'") == "''''"
    doAssert dbQuote("A Foobar's pen.") == "'A Foobar''s pen.'"

  if s == "null":
    return "NULL"
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

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
  result = ""
  var a = 0
  for c in items(formatstr):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else:
      add(result, c)

proc setupQuery(db: PSqlite3, query: string, args: varargs[string]): PStmt =
  assert(not db.isNil, "Database not connected.")
  var q = dbFormat(query, args)
  if prepare_v2(db, q, q.len.cint, result, nil) != SQLITE_OK: dbError(db)

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

proc setColumns(columns: var DbColumns; x: PStmt) =
  let L = column_count(x)
  setLen(columns, L)
  for i in 0'i32 ..< L:
    columns[i].name = $column_name(x, i)
    columns[i].typ.name = $column_decltype(x, i)
    toTypeKind(columns[i].typ, column_type(x, i))
    columns[i].tableName = $column_table_name(x, i)

# iterator instantRows*(db: PSqlite3; columns: var DbColumns; query: string, args: seq[string]): InstantRow
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
    while step(stmt) == SQLITE_ROW:
      setColumns(columns, stmt)
      dbRows.add(columns)
      yield stmt
  finally:
    if finalize(stmt) != SQLITE_OK: dbError(db)

iterator instantRows*(db: PSqlite3, dbRows: var DbRows, sqliteStmt: PStmt): InstantRow
                      {.tags: [ReadDbEffect,WriteDbEffect].} =
  var sqliteStmt = sqliteStmt
  try:
    var columns: DbColumns
    while step(sqliteStmt) == SQLITE_ROW:
      setColumns(columns, sqliteStmt)
      dbRows.add(columns)
      yield sqliteStmt
  finally:
    if finalize(sqliteStmt) != SQLITE_OK: dbError(db)

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
