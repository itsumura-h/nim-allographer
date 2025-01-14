import std/json
import std/strformat
import std/asyncdispatch
import std/oids
import std/times
import ../../../../src/allographer/query_builder
import ../../connection
import ../../schema

proc postSeeder*() {.async.} =
  seeder(rdb, "post"):
    let postCount = rdb.table("post").count().await
    if postCount > 0:
      return

    let users = rdb.table("user").get().orm(UserTable).await
    if users.len == 0:
      raise newException(ValueError, "No users found in database")

    var postList: seq[JsonNode]
    for i in 1..users.len:
      let row = PostTable(
        id: $genOid(),
        title: &"post {i}",
        content: &"content {i}",
        userId: users[i-1].id,
        createdAt: now().toTime().toUnix(),
        updatedAt: now().toTime().toUnix()
      )
      postList.add(%row)
    
    rdb.table("post").insert(postList).await
