import std/strutils
import std/json
import ../../error
import ../../models/database_types
import ./postgres_rdb


proc dbError*(db: PPGconn) {.noreturn.} =
  ## raises a DbError exception.
  var e: ref DbError
  new(e)
  e.msg = $pqErrorMessage(db)
  raise e

proc checkError*(db: PPGconn) =
  ## Raises a DbError exception.
  var message = pqErrorMessage(db)
  if message.len > 0:
    raise newException(DbError, $message)

proc getBaseColumnType(res: PPGresult, col: int32): DbType =
  ## OID → DbType（行に依存しない）。NULL セルは行ごとに `pqgetisnull` で上書きする。
  let oid = pqftype(res, col)
  case oid
  of 16: return DbType(kind: DbTypeKind.dbBool, name: "bool")
  of 17: return DbType(kind: DbTypeKind.dbBlob, name: "bytea")

  of 21:   return DbType(kind: DbTypeKind.dbInt, name: "int2", size: 2)
  of 23:   return DbType(kind: DbTypeKind.dbInt, name: "int4", size: 4)
  of 20:   return DbType(kind: DbTypeKind.dbInt, name: "int8", size: 8)
  of 1560: return DbType(kind: DbTypeKind.dbBit, name: "bit")
  of 1562: return DbType(kind: DbTypeKind.dbInt, name: "varbit")

  of 18:   return DbType(kind: DbTypeKind.dbFixedChar, name: "char")
  of 19:   return DbType(kind: DbTypeKind.dbFixedChar, name: "name")
  of 1042: return DbType(kind: DbTypeKind.dbFixedChar, name: "bpchar")

  of 25:   return DbType(kind: DbTypeKind.dbVarchar, name: "text")
  of 1043: return DbType(kind: DbTypeKind.dbVarChar, name: "varchar")
  of 2275: return DbType(kind: DbTypeKind.dbVarchar, name: "cstring")

  of 700: return DbType(kind: DbTypeKind.dbFloat, name: "float4")
  of 701: return DbType(kind: DbTypeKind.dbFloat, name: "float8")

  of 790:  return DbType(kind: DbTypeKind.dbDecimal, name: "money")
  of 1700: return DbType(kind: DbTypeKind.dbDecimal, name: "numeric")

  of 704:  return DbType(kind: DbTypeKind.dbTimeInterval, name: "tinterval")
  of 702:  return DbType(kind: DbTypeKind.dbTimestamp, name: "abstime")
  of 703:  return DbType(kind: DbTypeKind.dbTimeInterval, name: "reltime")
  of 1082: return DbType(kind: DbTypeKind.dbDate, name: "date")
  of 1083: return DbType(kind: DbTypeKind.dbTime, name: "time")
  of 1114: return DbType(kind: DbTypeKind.dbTimestamp, name: "timestamp")
  of 1184: return DbType(kind: DbTypeKind.dbTimestamp, name: "timestamptz")
  of 1186: return DbType(kind: DbTypeKind.dbTimeInterval, name: "interval")
  of 1266: return DbType(kind: DbTypeKind.dbTime, name: "timetz")

  of 114:  return DbType(kind: DbTypeKind.dbJson, name: "json")
  of 142:  return DbType(kind: DbTypeKind.dbXml, name: "xml")
  of 3802: return DbType(kind: DbTypeKind.dbJson, name: "jsonb")

  of 600: return DbType(kind: DbTypeKind.dbPoint, name: "point")
  of 601: return DbType(kind: DbTypeKind.dbLseg, name: "lseg")
  of 602: return DbType(kind: DbTypeKind.dbPath, name: "path")
  of 603: return DbType(kind: DbTypeKind.dbBox, name: "box")
  of 604: return DbType(kind: DbTypeKind.dbPolygon, name: "polygon")
  of 628: return DbType(kind: DbTypeKind.dbLine, name: "line")
  of 718: return DbType(kind: DbTypeKind.dbCircle, name: "circle")

  of 650: return DbType(kind: DbTypeKind.dbInet, name: "cidr")
  of 829: return DbType(kind: DbTypeKind.dbMacAddress, name: "macaddr")
  of 869: return DbType(kind: DbTypeKind.dbInet, name: "inet")

  of 2950: return DbType(kind: DbTypeKind.dbVarchar, name: "uuid")
  of 3614: return DbType(kind: DbTypeKind.dbVarchar, name: "tsvector")
  of 3615: return DbType(kind: DbTypeKind.dbVarchar, name: "tsquery")
  of 2970: return DbType(kind: DbTypeKind.dbVarchar, name: "txid_snapshot")

  of 27:   return DbType(kind: DbTypeKind.dbComposite, name: "tid")
  of 1790: return DbType(kind: DbTypeKind.dbComposite, name: "refcursor")
  of 2249: return DbType(kind: DbTypeKind.dbComposite, name: "record")
  of 3904: return DbType(kind: DbTypeKind.dbComposite, name: "int4range")
  of 3906: return DbType(kind: DbTypeKind.dbComposite, name: "numrange")
  of 3908: return DbType(kind: DbTypeKind.dbComposite, name: "tsrange")
  of 3910: return DbType(kind: DbTypeKind.dbComposite, name: "tstzrange")
  of 3912: return DbType(kind: DbTypeKind.dbComposite, name: "daterange")
  of 3926: return DbType(kind: DbTypeKind.dbComposite, name: "int8range")

  of 22:   return DbType(kind: DbTypeKind.dbArray, name: "int2vector")
  of 30:   return DbType(kind: DbTypeKind.dbArray, name: "oidvector")
  of 143:  return DbType(kind: DbTypeKind.dbArray, name: "xml[]")
  of 199:  return DbType(kind: DbTypeKind.dbArray, name: "json[]")
  of 629:  return DbType(kind: DbTypeKind.dbArray, name: "line[]")
  of 651:  return DbType(kind: DbTypeKind.dbArray, name: "cidr[]")
  of 719:  return DbType(kind: DbTypeKind.dbArray, name: "circle[]")
  of 791:  return DbType(kind: DbTypeKind.dbArray, name: "money[]")
  of 1000: return DbType(kind: DbTypeKind.dbArray, name: "bool[]")
  of 1001: return DbType(kind: DbTypeKind.dbArray, name: "bytea[]")
  of 1002: return DbType(kind: DbTypeKind.dbArray, name: "char[]")
  of 1003: return DbType(kind: DbTypeKind.dbArray, name: "name[]")
  of 1005: return DbType(kind: DbTypeKind.dbArray, name: "int2[]")
  of 1006: return DbType(kind: DbTypeKind.dbArray, name: "int2vector[]")
  of 1007: return DbType(kind: DbTypeKind.dbArray, name: "int4[]")
  of 1008: return DbType(kind: DbTypeKind.dbArray, name: "regproc[]")
  of 1009: return DbType(kind: DbTypeKind.dbArray, name: "text[]")
  of 1028: return DbType(kind: DbTypeKind.dbArray, name: "oid[]")
  of 1010: return DbType(kind: DbTypeKind.dbArray, name: "tid[]")
  of 1011: return DbType(kind: DbTypeKind.dbArray, name: "xid[]")
  of 1012: return DbType(kind: DbTypeKind.dbArray, name: "cid[]")
  of 1013: return DbType(kind: DbTypeKind.dbArray, name: "oidvector[]")
  of 1014: return DbType(kind: DbTypeKind.dbArray, name: "bpchar[]")
  of 1015: return DbType(kind: DbTypeKind.dbArray, name: "varchar[]")
  of 1016: return DbType(kind: DbTypeKind.dbArray, name: "int8[]")
  of 1017: return DbType(kind: DbTypeKind.dbArray, name: "point[]")
  of 1018: return DbType(kind: DbTypeKind.dbArray, name: "lseg[]")
  of 1019: return DbType(kind: DbTypeKind.dbArray, name: "path[]")
  of 1020: return DbType(kind: DbTypeKind.dbArray, name: "box[]")
  of 1021: return DbType(kind: DbTypeKind.dbArray, name: "float4[]")
  of 1022: return DbType(kind: DbTypeKind.dbArray, name: "float8[]")
  of 1023: return DbType(kind: DbTypeKind.dbArray, name: "abstime[]")
  of 1024: return DbType(kind: DbTypeKind.dbArray, name: "reltime[]")
  of 1025: return DbType(kind: DbTypeKind.dbArray, name: "tinterval[]")
  of 1027: return DbType(kind: DbTypeKind.dbArray, name: "polygon[]")
  of 1040: return DbType(kind: DbTypeKind.dbArray, name: "macaddr[]")
  of 1041: return DbType(kind: DbTypeKind.dbArray, name: "inet[]")
  of 1263: return DbType(kind: DbTypeKind.dbArray, name: "cstring[]")
  of 1115: return DbType(kind: DbTypeKind.dbArray, name: "timestamp[]")
  of 1182: return DbType(kind: DbTypeKind.dbArray, name: "date[]")
  of 1183: return DbType(kind: DbTypeKind.dbArray, name: "time[]")
  of 1185: return DbType(kind: DbTypeKind.dbArray, name: "timestamptz[]")
  of 1187: return DbType(kind: DbTypeKind.dbArray, name: "interval[]")
  of 1231: return DbType(kind: DbTypeKind.dbArray, name: "numeric[]")
  of 1270: return DbType(kind: DbTypeKind.dbArray, name: "timetz[]")
  of 1561: return DbType(kind: DbTypeKind.dbArray, name: "bit[]")
  of 1563: return DbType(kind: DbTypeKind.dbArray, name: "varbit[]")
  of 2201: return DbType(kind: DbTypeKind.dbArray, name: "refcursor[]")
  of 2951: return DbType(kind: DbTypeKind.dbArray, name: "uuid[]")
  of 3643: return DbType(kind: DbTypeKind.dbArray, name: "tsvector[]")
  of 3645: return DbType(kind: DbTypeKind.dbArray, name: "tsquery[]")
  of 3807: return DbType(kind: DbTypeKind.dbArray, name: "jsonb[]")
  of 2949: return DbType(kind: DbTypeKind.dbArray, name: "txid_snapshot[]")
  of 3905: return DbType(kind: DbTypeKind.dbArray, name: "int4range[]")
  of 3907: return DbType(kind: DbTypeKind.dbArray, name: "numrange[]")
  of 3909: return DbType(kind: DbTypeKind.dbArray, name: "tsrange[]")
  of 3911: return DbType(kind: DbTypeKind.dbArray, name: "tstzrange[]")
  of 3913: return DbType(kind: DbTypeKind.dbArray, name: "daterange[]")
  of 3927: return DbType(kind: DbTypeKind.dbArray, name: "int8range[]")
  of 2287: return DbType(kind: DbTypeKind.dbArray, name: "record[]")

  of 705:  return DbType(kind: DbTypeKind.dbUnknown, name: "unknown")
  else: return DbType(kind: DbTypeKind.dbUnknown, name: $oid) ## Query the system table pg_type to determine exactly which type is referenced.

