discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest
include ../src/allographer/schema_builder/queries/sqlite/impl
import ../src/allographer/schema_builder


block:
  check Column.increments("id").serialGenerator() ==
    "'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"

block:
  check Column.integer("int").intGenerator() ==
    "'int' INTEGER NOT NULL"

block:
  check Column.integer("int").nullable().intGenerator() ==
    "'int' INTEGER"

block:
  check Column.integer("int").nullable().unique().intGenerator() ==
    "'int' INTEGER UNIQUE"

block:
  check Column.integer("int").nullable().default(0).intGenerator() ==
    "'int' INTEGER DEFAULT 0"

block:
  check Column.integer("int").nullable().unsigned().intGenerator() ==
    "'int' INTEGER CHECK (int > 0)"

  check Column.integer("int").unsigned().intGenerator() ==
    "'int' INTEGER NOT NULL CHECK (int > 0)"

block:
  check Column.decimal("decimal", 5, 3).decimalGenerator() ==
    "'decimal' NUMERIC NOT NULL"

block:
  check Column.decimal("decimal", 5, 3).nullable().decimalGenerator() ==
    "'decimal' NUMERIC"

block:
  check Column.decimal("decimal", 5, 3).nullable().default(0.0).decimalGenerator() ==
    "'decimal' NUMERIC DEFAULT 0.0"

block:
  check Column.decimal("decimal", 5, 3).nullable().unsigned().decimalGenerator() ==
    "'decimal' NUMERIC CHECK (decimal > 0)"

  check Column.decimal("decimal", 5, 3).unsigned().decimalGenerator() ==
    "'decimal' NUMERIC NOT NULL CHECK (decimal > 0)"

block:
  check Column.float("decimal").floatGenerator() ==
    "'decimal' REAL NOT NULL"

block:
  check Column.float("decimal").nullable().floatGenerator() ==
    "'decimal' REAL"

block:
  check Column.float("decimal").nullable().unique().floatGenerator() ==
    "'decimal' REAL UNIQUE"

block:
  check Column.float("decimal").nullable().default(0.0).floatGenerator() ==
    "'decimal' REAL DEFAULT 0.0"

block:
  check Column.float("decimal").nullable().unsigned().floatGenerator() ==
    "'decimal' REAL CHECK (decimal > 0)"

block:
  check Column.char("char", 255).charGenerator() ==
    "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

block:
  check Column.char("char", 255).nullable().charGenerator() ==
    "'char' VARCHAR CHECK (length('char') <= 255)"

block:
  check Column.char("char", 255).nullable().unique().charGenerator() ==
    "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

block:
  check Column.char("char", 255).nullable().default("").charGenerator() ==
    "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

block:
  check Column.char("char", 255).nullable().unsigned().charGenerator() ==
    "'char' VARCHAR CHECK (length('char') <= 255) CHECK (char > 0)"

block:
  check Column.string("char").varcharGenerator() ==
    "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

block:
  check Column.string("char").nullable().varcharGenerator() ==
    "'char' VARCHAR CHECK (length('char') <= 255)"

block:
  check Column.string("char").nullable().unique().varcharGenerator() ==
    "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

block:
  check Column.string("char").nullable().default("").varcharGenerator() ==
    "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

block:
  check Column.string("char").nullable().unsigned().varcharGenerator() ==
    "'char' VARCHAR CHECK (length('char') <= 255) CHECK (char > 0)"

block:
  check Column.text("char").textGenerator() ==
    "'char' TEXT NOT NULL"

block:
  check Column.text("char").nullable().textGenerator() ==
    "'char' TEXT"

block:
  check Column.text("char").nullable().unique().textGenerator() ==
    "'char' TEXT UNIQUE"

block:
  check Column.text("char").nullable().default("").textGenerator() ==
    "'char' TEXT DEFAULT ''"

block:
  check Column.text("char").nullable().unsigned().textGenerator() ==
    "'char' TEXT CHECK (char > 0)"

block:
  check Column.date("date").dateGenerator() ==
    "'date' DATE NOT NULL"

block:
  check Column.date("date").nullable().dateGenerator() ==
    "'date' DATE"

block:
  check Column.date("date").nullable().unique().dateGenerator() ==
    "'date' DATE UNIQUE"

block:
  check Column.date("date").nullable().default().dateGenerator() ==
    "'date' DATE DEFAULT CURRENT_TIMESTAMP"

block:
  check Column.date("date").nullable().unsigned().dateGenerator() ==
    "'date' DATE CHECK (date > 0)"

block:
  check Column.datetime("date").datetimeGenerator() ==
    "'date' DATETIME NOT NULL"

block:
  check Column.datetime("date").nullable().datetimeGenerator() ==
    "'date' DATETIME"

block:
  check Column.datetime("date").nullable().unique().datetimeGenerator() ==
    "'date' DATETIME UNIQUE"

block:
  check Column.datetime("date").nullable().default().datetimeGenerator() ==
    "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

block:
  check Column.datetime("date").nullable().unsigned().datetimeGenerator() ==
    "'date' DATETIME CHECK (date > 0)"

