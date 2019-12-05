import unittest
include ../src/allographer/schema_builder_pkg/generators/sqlite_generators


suite "sqlite generators int":
  test "serialGenerator":
    check serialGenerator("id") == "'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"

  test "intGenerator":
    check intGenerator("int", true, false, 0, false) == "'int' INTEGER"
  
  test "intGenerator not null":
    check intGenerator("int", false, false, 0, false) == "'int' INTEGER NOT NULL"
  
  test "intGenerator default":
    check intGenerator("int", true, true, 0, false) == "'int' INTEGER DEFAULT 0"
  
  test "intGenerator unsigned":
    check intGenerator("int", true, false, 0, true) == "'int' INTEGER CHECK ('int' = null OR 'int' > 0)"
    check intGenerator("int", false, false, 0, true) == "'int' INTEGER NOT NULL CHECK ('int' > 0)"

suite "sqlite generators float":
  test "decimalGenerator":
    check decimalGenerator("decimal", 5, 3, true, false, 0.0, false) ==
      "'decimal' NUMERIC"

  test "decimalGenerator not null":
    check decimalGenerator("decimal", 5, 3, false, false, 0.0, false) ==
      "'decimal' NUMERIC NOT NULL"

  test "decimalGenerator default":
    check decimalGenerator("decimal", 5, 3, true, true, 0.0, false) ==
      "'decimal' NUMERIC DEFAULT 0.0"

  test "decimalGenerator unsigned":
    check decimalGenerator("decimal", 5, 3, true, false, 0.0, true) ==
      "'decimal' NUMERIC CHECK ('decimal' = null OR 'decimal' > 0)"
    check decimalGenerator("decimal", 5, 3, false, false, 0.0, true) ==
      "'decimal' NUMERIC NOT NULL CHECK ('decimal' > 0)"

  test "floatGenerator":
    check floatGenerator("decimal", true, false, 0.0, false) ==
      "'decimal' REAL"

  test "floatGenerator not null":
    check floatGenerator("decimal", false, false, 0.0, false) ==
      "'decimal' REAL NOT NULL"

  test "floatGenerator default":
    check floatGenerator("decimal", true, true, 0.0, false) ==
      "'decimal' REAL DEFAULT 0.0"

  test "floatGenerator unsigned":
    check floatGenerator("decimal", true, false, 0.0, true) ==
      "'decimal' REAL CHECK ('decimal' = null OR 'decimal' > 0)"
    check floatGenerator("decimal", false, false, 0.0, true) ==
      "'decimal' REAL NOT NULL CHECK ('decimal' > 0)"

suite "sqlite generators char":
  test "charGenerator":
    check charGenerator("char", 255, true, false, "") ==
      "'char' VARCHAR CHECK (length('char') <= 255)"
  
  test "charGenerator not null":
    check charGenerator("char", 255, false, false, "") ==
      "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

  test "charGenerator default":
    check charGenerator("char", 255, true, true, "") ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

  test "varcharGenerator":
    check varcharGenerator("char", 255, true, false, "") ==
      "'char' VARCHAR CHECK (length('char') <= 255)"
  
  test "varcharGenerator not null":
    check varcharGenerator("char", 255, false, false, "") ==
      "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

  test "varcharGenerator default":
    check varcharGenerator("char", 255, true, true, "") ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

  test "textGenerator":
    check textGenerator("char", true, false, "") ==
      "'char' TEXT"
  
  test "textGenerator not null":
    check textGenerator("char", false, false, "") ==
      "'char' TEXT NOT NULL"

  test "textGenerator default":
    check textGenerator("char", true, true, "") ==
      "'char' TEXT DEFAULT ''"

suite "sqlite generators date":
  test "dateGenerator":
    check dateGenerator("date", true, false) ==
      "'date' DATE"

  test "dateGenerator not null":
    check dateGenerator("date", false, false) ==
      "'date' DATE NOT NULL"

  test "dateGenerator default":
    check dateGenerator("date", true, true) ==
      "'date' DATE DEFAULT CURRENT_TIMESTAMP"

  test "datetimeGenerator":
    check datetimeGenerator("date", true, false) ==
      "'date' DATETIME"

  test "datetimeGenerator not null":
    check datetimeGenerator("date", false, false) ==
      "'date' DATETIME NOT NULL"

  test "datetimeGenerator default":
    check datetimeGenerator("date", true, true) ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "timeGenerator":
    check timeGenerator("date", true, false) ==
      "'date' TIME"

  test "timeGenerator not null":
    check timeGenerator("date", false, false) ==
      "'date' TIME NOT NULL"

  test "timeGenerator default":
    check timeGenerator("date", true, true) ==
      "'date' TIME DEFAULT CURRENT_TIMESTAMP"

  test "timestampGenerator":
    check timestampGenerator("date", true, false) ==
      "'date' DATETIME"

  test "timestampGenerator not null":
    check timestampGenerator("date", false, false) ==
      "'date' DATETIME NOT NULL"

  test "timestampGenerator default":
    check timestampGenerator("date", true, true) ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "timestampsGenerator":
    check timestampsGenerator() ==
      "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "softDeleteGenerator":
    check softDeleteGenerator() == "deleted_at DATETIME"

suite "sqlite generators others":
  test "blobGenerator":
    check blobGenerator("blob", true) == "'blob' BLOB"
    check blobGenerator("blob", false) == "'blob' BLOB NOT NULL"

  test "boolGenerator":
    check boolGenerator("bool", true, false, false) ==
      "'bool' TINYINT"

  test "boolGenerator not null":
    check boolGenerator("bool", false, false, false) ==
      "'bool' TINYINT NOT NULL"

  test "boolGenerator default":
    check boolGenerator("bool", true, true, false) ==
      "'bool' TINYINT DEFAULT false"

    check boolGenerator("bool", true, true, true) ==
      "'bool' TINYINT DEFAULT true"

  test "enumGenerator":
    check enumGenerator("enum", [%"a", %"b"], true, false, "") ==
      "'enum' VARCHAR CHECK ('enum' = null OR 'enum' = 'a' OR 'enum' = 'b')"

  test "enumGenerator not null":
    check enumGenerator("enum", [%"a", %"b"], false, false, "") ==
      "'enum' VARCHAR NOT NULL CHECK ('enum' = 'a' OR 'enum' = 'b')"

  test "enumGenerator default":
    check enumGenerator("enum", [%"a", %"b"], true, true, "a") ==
      "'enum' VARCHAR DEFAULT 'a' CHECK ('enum' = null OR 'enum' = 'a' OR 'enum' = 'b')"

  test "jsonGenerator":
    check jsonGenerator("json", true) ==
      "'json' TEXT"

  test "jsonGenerator not null":
    check jsonGenerator("json", false) ==
      "'json' TEXT NOT NULL"

  test "foreign":
    check foreignColumnGenerator("auth_id") == "'auth_id' INTEGER"
    check foreignGenerator("auth_id", "auth", "id", RESTRICT) ==
      ", FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE RESTRICT"
    check foreignGenerator("auth_id", "auth", "id", CASCADE) ==
      ", FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE CASCADE"
    check foreignGenerator("auth_id", "auth", "id", SET_NULL) ==
      ", FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE SET NULL"
    check foreignGenerator("auth_id", "auth", "id", NO_ACTION) ==
      ", FOREIGN KEY('auth_id') REFERENCES auth(id) ON DELETE NO ACTION"