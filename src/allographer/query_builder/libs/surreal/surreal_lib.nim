import std/strutils
import std/json


proc looksLikeRecordId(s: string): bool =
  let colonPos = s.find(':')
  if colonPos <= 0 or colonPos >= s.high:
    return false
  if s.find(':', colonPos + 1) >= 0:
    return false
  if s.contains(' ') or s.contains('"') or s.contains('\''):
    return false
  if not (s[0].isAlphaAscii or s[0] == '_'):
    return false
  for ch in s[1 ..< colonPos]:
    if not (ch.isAlphaNumeric or ch == '_'):
      return false
  for ch in s[colonPos + 1 .. ^1]:
    if ch.isSpaceAscii:
      return false
  return true


proc looksLikeDateTimeValue(s: string): bool =
  if s.len < 10:
    return false

  for idx in [0, 1, 2, 3, 5, 6, 8, 9]:
    if idx >= s.len or not s[idx].isDigit:
      return false

  if s[4] != '-' or s[7] != '-':
    return false

  if s.len == 10:
    return true

  if s.len < 19:
    return false

  if s[10] notin {'T', ' '}:
    return false

  for idx in [11, 12, 14, 15, 17, 18]:
    if idx >= s.len or not s[idx].isDigit:
      return false

  if s[13] != ':' or s[16] != ':':
    return false

  if s.len == 19:
    return true

  return s[19] in {'.', 'Z', '+', '-'}


proc dbQuote(s:string):string =
  ## DB quotes the string.
  if s == "null":
    return "NULL"
  if looksLikeRecordId(s):
    return s
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


proc appendAlphabet(result: var string, n: int) =
  var n = n
  if n <= 0:
    return

  var chars: seq[char] = @[]
  while n > 0:
    n.dec()
    chars.add(chr(ord('a') + (n mod 26)))
    n = n div 26

  for i in countdown(chars.high, 0):
    result.add(chars[i])


proc dbFormat*(formatstr: string, args: varargs[string]): string =
  var a = 0
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


proc numToAlphabet*(n:int):string =
  ## 1 => "a", 26 => "z", 27 => "aa", 28 => "ab", 52 => "az", 53 => "ba"
  result = newStringOfCap(8)
  appendAlphabet(result, n)


proc questionToDaller*(s: string): string =
  ## from `UPDATE user SET name = ?, email = ? WHERE id = ?`
  ##
  ## to   `UPDATE user SET name = $a, email = $b WHERE id = $c`
  var i = 1
  var segStart = 0
  result = newStringOfCap(s.len + 8)
  for j in 0 ..< s.len:
    if s[j] == '?':
      if j > segStart:
        result.add(s[segStart ..< j])
      result.add('$')
      appendAlphabet(result, i)
      inc(i)
      segStart = j + 1
  if segStart < s.len:
    result.add(s[segStart ..< s.len])


proc appendJsonLetClause(result: var string, idx: int, arg: JsonNode, quoteString: bool) =
  result.add("LET $")
  appendAlphabet(result, idx)
  result.add(" = ")
  case arg.kind
  of JBool:
    result.add($arg.getBool)
  of JInt:
    result.add($arg.getInt)
  of JFloat:
    result.add($arg.getFloat)
  of JString:
    let val = arg.getStr().replace("\"", "\\\"")
    if looksLikeRecordId(val):
      result.add(val)
    elif looksLikeDateTimeValue(val):
      result.add("<datetime>\"")
      result.add(val)
      result.add("\"")
    elif quoteString:
      result.add('"')
      result.add(val)
      result.add('"')
    else:
      result.add(val)
  of JNull:
    result.add("NONE")
  of JArray, JObject:
    result.add($arg)
  result.add("; ")


proc dbFormatPrepared*(normalizedQueryString: string, args: JsonNode): string =
  ## `normalizedQueryString` should already have `?` converted to SurrealQL
  ## style placeholders.
  if args.isNil:
    result = newStringOfCap(normalizedQueryString.len)
    result.add(normalizedQueryString)
    return
  if args.kind == JNull:
    result = newStringOfCap(normalizedQueryString.len)
    result.add(normalizedQueryString)
    return

  result = newStringOfCap(normalizedQueryString.len + max(args.len, 1) * 24)
  if args.kind == JArray and args.len > 0:
    var i = 1
    for arg in args.items:
      appendJsonLetClause(result, i, arg, true)
      inc(i)
  elif args.kind == JObject and args.len > 0:
    var i = 1
    for (_, arg) in args.pairs:
      appendJsonLetClause(result, i, arg, false)
      inc(i)

  result.add(normalizedQueryString)


proc dbFormat*(queryString: string, args: JsonNode): string =
  result = dbFormatPrepared(queryString.questionToDaller(), args)
