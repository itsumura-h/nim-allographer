import strutils

func getOsName*():string =
  const f = staticRead("/etc/os-release")
  for row in f.split("\n"):
    let kv = row.split("=")
    if kv[0] == "ID":
      return kv[1]

func isExistsSqlite*():bool =
  when defined(macosx):
    const query = "ldconfig -p | grep libsqlite3.dylib" # TODO
    const res = gorgeEx(query)
    return res.exitCode == 0 and res.output.len > 0
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
    const query = "ldconfig -p | grep libmysqlclient.dylib" # TODO
    const res = gorgeEx(query)
    return res.exitCode == 0 and res.output.len > 0
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
    const query = "ldconfig -p | grep libmariadb.dylib" # TODO
    const res = gorgeEx(query)
    return res.exitCode == 0 and res.output.len > 0
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
    const query = "ldconfig -p | grep libpq.dylib" # TODO
    const res = gorgeEx(query)
    return res.exitCode == 0 and res.output.len > 0
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
