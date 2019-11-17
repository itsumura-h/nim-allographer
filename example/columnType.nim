import json

import ../src/allographer/QueryBuilder

echo RDB().table("users")
      .select("id", "name", "password as pass")
      .limit(3).get()

echo RDB().table("users")
        .select("id", "name", "password as pass")
        .first()

echo RDB().table("users")
    .select("id", "name", "password as pass")
    .find(3)
