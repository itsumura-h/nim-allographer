import std/strutils
import std/uri


type DatabaseUrl* = distinct string

type DatabaseUrlQuery* = tuple[key, value: string]

type ParsedDatabaseUrl* = object
  raw*: string
  scheme*: string
  username*: string
  password*: string
  hostname*: string
  port*: int
  hasPort*: bool
  path*: string
  query*: seq[DatabaseUrlQuery]


proc asDatabaseUrl*(value: string): DatabaseUrl =
  DatabaseUrl(value)


proc `$`*(value: DatabaseUrl): string =
  string(value)


proc parseQueryPairs(query: string): seq[DatabaseUrlQuery] =
  if query.len == 0:
    return

  for item in query.split('&'):
    if item.len == 0:
      continue

    let eqIndex = item.find('=')
    if eqIndex < 0:
      result.add((decodeUrl(item), ""))
    else:
      result.add((decodeUrl(item[0..<eqIndex]), decodeUrl(item[eqIndex + 1 .. ^1])))


proc parseDatabaseUrl*(value: string): ParsedDatabaseUrl =
  let parsed = parseUri(value)

  result.raw = value
  result.scheme = parsed.scheme.toLowerAscii()
  result.username = decodeUrl(parsed.username)
  result.password = decodeUrl(parsed.password)
  result.hostname = decodeUrl(parsed.hostname)
  result.path = decodeUrl(parsed.path)
  result.query = parseQueryPairs(parsed.query)

  if parsed.port.len > 0:
    result.port = parsed.port.parseInt()
    result.hasPort = true


proc parseDatabaseUrl*(value: DatabaseUrl): ParsedDatabaseUrl =
  parseDatabaseUrl(string(value))


proc requireDatabaseUrlScheme*(value: ParsedDatabaseUrl; expectedSchemes: openArray[string];
                               driverName: string) =
  if value.scheme.len == 0 or value.scheme notin expectedSchemes:
    raise newException(
      ValueError,
      "Invalid URL format. Expected a " & driverName & " URL starting with '" &
        expectedSchemes[0] & "://'."
    )


proc stripLeadingSlash(value: string): string =
  if value.len > 0 and value[0] == '/':
    if value.len == 1:
      return ""
    return value[1..^1]
  value


proc databaseName*(value: ParsedDatabaseUrl): string =
  stripLeadingSlash(value.path)


proc sqliteDatabasePath*(value: ParsedDatabaseUrl): string =
  if value.hostname.len == 0:
    return value.path

  let tail = stripLeadingSlash(value.path)
  if tail.len == 0:
    return value.hostname

  result = value.hostname & "/" & tail


proc portOrDefault*(value: ParsedDatabaseUrl; defaultPort: int): int =
  if value.hasPort:
    value.port
  else:
    defaultPort
