import std/asyncdispatch
import std/os
import ./data/user_seeder
import ./data/post_seeder

proc seed() {.async.} =
  let env = getEnv("APP_ENV")
  if env != "develop":
    raise newException(CatchableError, "This command is only available in the develop environment")

  userSeeder().await
  postSeeder().await


seed().waitFor()
