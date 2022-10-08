import
  std/asyncdispatch,
  std/json,
  std/random,
  std/times,
  ../src/allographer/query_builder,
  ../src/allographer/schema_builder,
  ../src/allographer/async/async_db
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
    let randomNum = rand(10000)
    data.add(%*{"id": i, "randomnumber": randomNum})
  rdb.table("num_table").insert(data).waitFor

let start = cpuTime()
let resp = newJArray()
(proc(){.async.}=
  let conn = rdb.conn
  let prepare = conn.prepare(PostgreSQL, "select * from num_table where id = $1", "12345").await
  let n = 100
  var futures = newSeq[Future[(seq[Row], DbRows)]](n)
  for i in 1..n:
    futures[i-1] = prepare.query(PostgreSQL, @[$i])
  
  let resArr = all(futures).await
  for row in resArr:
    let data = row[0]
    let dbInfo = row[1]
    echo data
    # resp.add(%*{dbInfo[0][0].name: data[0][0], dbInfo[0][1].name: data[0][1]})
)()
.waitFor
echo cpuTime() - start
