import std/asyncdispatch
import std/os
import ./data/user_seeder
import ./data/post_seeder

proc seed() =
  let env = getEnv("APP_ENV")
  if env != "production":
    raise newException(Exception, "This command is only available in the production environment")

seed()