proc buildBaseDbColumns*(res: PPGresult; cols: int32): DbColumns =
  result = newSeqOfCap[DbColumn](cols.int)
  setLen(result, cols)
  for col in 0'i32 ..< cols:
    result[col].name = $pqfname(res, col)
    result[col].typ = getBaseColumnType(res, col)
    result[col].tableName = $(pqftable(res, col))

proc appendDbRowWithBaseColumns*(res: PPGresult; dbRows: var DbRows; line, cols: int32; base: DbColumns) =
  var columns = base
  for col in 0'i32 ..< cols:
    if pqgetisnull(res, line, col) == 1:
      columns[col].typ = DbType(kind: dbNull, name: "null")
  dbRows.add(columns)

proc setColumnInfo*(res: PPGresult; dbRows: var DbRows; line, cols: int32) =
  let base = buildBaseDbColumns(res, cols)
  appendDbRowWithBaseColumns(res, dbRows, line, cols, base)

proc newRow*(L: int): Row =
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""

proc setRow*(res: PPGresult, r: var Row,  line, cols: int32) =
  for col in 0'i32..cols-1:
    setLen(r[col], 0)
    let x = pqgetvalue(res, line, col)
    if x.isNil:
      r[col] = ""
    else:
      add(r[col], x)

proc dbQuote(s: string): string =
  # ## DB quotes the string.
  # if s == "null":
  #   return "NULL"
  # result = "'"
  # for c in items(s):
  #   if c == '\'': add(result, "''")
  #   else: add(result, c)
  # add(result, '\'')

  ## DB quotes the string.
  if s == "null":
    return "NULL"
  result = newStringOfCap(s.len * 2 + 2)
  result.add('\'')
  for c in items(s):
    case c
    of '\'': add(result, "''")
    of '\0': add(result, "\\0")
    else: add(result, c)
  add(result, '\'')

