# import std/db_postgres
import std/db_common
import std/times
import std/options
import std/asyncdispatch
import std/httpclient
import std/streams
import std/strutils
import ../../src/allographer/query_builder/libs/postgres/postgres_rdb

proc dbError(db: PPGconn) {.noreturn.} =
  ## raises a DbError exception.
  var e: ref DbError
  new(e)
  e.msg = $pqErrorMessage(db)
  raise e

# reference
# https://github.com/xzfc/ndb.nim/blob/master/ndb/postgres.nim#L72C1-L231C20

type DbValueKind* = enum
  dvkBool
  dvkInt
  dvkFloat
  dvkString
  dvkTimestamptz
  dvkOther
  dvkNull

type DbOther* = object
  oid*: Oid
  value*: string
type DbNull* = object          ## NULL value.
type DbValue* = object
  case kind*: DbValueKind
  of dvkBool:
    b*: bool
  of dvkInt:
    i*: int64
  of dvkFloat:
    f*: float64
  of dvkString:
    s*: string
  of dvkTimestamptz:
    t*: DateTime
  of dvkOther:
    o*: DbOther
  of dvkNull:
    discard
  isBinary:bool

type DbValueTypes* = bool|int64|float64|string|DateTime|DbOther|DbNull ## Possible value types

type DbParam = object
  nParams: int32
  values: cstringArray
  lengths: seq[int32]
  formats: seq[int32] # 0:text,1:binary

proc dbValue*(v: DbValue): DbValue =
  ## Return ``v`` as is.
  v

proc dbValue*(v: int|int8|int16|int32|int64|uint8|uint16|uint32): DbValue =
  ## Wrap integer value.
  DbValue(kind: dvkInt, i: v.int64)

proc dbValue*(v: float64): DbValue =
  ## Wrap float value.
  DbValue(kind: dvkFloat, f: v)

proc dbValue*(v: string, isBinary=false): DbValue =
  ## Wrap string value.
  DbValue(kind: dvkString, s: v, isBinary:isBinary)

proc dbValue*(v: bool): DbValue =
  ## Wrap bool value.
  DbValue(kind: dvkBool, b: v)

proc dbValue*(v: DateTime): DbValue =
  ## Wrap DateTime value.
  DbValue(kind: dvkTimestamptz, t: v)

proc dbValue*(v: DbNull|type(nil)): DbValue =
  ## Wrap NULL value.
  ## Caveat: ``dbValue(nil)`` doesn't compile on Nim 0.19.x, see
  ## https://github.com/nim-lang/Nim/pull/9231.
  DbValue(kind: dvkNull)

template `?`*(v: typed): DbValue =
  ## Shortcut for ``dbValue``.
  dbValue(v)

proc dbValue*[T](v: Option[T]): DbValue =
  ## Wrap value of type T or NULL.
  if v.isSome:
    v.unsafeGet.dbValue
  else:
    DbValue(kind: dvkNull)

proc `==`*(a: DbValue, b: DbValue): bool =
  ## Compare two DB values.
  if a.kind != b.kind:
    false
  else:
    case a.kind
    of dvkBool:        a.b == b.b
    of dvkInt:         a.i == b.i
    of dvkFloat:       a.f == b.f
    of dvkString:      a.s == b.s
    of dvkTimestamptz: a.t == b.t
    of dvkOther:       a.o == b.o
    of dvkNull:        true

proc strdup(s: string): cstring =
  result = cast[cstring](alloc0(s.len+1))
  if s.len != 0:
    copyMem(result, s[0].unsafeAddr, s.len)

