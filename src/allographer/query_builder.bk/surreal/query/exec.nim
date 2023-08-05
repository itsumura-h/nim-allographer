import std/asyncdispatch
import std/json
import ../../../env
import ../surreal_types
import ../databases/surreal_rdb
import ../databases/surreal_impl


proc query*(
  self: SurrealConnections,
  query: string,
  args: seq[string] = @[],
  specifiedConnI=false,
  connI=0
):Future[JsonNode] {.async.} =
  when isExistsSurrealdb:
    var connI = connI
    if not specifiedConnI:
      connI = getFreeConn(self).await
    defer:
      if not specifiedConnI:
        self.returnConn(connI).await
    if connI == errorConnectionNum:
      return
    return await query(self.pools[connI], query, args, self.timeout)


proc exec*(
  self: SurrealConnections,
  query: string,
  args: seq[string] = @[],
  specifiedConnI=false,
  connI=0
) {.async.} =
  when isExistsSurrealdb:
    var connI = connI
    if not specifiedConnI:
      connI = getFreeConn(self).await
    defer:
      if not specifiedConnI:
        self.returnConn(connI).await
    if connI == errorConnectionNum:
      return
    await exec(self.pools[connI], query, args, self.timeout)


proc info*(
  self: SurrealConnections,
  query: string,
  args: seq[string] = @[],
  specifiedConnI=false,
  connI=0
):Future[JsonNode] {.async.} =
  when isExistsSurrealdb:
    var connI = connI
    if not specifiedConnI:
      connI = getFreeConn(self).await
    defer:
      if not specifiedConnI:
        self.returnConn(connI).await
    if connI == errorConnectionNum:
      return
    return await info(self.pools[connI], query, args, self.timeout)
