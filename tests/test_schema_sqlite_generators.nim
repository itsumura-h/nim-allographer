discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import ../src/allographer/schema_builder
include ../src/allographer/schema_builder/queries/sqlite/impl


suite("schema sqlite generator"):
  test("serial"):
    check Column.increments("id").serialGenerator() ==
      "'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"

  test("int"):
    check Column.integer("int").intGenerator() ==
      "'int' INTEGER NOT NULL"

  test("nullable"):
    check Column.integer("int").nullable().intGenerator() ==
      "'int' INTEGER"

  test("nullable"):
    check Column.integer("int").nullable().unique().intGenerator() ==
      "'int' INTEGER UNIQUE"

  test("default"):
    check Column.integer("int").nullable().default(0).intGenerator() ==
      "'int' INTEGER DEFAULT 0"

  test("unsigned"):
    check Column.integer("int").nullable().unsigned().intGenerator() ==
      "'int' INTEGER CHECK (int > 0)"

    check Column.integer("int").unsigned().intGenerator() ==
      "'int' INTEGER NOT NULL CHECK (int > 0)"

  test("decimal"):
    check Column.decimal("decimal", 5, 3).decimalGenerator() ==
      "'decimal' NUMERIC NOT NULL"

  test("decimal nullable"):
    check Column.decimal("decimal", 5, 3).nullable().decimalGenerator() ==
      "'decimal' NUMERIC"

  test("decimal defualt"):
    check Column.decimal("decimal", 5, 3).nullable().default(0.0).decimalGenerator() ==
      "'decimal' NUMERIC DEFAULT 0.0"

  test("unsigned unique"):
    check Column.decimal("decimal", 5, 3).nullable().unsigned().decimalGenerator() ==
      "'decimal' NUMERIC CHECK (decimal > 0)"

    check Column.decimal("decimal", 5, 3).unsigned().decimalGenerator() ==
      "'decimal' NUMERIC NOT NULL CHECK (decimal > 0)"

  test("float"):
    check Column.float("decimal").floatGenerator() ==
      "'decimal' REAL NOT NULL"

  test("float nullable"):
    check Column.float("decimal").nullable().floatGenerator() ==
      "'decimal' REAL"

  test("unique unique"):
    check Column.float("decimal").nullable().unique().floatGenerator() ==
      "'decimal' REAL UNIQUE"

  test("default default"):
    check Column.float("decimal").nullable().default(0.0).floatGenerator() ==
      "'decimal' REAL DEFAULT 0.0"

  test("float unsigned"):
    check Column.float("decimal").nullable().unsigned().floatGenerator() ==
      "'decimal' REAL CHECK (decimal > 0)"

  test("char"):
    check Column.char("char", 255).charGenerator() ==
      "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

  test("char nullable"):
    check Column.char("char", 255).nullable().charGenerator() ==
      "'char' VARCHAR CHECK (length('char') <= 255)"

  test("char unique"):
    check Column.char("char", 255).nullable().unique().charGenerator() ==
      "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

  test("char default"):
    check Column.char("char", 255).nullable().default("").charGenerator() ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

  test("varchar"):
    check Column.string("char").varcharGenerator() ==
      "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

  test("vachar nullable"):
    check Column.string("char").nullable().varcharGenerator() ==
      "'char' VARCHAR CHECK (length('char') <= 255)"

  test("varchar unique"):
    check Column.string("char").nullable().unique().varcharGenerator() ==
      "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

  test("varchar default"):
    check Column.string("char").nullable().default("").varcharGenerator() ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

  test("text"):
    check Column.text("char").textGenerator() ==
      "'char' TEXT NOT NULL"

  test("nullable nullable"):
    check Column.text("char").nullable().textGenerator() ==
      "'char' TEXT"

  test("unique unique"):
    check Column.text("char").nullable().unique().textGenerator() ==
      "'char' TEXT UNIQUE"

  test("text default"):
    check Column.text("char").nullable().default("").textGenerator() ==
      "'char' TEXT DEFAULT ''"

  test("date"):
    check Column.date("date").dateGenerator() ==
      "'date' DATE NOT NULL"

  test("date nullable"):
    check Column.date("date").nullable().dateGenerator() ==
      "'date' DATE"

  test("date unique"):
    check Column.date("date").nullable().unique().dateGenerator() ==
      "'date' DATE UNIQUE"

  test("date default"):
    check Column.date("date").nullable().default().dateGenerator() ==
      "'date' DATE DEFAULT CURRENT_TIMESTAMP"

  test("datetime"):
    check Column.datetime("date").datetimeGenerator() ==
      "'date' DATETIME NOT NULL"

  test("datetime nullable"):
    check Column.datetime("date").nullable().datetimeGenerator() ==
      "'date' DATETIME"

  test("datetime unique"):
    check Column.datetime("date").nullable().unique().datetimeGenerator() ==
      "'date' DATETIME UNIQUE"

  test("datetime default"):
    check Column.datetime("date").nullable().default().datetimeGenerator() ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test("time"):
    check Column.time("date").timeGenerator() ==
      "'date' TIME NOT NULL"

  test("time nullable"):
    check Column.time("date").nullable().timeGenerator() ==
      "'date' TIME"

  test("time unique"):
    check Column.time("date").nullable().unique().timeGenerator() ==
      "'date' TIME UNIQUE"

  test("time default"):
    check Column.time("date").nullable().default().timeGenerator() ==
      "'date' TIME DEFAULT CURRENT_TIMESTAMP"

  test("timestamp"):
    check Column.timestamp("date").timestampGenerator() ==
      "'date' DATETIME NOT NULL"

  test("timestamp nullable"):
    check Column.timestamp("date").nullable().timestampGenerator() ==
      "'date' DATETIME"

  test("timestamp unique"):
    check Column.timestamp("date").nullable().unique().timestampGenerator() ==
      "'date' DATETIME UNIQUE"

  test("timestamp default"):
    check Column.timestamp("date").nullable().default().timestampGenerator() ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test("timestamps"):
    check Column.timestamps().timestampsGenerator() ==
      "'created_at' DATETIME DEFAULT CURRENT_TIMESTAMP, 'updated_at' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test("softDelete"):
    check Column.softDelete().softDeleteGenerator() ==
      "'deleted_at' DATETIME"

  test("binary"):
    check Column.binary("blob").blobGenerator() ==
      "'blob' BLOB NOT NULL"

  test("binary nullable"):
    check Column.binary("blob").nullable().blobGenerator() ==
      "'blob' BLOB"

  test("binary default"):
    check Column.binary("blob").nullable().default().blobGenerator() ==
      "'blob' BLOB DEFAULT ''"

  test("boolean"):
    check Column.boolean("bool").boolGenerator() ==
      "'bool' TINYINT NOT NULL"

  test("boolean nullable"):
    check Column.boolean("bool").nullable().boolGenerator() ==
      "'bool' TINYINT"

  test("boolean unique"):
    check Column.boolean("bool").nullable().unique().boolGenerator() ==
      "'bool' TINYINT UNIQUE"

  test("boolean default"):
    check Column.boolean("bool").nullable().default(false).boolGenerator() ==
      "'bool' TINYINT DEFAULT false"

    check Column.boolean("bool").nullable().default(true).boolGenerator() ==
      "'bool' TINYINT DEFAULT true"

  test("enum"):
    check Column.enumField("enum", ["a", "b"]).enumGenerator() ==
      "'enum' VARCHAR NOT NULL CHECK (enum = 'a' OR enum = 'b')"

  test("enum nullable"):
    check Column.enumField("enum", ["a", "b"]).nullable().enumGenerator() ==
      "'enum' VARCHAR CHECK (enum = 'a' OR enum = 'b')"

  test("enum unique"):
    check Column.enumField("enum", ["a", "b"]).nullable().unique().enumGenerator() ==
      "'enum' VARCHAR UNIQUE CHECK (enum = 'a' OR enum = 'b')"

  test("enum default"):
    check Column.enumField("enum", ["a", "b"]).nullable().default("a").enumGenerator() ==
      "'enum' VARCHAR DEFAULT 'a' CHECK (enum = 'a' OR enum = 'b')"

  test("json"):
    check Column.json("json").jsonGenerator() ==
      "'json' TEXT NOT NULL"

  test("json nullable"):
    check Column.json("json").nullable().jsonGenerator() ==
      "'json' TEXT"

  test("json unique"):
    check Column.json("json").nullable().unique().jsonGenerator() ==
      "'json' TEXT UNIQUE"

  test("json default"):
    check Column.json("json").nullable().default(%*{"key":"value"}).jsonGenerator() ==
      """'json' TEXT DEFAULT '{
  "key": "value"
}'"""

  test("foreign"):
    check Column.foreign("auth_id").nullable().foreignColumnGenerator() == "'auth_id' INTEGER"
    check Column.foreign("auth_id").reference("id").on("auth").onDelete(RESTRICT).foreignGenerator() ==
      "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE RESTRICT"
    check Column.foreign("auth_id").reference("id").on("auth").onDelete(CASCADE).foreignGenerator() ==
      "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE CASCADE"
    check Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL).foreignGenerator() ==
      "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE SET NULL"
    check Column.foreign("auth_id").reference("id").on("auth").onDelete(NO_ACTION).foreignGenerator() ==
      "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE NO ACTION"