proc newDbParam(args: varargs[DbValue]): DbParam =
  if args.len == 0:
    return
  result.nParams = args.len.int32
  var values = newSeq[string](args.len)
  # result.values = cast[cstringArray](alloc((args.len) * sizeof(cstring)))
  result.formats = newSeq[int32](args.len)
  result.lengths = newSeq[int32](args.len)
  # result.formats = 1 # binary
  for i in 0..<args.len:
    echo "=== args[i].kind"
    echo args[i].kind
    case args[i].kind
    of dvkBool:
      # result.values[i] = strdup((if args[i].b: "t" else: "f"))
      values[i] = if args[i].b: "t" else: "f"
      result.lengths[i] = sizeof(result.values[i]).int32
      result.formats[i] = 0
    of dvkInt:
      # result.values[i] = ($args[i].i).strdup
      values[i] = $args[i].i
      result.lengths[i] = sizeof(result.values[i]).int32
      result.formats[i] = 0
      # result.values[i] = "\0\0\0\0\0\0\x02\x01".strdup
      # result.lengthsSeq[i] = 8
      # result.formatsSeq[i] = 1
    of dvkFloat:
      # result.values[i] = ($args[i].f).strdup
      values[i] = $args[i].f
      result.lengths[i] = sizeof(result.values[i]).int32
      result.formats[i] = 0
      # result.types[i] = 701
    of dvkString:
      # let value = ($args[i].s).strdup
      let value = $args[i].s
      values[i] = value
      result.lengths[i] = args[i].s.len.int32
      result.formats[i] = if args[i].isBinary: 1 else: 0
      # result.types[i] = 25
    of dvkTimestamptz:
      # result.values[i] = ($args[i].t.format("yyyy-MM-dd HH:mm:sszz")).strdup
      values[i] = $args[i].t.format("yyyy-MM-dd HH:mm:sszz")
      result.lengths[i] = sizeof(result.values[i]).int32
      result.formats[i] = 0
      # result.types[i] = 1184
    of dvkOther:
      # result.values[i] = args[i].o.value.strdup
      values[i] = args[i].o.value
      result.lengths[i] = sizeof(result.values[i]).int32
      result.formats[i] = 0
      # result.types[i] = args[i].o.oid
    of dvkNull:
      # result.values[i] = nil
      values[i] = "NULL"
      result.formats[i] = 0

  result.values = allocCStringArray(values)
  for i, row in values:
    if row == "NULL":
      result.values[i] = nil


proc dealloc(binds: DbParam) =
  if binds.nParams == 0:
    return
  for i in 0..<binds.nParams:
    if binds.values[i] != nil:
      binds.values[i].dealloc
  dealloc(binds.values)



proc main() {.async.} =
  # connection
  let conn = pqsetdbLogin("postgres".cstring, "5432", nil, nil, "database", "user", "pass")
  if pqStatus(conn) != CONNECTION_OK: dbError(conn)
  # echo conn.repr

  block テーブル削除:
    echo "==== テーブル削除"
    let query = "DROP TABLE IF EXISTS image"
    let res = pqexecParams(conn, query.cstring, 0, nil, nil, nil, nil, 0) 
    if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(conn)
    pqclear(res)

  block テーブル作成:
    echo "==== テーブル作成"
    let query = """
      CREATE TABLE IF NOT EXISTS image (
        id SERIAL PRIMARY KEY,
        str VARCHAR(255),
        data BYTEA
      );
    """
    let res = pqexecParams(conn, query.cstring, 0, nil, nil, nil, nil, 0) 
    if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(conn)
    pqclear(res)

  block str挿入:
    echo "==== str挿入"
    let query = """
      INSERT INTO "image" ("str") VALUES ($1)
    """
    let param1 = dbValue("hello")
    let params = newDbParam(param1)
    echo "=== params.values.cstringArrayToSeq"
    echo params.values.cstringArrayToSeq
    # let res = pqexecParams(conn, query.cstring, params.nParams, nil, params.values, cast[ptr int32](params.lengths.unsafeAddr), cast[ptr int32](params.formats.unsafeAddr), 0)
    let res = pqexecParams(conn, query.cstring, params.nParams, nil, params.values, params.lengths[0].unsafeAddr, params.formats[0].unsafeAddr, 0)
    if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(conn)
    pqclear(res)

  block Binary挿入:
    echo "==== Binary挿入"
    let client = newAsyncHttpClient()
    let response = client.getContent("https://nim-lang.org/assets/img/twitter_banner.png").await
    let imageStream = newStringStream(response)
    let binaryImage = imageStream.readAll()
    
    let query = """
      INSERT INTO "image" ("data") VALUES ($1)
    """
    let param1 = dbValue(binaryImage, true)
    let params = newDbParam(param1)
    echo params.lengths
    echo params.formats
    let res = pqexecParams(conn, query.cstring, params.nParams, nil, params.values, params.lengths[0].unsafeAddr, params.formats[0].unsafeAddr, 0)
    if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(conn)
    pqclear(res)

main().waitFor
