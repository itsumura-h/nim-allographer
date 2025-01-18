type
  DbError* = object of IOError ## exception that is raised if a database error occurs

proc dbError*(msg: string) {.noreturn, noinline.} =
  ## raises an DbError exception with message `msg`.
  var e: ref DbError
  new(e)
  e.msg = msg
  raise e
