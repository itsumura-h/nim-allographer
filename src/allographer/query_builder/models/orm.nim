import std/asyncdispatch
import std/options
import std/json

proc orm*[T](response:Future[seq[JsonNode]], typ:typedesc[T]):Future[seq[T]] {.async.} =
  let response = response.await
  var result = newSeq[T](response.len)
  for i, res in response:
    result[i] = res.to(typ)
  return result


proc orm*[T](response:Future[Option[JsonNode]], typ:typedesc[T]):Future[Option[T]] {.async.} =
  let response = response.await
  if response.isSome:
    return response.get.to(typ).some()
  else:
    return none(T)
