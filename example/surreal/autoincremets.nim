import std/asyncdispatch
import std/json
import ../../src/allographer/query_builder
import ../../src/allographer/schema_builder
import ../../src/allographer/connection


let rdb = dbOpen(SurrealDB, "ns", "database", "user", "pass", "http://surreal", 8000, shouldDisplayLog=true).waitFor()

rdb.raw("""
  REMOVE TABLE `_sequences`;
  REMOVE EVENT `set_user_index` ON TABLE `user`;
  REMOVE TABLE `user`;
  REMOVE TABLE `auth`;
""").exec().waitFor()

rdb.raw("""
  DEFINE TABLE `_sequences`;
  DEFINE FIELD `table_name` ON TABLE `_sequences` TYPE string;
  DEFINE FIELD `max_index` ON TABLE `_sequences` TYPE int;
  DEFINE INDEX `_sequences_table_name_unique` ON TABLE `_sequences` COLUMNS `table_name` UNIQUE;
""").exec().waitFor()

rdb.raw("""
  DEFINE TABLE `user`;
  INSERT INTO `_sequences` {table_name: "user", max_index: 0};
  DEFINE FIELD `index` ON TABLE `user` TYPE int;
  DEFINE FIELD `name` ON TABLE `user` TYPE string;
""").exec().waitFor()

rdb.raw("""  
  DEFINE EVENT `set_user_index` ON TABLE `user` WHEN $event = "CREATE" THEN {
    LET $val = (SELECT `max_index` FROM `_sequences` WHERE `table_name` = "user" LIMIT 1)[0].max_index + 1;
    UPDATE `user` MERGE {index: $val} WHERE id = $after.id;
    UPDATE `_sequences` MERGE {max_index: $val} WHERE table_name = "user";
  };
""").exec().waitFor()

echo rdb.raw("""
  INSERT INTO `user` {name: "user1"};
  SELECT * FROM `user`;
  SELECT * FROM `_sequences`;
""").info().waitFor()

echo rdb.raw("""
  UPDATE `user` MERGE {name: "updated"} WHERE `name` = "user1";
  SELECT * FROM `user`;
  SELECT * FROM `_sequences`;
""").info().waitFor()


echo rdb.raw("""
  INSERT INTO `user` {name: "user2"};
  SELECT * FROM `user`;
  SELECT * FROM `_sequences`;
""").info().waitFor()

echo rdb.raw("""
  UPDATE `user` MERGE {name: "updated2"} WHERE `name` = "user2";
  SELECT * FROM `user`;
  SELECT * FROM `_sequences`;
""").info().waitFor()
