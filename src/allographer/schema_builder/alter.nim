import ./table, ./column
import
  ./alters/sqlite_alter,
  ./alters/mysql_alter,
  ./alters/postgres_alter
import ../async/async_db
import ../base


proc alter*(rdb:Rdb, tables:varargs[Table]) =
  for table in tables:
    case rdb.conn.driver:
    of SQLite3:
      sqlite_alter.exec(rdb, table)
    of MySQL, MariaDB:
      mysql_alter.exec(rdb, table)
    of PostgreSQL:
      postgres_alter.exec(rdb, table)


proc add*():Column =
  return Column(alterTyp:Add)

proc change*(name:string):Column =
  return Column(alterTyp:Change, previousName:name)

proc rename*(alterFrom, alterTo:string):Table =
  return Table(name:alterFrom, alterTo:alterTo, typ:Rename)

proc drop*(name:string):Table =
  return Table(name:name, typ:Drop)

proc delete*():Column =
  return Column(alterTyp: Delete)

proc column*(self:Column, name:string):Column =
  self.name = name
  return self
