import json
import ../src/allographer/query_builder

discard RDB().table("World").where("Id", "=", 1).updateSql(%*{"randomNumber": 2})
