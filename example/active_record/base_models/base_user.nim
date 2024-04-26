import std/asyncdispatch
import std/times
import std/options
import std/json
import ../connection


const tableName = "user"

type BaseUser = ref object of RootObj
  id*:int
  name*:string
  email*:string
  createdAt*:DateTime
  updatedAt*:DateTime


proc getBy(value:auto, columnName:string):Future[BaseUser] {.async.} =
  let resOpt = rdb.table(tableName).find(value, columnName).await
  if not resOpt.isSome():
    return
  let res = resOpt.get()
  return BaseUser(
    id: res["id"].getInt(),
    name: res["name"].getStr(),
    email: res["email"].getStr(),
    createdAt: res["created_at"].getStr().parse("yyyy-MM-dd hh:mm:ss"),
    updatedAt: res["updated_at"].getStr().parse("yyyy-MM-dd hh:mm:ss"),
  )


proc getById*(_:type BaseUser, id:int):Future[BaseUser] {.async.} =
  return getBy(id, "id").await

proc getByEmail*(_:type BaseUser, email:string):Future[BaseUser] {.async.} =
  return getBy(email, "email").await
