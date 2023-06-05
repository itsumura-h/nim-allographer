import std/asyncdispatch
import std/times
import std/json
import std/options
import ../src/allographer/connection
import ../src/allographer/query_builder

proc main() {.async.} =
  let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).await
  surreal.raw("DELETE types").exec().await
  surreal.raw("DELETE auth").exec().await
  surreal.raw("DELETE user").exec().await

  surreal.table("types").insert(%*[
    {
      "bool":true,
      "string": "alice",
      "int": 1,
      "float": 3.14,
      "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz"),
      "null": nil
    },
    {
      "bool":false,
      "string": "bob",
      "int": 2,
      "float": 1.11,
      "datetime": (now() + initDuration(days=1)).format("yyyy-MM-dd'T'HH:mm:sszzz"),
      "null": nil
    }
  ])
  .await
  
  block :
    echo "=== get"
    echo surreal.table("types").get().await
  
  block:
    echo "=== first"
    let res = surreal.table("types").first().await
    if res.isSome():
      echo res.get()

  block:
    echo "=== find"
    let id = SurrealId.new("types:64t0w6gpnye7tdf083ch")
    let res = surreal.table("types").find(id).await
    if res.isSome():
      echo res.get()

  block:
    echo "=== where"
    let adminId = surreal.table("auth").insertId(%*{"name": "admin"}).await
    surreal.table("auth").insert(%*{"name": "editor"}).await
    echo surreal.table("auth").get().await
    surreal.table("user").insert(%*{"name":"alice", "email":"alice@example.com", "auth": adminId}).await

    let res = surreal.table("user").where("name", "=", "alice").first().await
    if res.isSome():
      echo res.get().pretty()

  block:
    echo "=== fetch"
    let alice = surreal.table("user").where("auth.name", "=", "admin").fetch("auth").first().await
    if alice.isSome():
      echo alice.get().pretty()

main().waitFor