block:
  check Column.time("date").timeGenerator() ==
    "'date' TIME NOT NULL"

block:
  check Column.time("date").nullable().timeGenerator() ==
    "'date' TIME"

block:
  check Column.time("date").nullable().unique().timeGenerator() ==
    "'date' TIME UNIQUE"

block:
  check Column.time("date").nullable().default().timeGenerator() ==
    "'date' TIME DEFAULT CURRENT_TIMESTAMP"

block:
  check Column.time("date").nullable().unsigned().timeGenerator() ==
    "'date' TIME CHECK (date > 0)"

block:
  check Column.timestamp("date").timestampGenerator() ==
    "'date' DATETIME NOT NULL"

block:
  check Column.timestamp("date").nullable().timestampGenerator() ==
    "'date' DATETIME"

block:
  check Column.timestamp("date").nullable().unique().timestampGenerator() ==
    "'date' DATETIME UNIQUE"

block:
  check Column.timestamp("date").nullable().default().timestampGenerator() ==
    "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

block:
  check Column.timestamp("date").nullable().unsigned().timestampGenerator() ==
    "'date' DATETIME CHECK (date > 0)"

block:
  check Column.timestamps().timestampsGenerator() ==
    "'created_at' DATETIME DEFAULT CURRENT_TIMESTAMP, 'updated_at' DATETIME DEFAULT CURRENT_TIMESTAMP"

block:
  check Column.softDelete().softDeleteGenerator() ==
    "'deleted_at' DATETIME"

block:
  check Column.binary("blob").blobGenerator() ==
    "'blob' BLOB NOT NULL"

block:
  check Column.binary("blob").nullable().blobGenerator() ==
    "'blob' BLOB"

block:
  check Column.binary("blob").nullable().blobGenerator() ==
    "'blob' BLOB"

block:
  check Column.binary("blob").nullable().default().blobGenerator() ==
    "'blob' BLOB DEFAULT ''"

block:
  check Column.binary("blob").nullable().unsigned().blobGenerator() ==
    "'blob' BLOB CHECK (blob > 0)"

block:
  check Column.boolean("bool").boolGenerator() ==
    "'bool' TINYINT NOT NULL"

block:
  check Column.boolean("bool").nullable().boolGenerator() ==
    "'bool' TINYINT"

block:
  check Column.boolean("bool").nullable().unique().boolGenerator() ==
    "'bool' TINYINT UNIQUE"

block:
  check Column.boolean("bool").nullable().default(false).boolGenerator() ==
    "'bool' TINYINT DEFAULT false"

  check Column.boolean("bool").nullable().default(true).boolGenerator() ==
    "'bool' TINYINT DEFAULT true"

block:
  try:
    discard Column.boolean("bool").nullable().unsigned().boolGenerator()
    check false
  except DbError:
    check true

block:
  check Column.enumField("enum", ["a", "b"]).enumGenerator() ==
    "'enum' VARCHAR NOT NULL CHECK (enum = 'a' OR enum = 'b')"

block:
  check Column.enumField("enum", ["a", "b"]).nullable().enumGenerator() ==
    "'enum' VARCHAR CHECK (enum = 'a' OR enum = 'b')"

block:
  check Column.enumField("enum", ["a", "b"]).nullable().unique().enumGenerator() ==
    "'enum' VARCHAR UNIQUE CHECK (enum = 'a' OR enum = 'b')"

block:
  check Column.enumField("enum", ["a", "b"]).nullable().default("a").enumGenerator() ==
    "'enum' VARCHAR DEFAULT 'a' CHECK (enum = 'a' OR enum = 'b')"

block:
  try:
    discard Column.enumField("enum", ["a", "b"]).nullable().unsigned().enumGenerator()
    check false
  except DbError:
    check true

block:
  check Column.json("json").jsonGenerator() ==
    "'json' TEXT NOT NULL"

block:
  check Column.json("json").nullable().jsonGenerator() ==
    "'json' TEXT"

block:
  check Column.json("json").nullable().unique().jsonGenerator() ==
    "'json' TEXT UNIQUE"

block:
  check Column.json("json").nullable().default(%*{"key":"value"}).jsonGenerator() ==
    """'json' TEXT DEFAULT '{
  "key": "value"
}'"""

block:
  check Column.json("json").nullable().unsigned().jsonGenerator() ==
    "'json' TEXT CHECK (json > 0)"

block:
  check Column.foreign("auth_id").nullable().foreignColumnGenerator() == "'auth_id' INTEGER"
  check Column.foreign("auth_id").reference("id").on("auth").onDelete(RESTRICT).foreignGenerator() ==
    "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE RESTRICT"
  check Column.foreign("auth_id").reference("id").on("auth").onDelete(CASCADE).foreignGenerator() ==
    "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE CASCADE"
  check Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL).foreignGenerator() ==
    "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE SET NULL"
  check Column.foreign("auth_id").reference("id").on("auth").onDelete(NO_ACTION).foreignGenerator() ==
    "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE NO ACTION"
