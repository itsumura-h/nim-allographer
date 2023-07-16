import std/asyncdispatch
import std/random
import std/strutils
import std/times
import ./sqlite/sqlite_rdb
import ./postgres/postgres_rdb
import ./mysql/mysql_rdb
import ./mariadb/mariadb_rdb


type
  Pool* = ref object
    mysqlConn*: mysql_rdb.PMySQL
    mariadbConn*: mariadb_rdb.PMySQL
    postgresConn*: PPGconn
    sqliteConn*: PSqlite3
    isBusy*: bool
    createdAt*: int64
  Connections* = ref object
    pools*: seq[Pool]
    timeout*:int
  Prepared* = ref object
    conn*: Connections
    connI*:int
    nArgs*: int
    pgStmt*: string
    sqliteStmt*: sqlite_rdb.PStmt
  Row* = seq[string]
  DbTypeKind* = enum ## a superset of datatypes that might be supported.
    dbUnknown,       ## unknown datatype
    dbSerial,        ## datatype used for primary auto-increment keys
    dbNull,          ## datatype used for the NULL value
    dbBit,           ## bit datatype
    dbBool,          ## boolean datatype
    dbBlob,          ## blob datatype
    dbFixedChar,     ## string of fixed length
    dbVarchar,       ## string datatype
    dbJson,          ## JSON datatype
    dbXml,           ## XML datatype
    dbInt,           ## some integer type
    dbUInt,          ## some unsigned integer type
    dbDecimal,       ## decimal numbers (fixed-point number)
    dbFloat,         ## some floating point type
    dbDate,          ## a year-month-day description
    dbTime,          ## HH:MM:SS information
    dbDatetime,      ## year-month-day and HH:MM:SS information,
                     ## plus optional time or timezone information
    dbTimestamp,     ## Timestamp values are stored as the number of seconds
                     ## since the epoch ('1970-01-01 00:00:00' UTC).
    dbTimeInterval,  ## an interval [a,b] of times
    dbEnum,          ## some enum
    dbSet,           ## set of enum values
    dbArray,         ## an array of values
    dbComposite,     ## composite type (record, struct, etc)
    dbUrl,           ## a URL
    dbUuid,          ## a UUID
    dbInet,          ## an IP address
    dbMacAddress,    ## a MAC address
    dbGeometry,      ## some geometric type
    dbPoint,         ## Point on a plane   (x,y)
    dbLine,          ## Infinite line ((x1,y1),(x2,y2))
    dbLseg,          ## Finite line segment   ((x1,y1),(x2,y2))
    dbBox,           ## Rectangular box   ((x1,y1),(x2,y2))
    dbPath,          ## Closed or open path (similar to polygon) ((x1,y1),...)
    dbPolygon,       ## Polygon (similar to closed path)   ((x1,y1),...)
    dbCircle,        ## Circle   <(x,y),r> (center point and radius)
    dbUser1,         ## user definable datatype 1 (for unknown extensions)
    dbUser2,         ## user definable datatype 2 (for unknown extensions)
    dbUser3,         ## user definable datatype 3 (for unknown extensions)
    dbUser4,         ## user definable datatype 4 (for unknown extensions)
    dbUser5          ## user definable datatype 5 (for unknown extensions)
  DbType* = object              ## describes a database type
    kind*: DbTypeKind           ## the kind of the described type
    notNull*: bool              ## does the type contain NULL?
    name*: string               ## the name of the type
    size*: Natural              ## the size of the datatype; 0 if of variable size
    maxReprLen*: Natural        ## maximal length required for the representation
    precision*, scale*: Natural ## precision and scale of the number
    min*, max*: BiggestInt      ## the minimum and maximum of allowed values
    validValues*: seq[string]   ## valid values of an enum or a set
  DbColumn* = object   ## information about a database column
    name*: string      ## name of the column
    tableName*: string ## name of the table the column belongs to (optional)
    typ*: DbType       ## type of the column
    primaryKey*: bool  ## is this a primary key?
    foreignKey*: bool  ## is this a foreign key?
  DbColumns* = seq[DbColumn]
  DbRows* = seq[DbColumns]

  DbEffect* = object of IOEffect ## effect that denotes a database operation
  ReadDbEffect* = object of DbEffect ## effect that denotes a read operation
  WriteDbEffect* = object of DbEffect ## effect that denotes a write operation

const errorConnectionNum* = 99999


proc getFreeConn*(self:Connections):Future[int] {.async.} =
  let calledAt = getTime().toUnix()
  while true:
    for i in 0..<self.pools.len:
      if not self.pools[i].isBusy:
        self.pools[i].isBusy = true
        # echo "=== getFreeConn ", i
        return i
        break
    await sleepAsync(10)
    if getTime().toUnix() >= calledAt + self.timeout:
      return errorConnectionNum


proc returnConn*(self: Connections, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools[i].isBusy = false
  # echo "=== returnConn ", i


proc randStr*(n:int):string =
  randomize()
  for _ in 0..<n:
    add(result, char(rand(int('a')..int('z'))))
