discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest
include ../src/allographer/schema_builder/generators/sqlite_generators


block:
  check serialGenerator("id") == "'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
    "'int' INTEGER"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
    "'int' INTEGER NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
    "'int' INTEGER UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
    "'int' INTEGER DEFAULT 0"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault = false
  check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
    "'int' INTEGER CHECK (int > 0)"

  nullable= false
  check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
    "'int' INTEGER NOT NULL CHECK (int > 0)"


block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' NUMERIC"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' NUMERIC NOT NULL"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' NUMERIC DEFAULT 0.0"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault = false
  check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' NUMERIC CHECK (decimal > 0)"

  nullable = false
  check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' NUMERIC NOT NULL CHECK (decimal > 0)"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' REAL"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' REAL NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' REAL UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' REAL DEFAULT 0.0"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault = false
  check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
    "'decimal' REAL CHECK (decimal > 0)"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR CHECK (length('char') <= 255)"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault = false
  check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR CHECK (length('char') <= 255) CHECK (char > 0)"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR CHECK (length('char') <= 255)"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' VARCHAR CHECK (length('char') <= 255) CHECK (char > 0)"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' TEXT"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' TEXT NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' TEXT UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' TEXT DEFAULT ''"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'char' TEXT CHECK (char > 0)"

block:
  var nullable = true
  let isUnique, isDefault, isUnsigned = false
  check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATE"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATE NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATE UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATE DEFAULT CURRENT_TIMESTAMP"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATE CHECK (date > 0)"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME CHECK (date > 0)"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' TIME"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' TIME NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' TIME UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' TIME DEFAULT CURRENT_TIMESTAMP"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' TIME CHECK (date > 0)"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
    "'date' DATETIME CHECK (date > 0)"

block:
  check timestampsGenerator() ==
    "'created_at' DATETIME DEFAULT CURRENT_TIMESTAMP, 'updated_at' DATETIME DEFAULT CURRENT_TIMESTAMP"

block:
  check softDeleteGenerator() == "'deleted_at' DATETIME"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'blob' BLOB"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'blob' BLOB NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'blob' BLOB UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'blob' BLOB DEFAULT ''"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
    "'blob' BLOB CHECK (blob > 0)"

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, false) ==
    "'bool' TINYINT"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, false) ==
    "'bool' TINYINT NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, false) ==
    "'bool' TINYINT UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, false) ==
    "'bool' TINYINT DEFAULT false"

  check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, true) ==
    "'bool' TINYINT DEFAULT true"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  try:
    discard boolGenerator("blob", nullable, isUnique, isUnsigned, isDefault, false)
    check false
  except DbError:
    check true

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "") ==
    "'enum' VARCHAR CHECK (enum = 'a' OR enum = 'b')"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "") ==
    "'enum' VARCHAR NOT NULL CHECK (enum = 'a' OR enum = 'b')"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "") ==
    "'enum' VARCHAR UNIQUE CHECK (enum = 'a' OR enum = 'b')"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "a") ==
    "'enum' VARCHAR DEFAULT 'a' CHECK (enum = 'a' OR enum = 'b')"

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  try:
    discard enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "a")
    check false
  except DbError:
    check true

block:
  let nullable = true
  let isUnique, isDefault, isUnsigned = false
  check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, newJNull()) ==
    "'json' TEXT"

block:
  let nullable, isUnique, isDefault, isUnsigned = false
  check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, newJNull()) ==
    "'json' TEXT NOT NULL"

block:
  let nullable, isUnique = true
  let isDefault, isUnsigned = false
  check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, newJNull()) ==
    "'json' TEXT UNIQUE"

block:
  let nullable, isDefault = true
  let isUnique, isUnsigned = false
  check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, %*{"key":"value"}) ==
    """'json' TEXT DEFAULT '{
  "key": "value"
}'"""

block:
  var nullable, isUnsigned = true
  var isUnique, isDefault= false
  check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, newJNull()) ==
    "'json' TEXT CHECK (json > 0)"

block:
  check foreignColumnGenerator("auth_id", false, 0) == "'auth_id' INTEGER"
  check foreignColumnGenerator("auth_id", true, 1) == "'auth_id' INTEGER DEFAULT 1"
  check foreignGenerator("auth_id", "auth", "id", RESTRICT) ==
    "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE RESTRICT"
  check foreignGenerator("auth_id", "auth", "id", CASCADE) ==
    "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE CASCADE"
  check foreignGenerator("auth_id", "auth", "id", SET_NULL) ==
    "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE SET NULL"
  check foreignGenerator("auth_id", "auth", "id", NO_ACTION) ==
    "FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE NO ACTION"
