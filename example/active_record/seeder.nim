import std/asyncdispatch
import std/json
import std/strformat
import std/strutils
import ../../src/allographer/query_builder
import ./connection


proc main() {.async.} =
  seeder(rdb, "user"):
    var user:seq[JsonNode]
    for i in 1..10:
      user.add(%*{
        "name": &"User {i}",
        "email": &"user{i}@example.com",
      })
    rdb.table("user").insert(user).await
    echo rdb.table("user").get().await


  seeder(rdb, "article"):
    for i in 1..10:
      if (i mod 2) == 0:
        rdb.table("article").insert(%*{
          "id": &"article-{i}",
          "title": &"Article {i}",
          "user_id": 1,
        }).await
      else:
        rdb.table("article").insert(%*{
          "id": &"article-{i}",
          "title": &"Article {i}",
          "content": &"Article {i} content",
          "user_id": 1,
        }).await
    echo rdb.table("article").get().await


  seeder(rdb, "tag"):
    var tags:seq[JsonNode]
    for i in 1..10:
      tags.add(%*{
        "id": &"tag-{i}",
        "name": &"Tag {i}",
      })
    rdb.table("tag").insert(tags).await
    echo rdb.table("tag").get().await


  seeder(rdb, "tag_article_map"):
    var tagArticleMap:seq[JsonNode]
    for i in 1..10:
      tagArticleMap.add(%*{
        "tag_id": &"tag-{i}",
        "article_id": &"article-{i}",
      })
    rdb.table("tag_article_map").insert(tagArticleMap).await
    echo rdb.table("tag_article_map").get().await


main().waitFor()
