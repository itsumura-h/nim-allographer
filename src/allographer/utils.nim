import strutils

func getOsName*():string =
  when defined(linux) or defined(bsd):
    const f = staticRead("/etc/os-release")
    for row in f.split("\n"):
      let kv = row.split("=")
      if kv[0] == "ID":
        return kv[1]
  elif defined(windows):
    return "windows"
  else:
    return ""
