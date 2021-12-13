import std/[os,strutils]

func getOsName*():string =
  const f = staticRead("/etc/os-release")
  for row in f.split("\n"):
    let kv = row.split("=")
    if kv[0] == "ID":
      return kv[1]

func isExistsSqlite*():bool =
  when defined(macosx):
    const query = "brew --prefix sqlite"
    const res = gorgeEx(query)
    if res.exitCode == 0: return true
    const libPath = os.getEnv("DYLD_SQLITE_PATH", "/usr/lib/sqlite3.dylib")
    return fileExists( libPath )
  elif defined(linux) or defined(bsd):
    const osName = getOsName()
    when osName == "alpine":
      const query = "cat /lib/apk/db/installed | grep libsqlite3.so"
      const res = gorgeEx(query)
      return res.exitCode == 0 and res.output.len > 0
    else: # Ubuntu/Debian/CentOS...
      const query = "ldconfig -p | grep libsqlite3.so"
      const res = gorgeEx(query)
      return res.exitCode == 0 and res.output.len > 0
  else: # Windows
    # TODO
    return false

func isExistsMysql*():bool =
  when defined(macosx):
    const query = "brew --prefix mysql"
    const res = gorgeEx(query)
    if res.exitCode == 0: return true
    const libPath = os.getEnv("DYLD_MYSQL_PATH", "/usr/lib/libmysqlclient.dylib")
    return fileExists( libPath )
  elif defined(linux) or defined(bsd):
    const osName = getOsName()
    if osName == "alpine":
      return false
    else: # Ubuntu/Debian/CentOS...
      const query = "ldconfig -p | grep libmysqlclient.so"
      const res = gorgeEx(query)
      return res.exitCode == 0 and res.output.len > 0
  else: # Windows
    # TODO
    return false

func isExistsMariadb*():bool =
  when defined(macosx):
    const query = "brew --prefix mariadb"
    const res = gorgeEx(query)
    if res.exitCode == 0: return true
    const libPath = os.getEnv("DYLD_MARIADB_PATH", "/usr/lib/libmariadb.dylib")
    return fileExists( libPath )
  elif defined(linux) or defined(bsd):
    const osName = getOsName()
    if osName == "alpine":
      const query = "cat /lib/apk/db/installed | grep libmariadb.so"
      const res = gorgeEx(query)
      return res.exitCode == 0 and res.output.len > 0
    else: # Ubuntu/Debian/CentOS...
      const query = "ldconfig -p | grep -e libmysqlclient.so -e libmariadbclient.so"
      const res = gorgeEx(query)
      return res.exitCode == 0 and res.output.len > 0
  else: # Windows
    # TODO
    return false

func isExistsPostgres*():bool =
  when defined(macosx):
    const query = "brew --prefix postgres"
    const res = gorgeEx(query)
    if res.exitCode == 0: return true
    const libPath = os.getEnv("DYLD_POSTGRES_PATH", "/usr/lib/libpq.dylib")
    return fileExists( libPath )
  elif defined(linux) or defined(bsd):
    const osName = getOsName()
    if osName == "alpine":
      const query = "cat /lib/apk/db/installed | grep libpq.so"
      const res = gorgeEx(query)
      return res.exitCode == 0 and res.output.len > 0
    else: # Ubuntu/Debian/CentOS...
      const query = "ldconfig -p | grep libpq.so"
      const res = gorgeEx(query)
      return res.exitCode == 0 and res.output.len > 0
  else: # Windows
    # TODO
    return false
