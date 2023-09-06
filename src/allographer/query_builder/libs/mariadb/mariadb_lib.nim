import std/json
import ../../error
import ../../models/database_types
import ./mariadb_rdb


# type InstantRow* = object ## a handle that can be used to get a row's
#                        ## column text on demand
#   row*: cstringArray
#   len: int

proc dbError*(db: PMySQL) {.noreturn.} =
  ## raises a DbError exception.
  var e: ref DbError
  new(e)
  e.msg = $db.error
  raise e

# proc checkError*(db: PMySQL) =
#   ## Raises a DbError exception.
#   var message = $db.error
#   if message.len > 0:
#     raise newException(DbError, $message)

proc setTypeName(t: var DbType; f: PFIELD) =
  t.name = $f.name
  t.maxReprLen = Natural(f.max_length)
  if (NOT_NULL_FLAG and f.flags) != 0: t.notNull = true
  case f.ftype
  of TYPE_DECIMAL:
    t.kind = dbDecimal
  of TYPE_TINY:
    t.kind = dbInt
    t.size = 1
  of TYPE_SHORT:
    t.kind = dbInt
    t.size = 2
  of TYPE_LONG:
    t.kind = dbInt
    t.size = 4
  of TYPE_FLOAT:
    t.kind = dbFloat
    t.size = 4
  of TYPE_DOUBLE:
    t.kind = dbFloat
    t.size = 8
  of TYPE_NULL:
    t.kind = dbNull
  of TYPE_TIMESTAMP:
    t.kind = dbTimestamp
  of TYPE_LONGLONG:
    t.kind = dbInt
    t.size = 8
  of TYPE_INT24:
    t.kind = dbInt
    t.size = 3
  of TYPE_DATE:
    t.kind = dbDate
  of TYPE_TIME:
    t.kind = dbTime
  of TYPE_DATETIME:
    t.kind = dbDatetime
  of TYPE_YEAR:
    t.kind = dbDate
  of TYPE_NEWDATE:
    t.kind = dbDate
  of TYPE_VARCHAR, TYPE_VAR_STRING, TYPE_STRING:
    t.kind = dbVarchar
  of TYPE_BIT:
    t.kind = dbBit
  of TYPE_NEWDECIMAL:
    t.kind = dbDecimal
  of TYPE_ENUM: t.kind = dbEnum
  of TYPE_SET: t.kind = dbSet
  of TYPE_TINY_BLOB, TYPE_MEDIUM_BLOB, TYPE_LONG_BLOB,
     TYPE_BLOB: t.kind = dbBlob
  of TYPE_GEOMETRY:
    t.kind = dbGeometry

proc setColumnInfo*(columns: var DbColumns; res: PRES; L: int) =
  setLen(columns, L)
  for i in 0..<L:
    let fp = fetch_field_direct(res, cint(i))
    setTypeName(columns[i].typ, fp)
    columns[i].name = $fp.name
    columns[i].tableName = $fp.table
    columns[i].primaryKey = (fp.flags and PRI_KEY_FLAG) != 0

# proc newRow*(L: int): database_types.Row =
#   newSeq(result, L)
#   for i in 0..L-1: result[i] = ""

# proc properFreeResult*(sqlres: PRES, row: cstringArray) =
#   if row != nil:
#     while fetchRow(sqlres) != nil: discard
#   freeResult(sqlres)

proc dbQuote(s: string): string =
  ## DB quotes the string.
  if s == "null":
    return "NULL"
  result = newStringOfCap(s.len + 2)
  result.add "'"
  for c in items(s):
    # see https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html#mysql-escaping
    case c
    of '\0': result.add "\\0"
    of '\b': result.add "\\b"
    of '\t': result.add "\\t"
    of '\l': result.add "\\n"
    of '\r': result.add "\\r"
    of '\x1a': result.add "\\Z"
    of '"': result.add "\\\""
    of '\'': result.add "\\'"
    of '\\': result.add "\\\\"
    of '_': result.add "\\_"
    else: result.add c
  add(result, '\'')

proc dbFormat*(formatstr: string, args: seq[string]): string =
  result = ""
  var a = 0
  for c in items(formatstr):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else:
      add(result, c)


# proc rawExec*(db:PMySQL, query:string, args: seq[string]) =
#   var q = dbFormat(query, args)
#   if realQuery(db, q.cstring, q.len) != 0'i32: dbError(db)

# iterator instantRows*(db: PMySQL; dbRows: var DbRows; query: string;
#                       args: seq[string]): InstantRow =
#   ## Same as fastRows but returns a handle that can be used to get column text
#   ## on demand using []. Returned handle is valid only within the iterator body.
#   rawExec(db, query, args)
#   var sqlres = mariadb_rdb.useResult(db)
#   var dbColumns: DbColumns
#   if sqlres != nil:
#     let L = int(mariadb_rdb.numFields(sqlres))
#     var row: cstringArray
#     while true:
#       setColumnInfo(dbColumns, sqlres, L)
#       dbRows.add(dbColumns)
#       for i in 0..L:
#         row = mariadb_rdb.fetchRow(sqlres)
#       if row == nil: break
#       yield InstantRow(row: row, len: L)
#     properFreeResult(sqlres, row)

# proc `[]`*(row: InstantRow, col: int): string {.inline.} =
#   ## Returns text for given column of the row.
#   $row.row[col]

# proc unsafeColumnAt*(row: InstantRow, index: int): cstring {.inline.} =
#   ## Return cstring of given column of the row
#   row.row[index]

# proc len*(row: InstantRow): int {.inline.} =
#   ## Returns number of columns in the row.
#   row.len


type MariadbParamValue* = object
  value*: string
  isBinary*:bool

type MariadbParams* = seq[MariadbParamValue]

proc fromObj*(_:type MariadbParams, args:JsonNode, columns:seq[seq[string]]):MariadbParams =
  ## args is JArray [{"key":"id", "value": 1}, {"key": "name" "value": "alice"}] 
  result = newSeq[MariadbParamValue](args.len)
  var i = 0
  for arg in args.items:
    defer: i.inc()
    case arg["value"].kind
    of JBool:
      let value = if arg["value"].getBool: "1" else: "0"
      result[i] = MariadbParamValue(value:value, isBinary:false)
    of JInt:
      let value = $arg["value"].getInt
      result[i] = MariadbParamValue(value:value, isBinary:false)
    of JFloat:
      let value = $arg["value"].getFloat
      result[i] = MariadbParamValue(value:value, isBinary:false)
    of JArray, JObject:
      let value = arg["value"].pretty()
      result[i] = MariadbParamValue(value:value, isBinary:false)
    of JNull:
      let value = "NULL"
      result[i] = MariadbParamValue(value:value, isBinary:false)
    else: # JString
      let value = arg["value"].getStr
      result[i] = MariadbParamValue(value:value, isBinary:false)
      for column in columns:
        let columnName = column[0]
        let columnTyp = column[1]
        if columnName == arg["key"].getStr:
          defer:break
          if columnTyp == "blob":
            result[i].isBinary = true


proc dbFormat*(conn:PMySQL, query: string, args: MariadbParams): string =
  result = ""
  var i = 0
  for c in query:
    if c == '?':
      defer: i.inc()
      if args[i].isBinary:
        let `from` = args[i].value
        var to = newString(`from`.len * 2 + 1)
        let len = mariadb_rdb.real_escape_string(conn, to.cstring, `from`.cstring, `from`.len)
        to.setLen(len)
        result.add("\'")
        result.add(to)
        result.add("\'")
      else:
        result.add(dbQuote(args[i].value))
    else:
      result.add(c)
