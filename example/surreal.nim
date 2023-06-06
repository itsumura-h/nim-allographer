import std/asyncdispatch
import std/times
import std/json
import std/options
import ../src/allographer/connection
import ../src/allographer/query_builder

proc main() {.async.} =
  let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).await
  surreal.raw("DELETE type").exec().await

  surreal.table("type").insert(%*[
    {
      "bool":true,
      "string": "alice",
      "int": 1,
      "float": 3.14,
      "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
    },
    {
      "bool":false,
      "string": "bob",
      "int": 2,
      "float": 1.11,
      "datetime": (now() + initDuration(days=1)).format("yyyy-MM-dd'T'HH:mm:sszzz")
    }
  ])
  .await
  
  block :
    echo "=== get"
    echo surreal.table("type").get().await
  
  block:
    echo "=== first"
    let res = surreal.table("type").first().await
    if res.isSome():
      echo res.get()

  block:
    echo "=== find"
    let id = SurrealId.new("type:64t0w6gpnye7tdf083ch")
    let res = surreal.table("type").find(id).await
    if res.isSome():
      echo res.get()

  block:
    echo "=== where"
    surreal.raw("DELETE auth").exec().await
    surreal.raw("DELETE user").exec().await
    
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

  block:
    echo "=== update"
    surreal.raw("DELETE type").exec().await

    let id = surreal.table("type").insertId(%*{
      "bool":true,
      "string": "alice",
      "int": 1,
      "float": 3.14,
      "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
    })
    .await
    echo id.rawId()

    surreal.table("type").where("id", "=", id).update(%*{"string": "bob"}).await
    echo surreal.table("type").find(id).await

  block:
    echo "=== delete all"
    surreal.raw("DELETE type").exec().await

    let id = surreal.table("type").insertId(%*{
      "bool":true,
      "string": "alice",
      "int": 1,
      "float": 3.14,
      "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
    })
    .await

    surreal.table("type").delete().await
    echo surreal.table("type").get().await

  block:
    echo "=== delete row"
    surreal.raw("DELETE type").exec().await

    surreal.table("type").insert(%*[
    {
      "bool":true,
      "string": "alice",
      "int": 1,
      "float": 3.14,
      "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
    },
    {
      "bool":false,
      "string": "bob",
      "int": 2,
      "float": 1.11,
      "datetime": (now() + initDuration(days=1)).format("yyyy-MM-dd'T'HH:mm:sszzz")
    }])
    .await

    let row = surreal.table("type").where("string", "=", "alice").first().await.get()
    let rowId = SurrealId.new(row["id"].getStr())

    surreal.table("type").where("id", "=", rowId).delete().await
    echo surreal.table("type").get().await

  block:
    echo "=== raw"
    surreal.table("type").delete().await

    let define = """
REMOVE TABLE type;
DEFINE TABLE type SCHEMAFULL;
DEFINE FIELD index ON TABLE type TYPE int;
DEFINE INDEX types_index ON TABLE type COLUMNS index UNIQUE;
DEFINE FIELD bool ON TABLE type TYPE bool;
DEFINE FIELD datetime ON TABLE type TYPE datetime;
DEFINE FIELD float ON TABLE type TYPE float;
DEFINE FIELD int ON TABLE type TYPE int;
DEFINE FIELD string ON TABLE type TYPE string;
"""
    surreal.raw(define).exec().await()

    echo surreal.raw("INFO FOR TABLE type").info().await

    var rows = surreal.raw("SELECT * FROM type").get().await
    let max = rows.len + 1

    surreal.raw("""
      CREATE type CONTENT {
        index: ?,
        bool: true,
        datetime: ?,
        float: 1.11,
        int: 1,
        string: "aaa"
      }
    """,
    $max, now().format("yyyy-MM-dd'T'HH:mm:sszzz"))
    .exec()
    .await

    rows = surreal.raw("SELECT * FROM type").get().await
    echo rows

  block:
    echo "=== count"
    surreal.table("user").delete().await

    surreal.table("user").insert(%*[
      {"name": "alice", "email": "alice@example.com"},
      {"name": "bob", "email": "bob@example.com"},
      {"name": "charlie", "email": "charlie@example.com"},
    ])
    .await

    let count = surreal.table("user").count().await
    echo count

  block:
    echo "=== max"
    surreal.table("user").delete().await

    surreal.table("user").insert(%*[
      {"name": "alice", "email": "alice@example.com", "index": 1},
      {"name": "bob", "email": "bob@example.com", "index": 2},
      {"name": "charlie", "email": "charlie@example.com", "index": 3},
    ])
    .await

    let max = surreal.table("user").max("index").await
    echo max

  block:
    echo "=== min"
    surreal.table("user").delete().await

    surreal.table("user").insert(%*[
      {"name": "alice", "email": "alice@example.com", "index": 1},
      {"name": "bob", "email": "bob@example.com", "index": 2},
      {"name": "charlie", "email": "charlie@example.com", "index": 3},
    ])
    .await

    let min = surreal.table("user").min("index").await
    echo min


main().waitFor
