import std/asyncdispatch
import std/json
import std/random
import std/times
import ../src/allographer/query_builder
import ../src/allographer/schema_builder
import ../src/allographer/query_builder/libs/sqlite/sqlite_impl
from connections import rdb

randomize()

rdb.create(
  table("num_table", [
    Column.integer("id"),
    Column.integer("randomnumber")
  ])
)

seeder rdb, "num_table":
  var data = newSeq[JsonNode]()
  for i in 1..10000:
    data.add(%*{"id": i, "randomnumber": rand(10000)})
  rdb.table("num_table").insert(data).waitFor

let start = cpuTime()
(proc(){.async.}=
  let conn = rdb.pools.conns[0].conn
  let stmt = await conn.prepare("select * from num_table where id = ?", 30)
  let resultSet = await conn.preparedQuery(@["1"], stmt)
  echo resultSet[0]
)()
.waitFor
echo cpuTime() - start
