import strformat, json, oids, asyncdispatch
import bcrypt
import ../src/allographer/query_builder
import ../src/allographer/schema_builder
import connections

# migration
rdb.schema([
  table("Auth",[
    Column().increments("id"),
    Column().string("auth")
  ]),
  table("Users",[
    Column().increments("id"),
    Column().string("oid").index().nullable(),
    Column().string("oid2").index(),
    Column().string("Name").nullable(),
    Column().string("email").nullable(),
    Column().string("password").nullable(),
    Column().string("address").nullable(),
    Column().date("birth_date").nullable(),
    Column().foreign("auth_id").reference("id").on("Auth").onDelete(SET_NULL).default(1)
  ]),
])

# seeder
# run query if Auth table is empty
seeder rdb, "Auth":
  waitFor rdb.table("Auth").insert(@[
    %*{"auth": "admin"},
    %*{"auth": "user"}
  ])

# run query if Users table is empty
seeder rdb, "Users", "Name":
  var insertData: seq[JsonNode]
  for i in 1..100:
    let salt = genSalt(10)
    let password = hash(&"password{i}", salt)
    let authId = if i mod 2 == 0: 1 else: 2
    insertData.add(
      %*{
        "oid": $(genOid()),
        "oid2": $(genOid()),
        "Name": &"user{i}",
        "email": &"user{i}@gmail.com",
        "password": password,
        "auth_id": authId
      }
    )
  waitFor rdb.table("Users").insert(insertData)
