import json, random, asyncdispatch, strutils
import faker
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
from connections import rdb

echo rdb.repr
# let fake = newFaker("ja_JP")

# rdb.schema(
#   table("posts", [
#     Column().increments("id"),
#     Column().string("content")
#   ])
# )

# var data:seq[JsonNode]
# for _ in 1..10:
#   data.add(%*{
#     "content": fake.word()
#   })
# waitFor rdb.table("posts").insert(data)

# echo waitFor rdb.table("posts").get()
