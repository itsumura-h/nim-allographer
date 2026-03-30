import std/json
import std/options
import std/macros


type PreparedParam* = object
  value*: string
  isNull*: bool


proc nullPreparedParam*(): PreparedParam =
  result.isNull = true


proc toPreparedParam*(v: string): PreparedParam =
  result.value = v


proc toPreparedParam*(v: cstring): PreparedParam =
  if v.isNil:
    return nullPreparedParam()
  result.value = $v


proc toPreparedParam*(v: bool): PreparedParam =
  result.value = if v: "1" else: "0"


proc toPreparedParam*[T: SomeInteger](v: T): PreparedParam =
  result.value = $v


proc toPreparedParam*[T: SomeFloat](v: T): PreparedParam =
  result.value = $v


proc toPreparedParam*(v: JsonNode): PreparedParam =
  if v.isNil or v.kind == JNull:
    return nullPreparedParam()

  case v.kind
  of JBool:
    result.value = if v.getBool: "1" else: "0"
  of JInt:
    result.value = $v.getInt
  of JFloat:
    result.value = $v.getFloat
  of JString:
    result.value = v.getStr
  of JArray, JObject:
    result.value = v.pretty
  of JNull:
    discard


proc toPreparedParam*[T](v: Option[T]): PreparedParam =
  if v.isSome:
    return toPreparedParam(v.get)
  return nullPreparedParam()


proc toPreparedParam*[T](v: T): PreparedParam =
  result.value = $v


proc toPreparedParams*(args: seq[string]): seq[PreparedParam] =
  result = newSeq[PreparedParam](args.len)
  for i, arg in args:
    if arg == "NULL" or arg == "null":
      result[i] = nullPreparedParam()
    else:
      result[i] = toPreparedParam(arg)


proc toPreparedParams*(args: JsonNode): seq[PreparedParam] =
  if args.isNil or args.kind == JNull:
    return

  if args.kind == JArray:
    result = newSeq[PreparedParam](args.len)
    for i in 0 ..< args.len:
      result[i] = toPreparedParam(args[i])
    return

  result = @[toPreparedParam(args)]


proc preparedText*(param: PreparedParam): string =
  if param.isNull:
    return "NULL"
  return param.value


proc preparedTextSeq*(args: openArray[PreparedParam]): seq[string] =
  result = newSeq[string](args.len)
  for i, arg in args:
    result[i] = arg.preparedText


proc countQuestionMarks*(s: string): int =
  for ch in s:
    if ch == '?':
      inc result


proc buildPreparedArgsExpr*(args: NimNode): NimNode =
  let toPreparedParamSym = bindSym("toPreparedParam")
  let nullPreparedParamSym = bindSym("nullPreparedParam")
  var arr = nnkBracket.newTree()
  for arg in args:
    if arg.kind == nnkNilLit:
      arr.add(newCall(nullPreparedParamSym))
    else:
      arr.add(newCall(toPreparedParamSym, arg))
  result = newTree(nnkPrefix, ident("@"), arr)
