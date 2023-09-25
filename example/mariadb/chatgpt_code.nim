{.passL: "-lmariadb".}
{.passC: "-D_DEFAULT_SOURCE".}

import os, sequtils

# C言語のヘッダーファイルと関数のバインディング
type
  MYSQL* = pointer
  MYSQL_STMT* = pointer
  MYSQL_BIND* = pointer

proc mysql_library_init(nr: cint, argv: ptr ptr cchar, groups: ptr ptr cchar): cint {.importc, dynlib: "libmariadb.so".}
proc mysql_init(mysql: MYSQL): MYSQL {.importc, dynlib: "libmariadb.so".}
proc mysql_real_connect(mysql: MYSQL, host: cstring, user: cstring, passwd: cstring, db: cstring, port: cuint, unix_socket: cstring, client_flag: cuint): MYSQL {.importc, dynlib: "libmariadb.so".}
proc mysql_close(mysql: MYSQL) {.importc, dynlib: "libmariadb.so".}
proc mysql_error(mysql: MYSQL): cstring {.importc, dynlib: "libmariadb.so".}

proc mysql_stmt_init(mysql: MYSQL): MYSQL_STMT {.importc, dynlib: "libmariadb.so".}
proc mysql_stmt_prepare(stmt: MYSQL_STMT, query: cstring, length: culong): cint {.importc, dynlib: "libmariadb.so".}
proc mysql_stmt_bind_param(stmt: MYSQL_STMT, params: MYSQL_BIND): cint {.importc, dynlib: "libmariadb.so".}
proc mysql_stmt_execute(stmt: MYSQL_STMT): cint {.importc, dynlib: "libmariadb.so".}
proc mysql_stmt_close(stmt: MYSQL_STMT): cint {.importc, dynlib: "libmariadb.so".}
proc mysql_stmt_error(stmt: MYSQL_STMT): cstring {.importc, dynlib: "libmariadb.so".}

proc main() =
  if mysql_library_init(0, nil, nil) != 0:
    raise newException(Exception, "Could not initialize MySQL client library")

  let mysql = mysql_init(nil)
  if mysql == nil:
    raise newException(Exception, "mysql_init() failed: " & $mysql_error(mysql))

  if mysql_real_connect(mysql, "localhost", "username", "password", "dbname", 3306, nil, 0) == nil:
    raise newException(Exception, "mysql_real_connect() failed: " & $mysql_error(mysql))

  let stmt = mysql_stmt_init(mysql)
  if stmt == nil:
    raise newException(Exception, "mysql_stmt_init() failed: " & $mysql_error(mysql))

  let query = "INSERT INTO test(id, str) VALUES(?, ?)"
  if mysql_stmt_prepare(stmt, query, csize_t(query.len)) != 0:
    raise newException(Exception, "mysql_stmt_prepare() failed: " & $mysql_stmt_error(stmt))

  var bindSeq: seq[MYSQL_BIND]
  bindSeq.setLen(2)
  var id: cint = 1
  var strData = "alice"
  bindSeq[0].buffer_type = MYSQL_TYPE_LONG
  bindSeq[0].buffer = addr(id)
  bindSeq[1].buffer_type = MYSQL_TYPE_STRING
  bindSeq[1].buffer = addr(strData)
  bindSeq[1].buffer_length = cunsigned_long(strData.len)

  if mysql_stmt_bind_param(stmt, addr(bindSeq[0])) != 0:
    raise newException(Exception, "mysql_stmt_bind_param() failed: " & $mysql_stmt_error(stmt))

  if mysql_stmt_execute(stmt) != 0:
    raise newException(Exception, "mysql_stmt_execute() failed: " & $mysql_stmt_error(stmt))

  discard mysql_stmt_close(stmt)
  mysql_close(mysql)

main()
