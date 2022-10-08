import strformat, json, progress, asyncdispatch
import bcrypt

import ../src/allographer/query_builder
import ../src/allographer/schema_builder

from connections import rdb

rdb.create([
  table("auth",[
    Column.increments("id"),
    Column.string("auth")
  ]),
  table("users",[
    Column.increments("id"),
    Column.string("name").nullable(),
    Column.string("email").nullable(),
    Column.string("password").nullable(),
    Column.string("address").nullable(),
    Column.date("birth_date").nullable(),
    Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ])
])

# シーダー
seeder rdb, "auth":
  rdb.table("auth").insert(@[
    %*{"auth": "admin"},
    %*{"auth": "user"}
  ])
  .waitFor()

seeder rdb, "users":
  # プログレスバー
  let total = 20
  var pb = newProgressBar(total=total) # totalは分母

  pb.start()
  var insertData: seq[JsonNode]
  for i in 1..total:
    let salt = genSalt(10)
    let password = hash(&"password{i}", salt)
    let authId = if i mod 2 == 0: 1 else: 2
    insertData.add(
      %*{
        "name": &"user{i}",
        "email": &"user{i}@gmail.com",
        "password": password,
        "auth_id": authId
      }
    )
    pb.increment()
  pb.finish()

  rdb.table("users").insert(insertData).waitFor()

  echo rdb.table("users").get().waitFor()

echo rdb
    .table("users")
    .select("users.id", "users.email")
    .where("name", "=", "user3")
    .orWhere("name", "=", "user4")
    .orWhere("users.id", "=", 5)
    .join("auth", "auth.id", "=", "users.auth_id")
    .limit(10)
    .get()
    .waitFor()

echo rdb.table("users").select("id", "email").limit(5).get().waitFor()
echo rdb.table("users").select("id", "email").limit(5).first().waitFor()
echo rdb.table("users").find(4).waitFor()
echo rdb.table("users").select("id", "email").limit(5).find(3).waitFor()

echo ""

rdb.table("users").insert(%*{"name": "John", "email": "John@gmail.com"}).waitFor()
echo rdb.table("users").insertId(%*{"name": "John", "email": "John@gmail.com"}).waitFor()


rdb.table("users").insert(
  @[
      %*{"name": "John", "email": "John@gmail.com"},
      %*{"name": "Paul", "email": "Paul@gmail.com"}
  ]
)
.waitFor()

rdb.table("users").inserts(
  @[
      %*{"name": "Mick", "email": "Mick@gmail.com"},
      %*{"name": "Keith", "password": "KeithPass"}
  ]
)
.waitFor()


rdb.table("users").where("id", "=", 2).update(%*{"name": "David"}).waitFor()
rdb.table("users").where("id", "=", 2).update(%*{"name": "David"}).waitFor()
echo rdb.table("users").select().where("name", "=", "David").get().waitFor()
echo rdb.table("users").find(2).waitFor()

rdb.table("users").where("name", "=", "David").delete().waitFor()
rdb.table("users").delete(3).waitFor()
echo rdb.table("users").find(3).waitFor()
echo rdb.table("users").limit(5).get().waitFor()
echo rdb.table("users").select("name").where("address", "is", nil).get().waitFor()

# sql check
let r = rdb
    .table("users")
    .select("users.id", "users.email")
    .where("name", "=", "user3")
    .where("name", "=", "user4")
    .where("users.id", "=", 5)
    .orWhere("name", "=", "user6")
    .orWhere("users.id", "=", 7)
    .join("auth", "auth.id", "=", "users.auth_id")
    .limit(10)
    .get()
    .waitFor()
echo r[0]["id"]
echo r[0]["id"].type
echo r[0]["email"]
echo r[0]["email"].type

type User = ref object
  id:int
  name:string
  email:string
  password:string
  address:string
  birth_date:string
  auth_id:int
let users = rdb.table("users").limit(5).get(User).waitFor()
for user in users:
  echo user.name

waitFor rdb.raw("DROP TABLE users").exec()
waitFor rdb.raw("DROP TABLE auth").exec()
