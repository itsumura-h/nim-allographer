import std/strutils
import std/strformat
import std/json


proc dbQuote*(s:string):string =
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


proc dbFormat*(formatstr: string, args: varargs[string]): string =
  result = ""
  var a = 0
  for c in items(formatstr):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else:
      add(result, c)


proc numToAlphabet*(n:int):string =
  ## 1 => "a", 26 => "z", 27 => "aa", 28 => "ab", 52 => "az", 53 => "ba"
  var n = n
  result = ""
  while n > 0:
    n.dec()
    let quotient = n.div(26)
    let remainder = n.mod(26)
    result = chr(int('A') + remainder) & result
    n = quotient

  return result.toLower()


proc questionToDaller*(s:string):string =
  ## from `UPDATE user SET name = ?, email = ? WHERE id = ?`
  ## 
  ## to   `UPDATE user SET name = $a, email = $b WHERE id = $c`
  var i = 1
  for c in s:
    if c == '?':
      result.add(&"${numToAlphabet(i)}")
      i += 1
    else:
      result.add(c)


proc dbFormat*(queryString: string, args: JsonNode): string =
  result = ""
  var queryString = queryString.questionToDaller()
  var i = 0
  for c in items(queryString):
    if c == '?':
      result.add(&"${numToAlphabet(i)}")
      inc(i)
    else:
      add(result, c)

  var strArgs:seq[string]
  if args.kind == JArray and args.len > 0:
    var i = 1
    for arg in args.items:
      defer: i.inc()
      case arg.kind
      of JBool:
        strArgs.add(&"LET ${numToAlphabet(i)} = {$arg.getBool}; ")
      of JInt:
        strArgs.add(&"LET ${numToAlphabet(i)} = {$arg.getInt}; ")
      of JFloat:
        strArgs.add(&"LET ${numToAlphabet(i)} = {$arg.getFloat}; ")
      of JString:
        let val = arg.getStr()
        strArgs.add(&"""LET ${numToAlphabet(i)} = "{val}"; """)
      of JNull:
        strArgs.add(&"LET ${numToAlphabet(i)} = null; ")
      of JArray, JObject:
        strArgs.add(&"LET ${numToAlphabet(i)} = {$arg}; ")
  elif args.kind == JObject and args.len > 0:
    var i = 1
    for (key, arg) in args.pairs:
      defer: i.inc()
      case arg.kind
      of JBool:
        strArgs.add(&"LET ${numToAlphabet(i)} = {$arg.getBool}; ")
      of JInt:
        strArgs.add(&"LET ${numToAlphabet(i)} = {$arg.getInt}; ")
      of JFloat:
        strArgs.add(&"LET ${numToAlphabet(i)} = {$arg.getFloat}; ")
      of JString:
        strArgs.add(&"""LET ${numToAlphabet(i)} = \"{arg.getStr}\""; """)
      of JNull:
        strArgs.add(&"LET ${numToAlphabet(i)} = null; ")
      of JArray, JObject:
        strArgs.add(&"LET ${numToAlphabet(i)} = {$arg}; ")

  result = strArgs.join() & result
  return result
