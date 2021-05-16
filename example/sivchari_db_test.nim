import json, options
import database
import ../src/allographer/query_builder

echo rdb().table("users").limit(2).get()
echo rdb().table("users").first().get()

rdb().table("users").insertID(%*{
  "name": "aaa",
  "auth_id": 1
})