proc dbFormat*(formatstr: string, args: varargs[string]): string =
  var a = 0
  if args.len > 0 and not formatstr.contains("?"):
    dbError("""parameter substitution expects "?" """)
  if args.len == 0:
    return formatstr
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


proc questionToDaller*(s:string):string =
  ## from `UPDATE user SET name = ?, email = ? WHERE id = ?`
  ##
  ## to   `UPDATE user SET name = $1, email = $2 WHERE id = $3`
  var i = 1
  var segStart = 0
  result = newStringOfCap(s.len + 8)
  for j in 0 ..< s.len:
    if s[j] == '?':
      if j > segStart:
        result.add(s[segStart ..< j])
      result.add('$')
      result.add($i)
      inc(i)
      segStart = j + 1
  if segStart < s.len:
    result.add(s[segStart ..< s.len])


type PGParams* = object
  nParams*: int32
  values*: cstringArray
  lengths*: seq[int32]
  formats*: seq[int32] # 0:text,1:binary


proc objArrayParamSeqs(args: JsonNode; columns: seq[Row]): tuple[values: seq[string], lengths: seq[int32], formats: seq[int32]] =
  result.values = newSeq[string](args.len)
  result.lengths = newSeq[int32](args.len)
  result.formats = newSeq[int32](args.len)
  var i = 0
  for arg in args.items:
    defer: i.inc()
    case arg["value"].kind
    of JBool:
      result.values[i] = if arg["value"].getBool: "t" else: "f"
      result.lengths[i] = 0
      result.formats[i] = 0
    of JInt:
      result.values[i] = $arg["value"].getInt
      result.lengths[i] = 0
      result.formats[i] = 0
    of JFloat:
      result.values[i] = $arg["value"].getFloat
      result.lengths[i] = 0
      result.formats[i] = 0
    of JNull:
      result.values[i] = "NULL"
      result.lengths[i] = 0
      result.formats[i] = 0
    of JObject, JArray:
      result.values[i] = arg["value"].pretty
      result.lengths[i] = 0
      result.formats[i] = 0
    of JString:
      if columns.len > 0:
        for column in columns:
          if column[0] == arg["key"].getStr:
            defer: break
            let value = arg["value"].getStr
            result.values[i] = value
            result.lengths[i] = value.len.int32
            if column[1] == "bytea":
              result.formats[i] = 1
            else:
              result.formats[i] = 0
      else:
        let value = arg["value"].getStr
        result.values[i] = value
        result.lengths[i] = value.len.int32
        result.formats[i] = 0

