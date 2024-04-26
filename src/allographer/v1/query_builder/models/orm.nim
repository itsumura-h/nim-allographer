import std/asyncdispatch
import std/options
import std/json

proc orm*[T](response:Future[seq[JsonNode]], typ:typedesc[T]):Future[seq[T]] {.async.} =
  runnableExamples:
    type User = object
      id: int
      name: string

    let users = rdb.table("user").get().orm(User).await
    assert users[0].id == 1
    assert users[0].name == "John"

  let response = response.await
  var result = newSeq[T](response.len)
  for i, res in response:
    result[i] = res.to(typ)
  return result


proc orm*[T](response:Future[Option[JsonNode]], typ:typedesc[T]):Future[Option[T]] {.async.} =
  runnableExamples:
    type User = object
      id: int
      name: string

    let user = rdb.table("user").first().orm(User).await
    if not user.isSome():
      raise newException(CatchableError, "User not found")

    assert user.id == 1
    assert user.name == "John"

  let response = response.await
  if response.isSome:
    return response.get.to(typ).some()
  else:
    return none(T)
