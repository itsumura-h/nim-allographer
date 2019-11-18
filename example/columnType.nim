import json

import ../src/allographer/QueryBuilder

echo RDB().table("users").select("id", "name", "address")
    .limit(2).get()

echo RDB().table("users").select("id", "name", "address")
    .first()

echo RDB().table("users")
    .select("id", "name", "address")
    .find(3)


# echo RDB().table("users")
#         .select("id", "name", "password as pass")
#         .first()

# echo RDB().table("users")
#     .select("id", "name", "password as pass")
#     .find(3)