proc allocPgParamsFromSeqs(values: seq[string]; lengths, formats: seq[int32]; n: int): PGParams =
  result.nParams = n.int32
  result.lengths = lengths
  result.formats = formats
  result.values = allocCStringArray(values)
  for j, row in values:
    if row == "NULL":
      result.values[j] = nil

proc fromObjArray*(_: type PGParams, args: JsonNode, columns: seq[Row]): PGParams =
  if args.len == 0:
    return
  let t = objArrayParamSeqs(args, columns)
  result = allocPgParamsFromSeqs(t.values, t.lengths, t.formats, args.len)

proc fromObjArray*(_: type PGParams, args: JsonNode): PGParams =
  ## `args` is JArray `[{"key": "bool", "value": true},{"key": "int", "value": 1}]`
  if args.len == 0:
    return
  let t = objArrayParamSeqs(args, @[])
  result = allocPgParamsFromSeqs(t.values, t.lengths, t.formats, args.len)


proc fromArray*(_:type PGParams, args: JsonNode):PGParams =
  ## `args` is JArray `{true, 1, 1.1, "alice"}`
  if args.len == 0:
    return
  result.nParams = args.len.int32

  var values = newSeq[string](args.len)
  result.formats = newSeq[int32](args.len)
  result.lengths = newSeq[int32](args.len)

  var i = 0
  for arg in args.items:
    defer: i.inc()
    case arg.kind
    of JBool:
      values[i] = if arg.getBool: "t" else: "f"
      result.lengths[i] = 0
      result.formats[i] = 0
    of JInt:
      values[i] = $arg.getInt
      result.lengths[i] = 0
      result.formats[i] = 0
    of JFloat:
      values[i] = $arg.getFloat
      result.lengths[i] = 0
      result.formats[i] = 0
    of JNull:
      values[i] = "NULL"
      result.lengths[i] = 0
      result.formats[i] = 0
    of JObject, JArray:
      values[i] = arg.pretty
      result.lengths[i] = 0
      result.formats[i] = 0
    of JString:
      let value = arg.getStr
      values[i] = value
      result.lengths[i] = value.len.int32
      result.formats[i] = 0

  result.values = allocCStringArray(values)
  for i, row in values:
    if row == "NULL":
      result.values[i] = nil
