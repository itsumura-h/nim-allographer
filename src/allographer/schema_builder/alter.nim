import ./table, ./column
import
  ./alters/sqlite_alter,
  ./alters/mysql_alter,
  ./alters/postgres_alter
import ../connection


proc alter*(tables:varargs[Table]) =
  for table in tables:
    let driver = getDriver()
    case driver:
    of "sqlite":
      sqlite_alter.exec(table)
    of "mysql":
      mysql_alter.exec(table)
    of "postgres":
      postgres_alter.exec(table)


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
