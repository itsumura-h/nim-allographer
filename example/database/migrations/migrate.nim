import std/asyncdispatch
import ../../../src/allographer/schema_builder
import ../connection
import ./init_databaase
import ./create_all_type_table

proc migrate*() =
  initDatabaase()
  createAllTypeTable()

migrate()
createSchema(rdb).waitFor()
