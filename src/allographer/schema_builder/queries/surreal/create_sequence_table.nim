import std/asyncdispatch
import std/strformat
import std/json
import ../../../query_builder/models/surreal/surreal_types
import ../../../query_builder/models/surreal/surreal_query
import ../../../query_builder/models/surreal/surreal_exec
import ../../models/table


proc createSequenceTable*(rdb:SurrealConnections) =
  ## if _autoincrement_sequences table is not exists, create it
  let logDisplay = rdb.log.shouldDisplayLog
  let logFile = rdb.log.shouldOutputLogFile
  rdb.log.shouldDisplayLog = false
  rdb.log.shouldOutputLogFile = false
  defer:
    rdb.log.shouldDisplayLog = logDisplay
    rdb.log.shouldOutputLogFile = logFile

  let info = rdb.raw(&"INFO FOR DB").info().waitFor()
  if not info[0]["result"]["tb"].contains("_autoincrement_sequences"):
    rdb.raw(&"""
      DEFINE TABLE `_autoincrement_sequences`;
      DEFINE FIELD `table` ON TABLE `_autoincrement_sequences` TYPE string;
      DEFINE FIELD `column` ON TABLE `_autoincrement_sequences` TYPE string;
      DEFINE FIELD `max_index` ON TABLE `_autoincrement_sequences` TYPE int;
      DEFINE INDEX `_autoincrement_sequences_table_name_unique` ON TABLE `_autoincrement_sequences` COLUMNS `table`, `column` UNIQUE;
    """).exec().waitFor()


proc resetSequence*(rdb:SurrealConnections, table:Table) =
  rdb.table("_autoincrement_sequences").where("table", "=", table.name).delete().waitFor()
