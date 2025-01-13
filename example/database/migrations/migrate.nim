import std/asyncdispatch
import ../../../src/allographer/schema_builder
import ../connection
import ./init_databaase
import ./create_all_type_table

proc migrate*() =
  init_databaase()
  createAllTypeTable()

migrate()
createSchema(rdb).waitFor()
