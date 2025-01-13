import std/json
import std/strformat
import std/asyncdispatch
import std/oids
import std/times
import ../../../../src/allographer/query_builder
import ../../connection
import ../../schema

proc postSeeder*() {.async.} =
  let postCount = rdb.table("post").count().await
  if postCount > 0:
    return

  let users = rdb.table("user").get().orm(UserTable).await
  if users.len == 0:
    raise newException(ValueError, "No users found in database")

  var posts: seq[JsonNode]
  for i in 0..<users.len:
    let row = PostTable(
      id: $genOid(),
      title: &"post {i}",
      content: &"content {i}",
      user_id: users[i].id,
      created_at: now().format("yyyy-MM-dd HH:mm:ss"),
      updated_at: now().format("yyyy-MM-dd HH:mm:ss")
    )
    posts.add(%row)
  
  rdb.table("post").insert(posts).await
