discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import strformat
import std/json
import std/strutils
import std/options
import std/asyncdispatch
import ../../src/allographer/query_builder
import ../../src/allographer/schema_builder
import ./connection

type
  Auth = ref object
    id:int
    name:string

  User = ref object
    id:int
    name:string
    authId:int
    bool:bool
    float:float

  JoinedUser = ref object
    userId:int
    userName:string
    bool:bool
    float:float
    authId:int
    authName:string


proc setUp(rdb:MysqlConnections) =
  rdb.create([
    table("auth",[
      Column.increments("id"),
      Column.string("name")
    ]),
    table("user",[
      Column.increments("id"),
      Column.string("name"),
      Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL),
      Column.boolean("bool"),
      Column.float("float"),
    ])
  ])

  # seeder
  seeder(rdb, "auth"):
    rdb.table("auth").insert(@[
      %*{"name": "admin"},
      %*{"name": "user"}
    ])
    .waitFor()

  seeder(rdb, "user"):
    var types: seq[JsonNode]
    for i in 1..10:
      let b = i mod 2 > 0
      let authId = if i mod 2 == 0: 2 else: 1
      types.add(
        %*{
          "name": &"user{i}",
          "auth_id": authId,
          "bool": b,
          "float": i,
        }
      )

    rdb.table("user").insert(types).waitFor()


let rdb = mysql

suite("return type"):
  setup(rdb)

  suite("get"):
    test("auth"):
      let auths = rdb
                  .table("auth")
                  .orderBy("id", Asc)
                  .get(Auth)
                  .waitFor()
      check auths[0].id == 1
      check auths[0].name == "admin"
      check auths[1].id == 2
      check auths[1].name == "user"


    test("user"):
      let users = rdb
                  .select("id", "name", "auth_id as authId", "bool", "float")
                  .table("user")
                  .orderBy("id", Asc)
                  .get(User)
                  .waitFor()
      check users[0].id == 1
      check users[0].name == "user1"
      check users[0].authId == 1
      check users[0].bool == true
      check users[0].float == 1.0


    test("join typ and relation"):
      let joinedUsers = rdb
                  .select(
                    "user.id as userId",
                    "user.name as userName",
                    "bool",
                    "float",
                    "auth.id as authId",
                    "auth.name as authName"
                  )
                  .table("user")
                  .join("auth", "auth.id", "=", "user.auth_id")
                  .orderBy("user.id", Asc)
                  .get(JoinedUser)
                  .waitFor()
      check joinedUsers[0].userId == 1
      check joinedUsers[0].userName == "user1"
      check joinedUsers[0].bool == true
      check joinedUsers[0].float == 1.0
      check joinedUsers[0].authId == 1
      check joinedUsers[0].authName == "admin"


  suite("first"):
    test("auth"):
      let auth = rdb
                  .table("auth")
                  .orderBy("id", Asc)
                  .first(Auth)
                  .waitFor()
                  .get()
      check auth.id == 1
      check auth.name == "admin"


    test("user"):
      let user = rdb
                  .select("id", "name", "auth_id as authId", "bool", "float")
                  .table("user")
                  .orderBy("id", Asc)
                  .first(User)
                  .waitFor()
                  .get()
      check user.id == 1
      check user.name == "user1"
      check user.authId == 1
      check user.bool == true
      check user.float == 1.0


    test("join auth and user"):
      let user = rdb
                  .select(
                    "user.id as userId",
                    "user.name as userName",
                    "bool",
                    "float",
                    "auth_id as authId",
                    "auth.name as authName"
                  )
                  .table("user")
                  .join("auth", "auth.id", "=", "user.auth_id")
                  .orderBy("user.id", Asc)
                  .first(JoinedUser)
                  .waitFor()
                  .get()
      check user.userId == 1
      check user.userName == "user1"
      check user.bool == true
      check user.float == 1.0
      check user.authId == 1
      check user.authName == "admin"


  suite("find"):
    test("auth"):
      let auth = rdb
                  .table("auth")
                  .orderBy("id", Asc)
                  .find(1, Auth)
                  .waitFor()
                  .get()
      check auth.id == 1
      check auth.name == "admin"


    test("user"):
      let user = rdb
                  .select("id", "name", "auth_id as authId", "bool", "float")
                  .table("user")
                  .orderBy("id", Asc)
                  .find(1, User)
                  .waitFor()
                  .get()
      check user.id == 1
      check user.name == "user1"
      check user.authId == 1
      check user.bool == true
      check user.float == 1.0


    test("join auth and user"):
      let user = rdb
                  .select(
                    "user.id as userId",
                    "user.name as userName",
                    "bool",
                    "float",
                    "auth_id as authId",
                    "auth.name as authName"
                  )
                  .table("user")
                  .join("auth", "auth.id", "=", "user.auth_id")
                  .orderBy("user.id", Asc)
                  .find(1, JoinedUser, key="user.id")
                  .waitFor()
                  .get()
      check user.userId == 1
      check user.userName == "user1"
      check user.bool == true
      check user.float == 1.0
      check user.authId == 1
      check user.authName == "admin"


rdb.raw("DROP TABLE IF EXISTS `user`").exec().waitFor()
rdb.raw("DROP TABLE IF EXISTS `auth`").exec().waitFor()
