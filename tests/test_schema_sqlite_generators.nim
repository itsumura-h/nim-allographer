import unittest
include ../src/allographer/schema_builder/generators/sqlite_generators


suite "sqlite generators int":
  test "serialGenerator":
    check serialGenerator("id") == "'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"

  test "intGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check intGenerator("int", nullable, isUnique, isDefault, isUnsigned, 0) ==
      "'int' INTEGER"

  test "intGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check intGenerator("int", nullable, isUnique, isDefault, isUnsigned, 0) ==
      "'int' INTEGER NOT NULL"

  test "intGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check intGenerator("int", nullable, isUnique, isDefault, isUnsigned, 0) ==
      "'int' INTEGER UNIQUE"

  test "intGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check intGenerator("int", nullable, isUnique, isDefault, isUnsigned, 0) ==
      "'int' INTEGER DEFAULT 0"

  test "intGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check intGenerator("int", nullable, isUnique, isDefault, isUnsigned, 0) ==
      "'int' INTEGER CHECK ('int' = null OR 'int' > 0)"

    nullable= false
    check intGenerator("int", nullable, isUnique, isDefault, isUnsigned, 0) ==
      "'int' INTEGER NOT NULL CHECK ('int' > 0)"


suite "sqlite generators float":
  test "decimalGenerator":
    let nullable = false
    let isUnique, isDefault, isUnsigned = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' NUMERIC"

  test "decimalGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' NUMERIC NOT NULL"

  test "decimalGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' NUMERIC DEFAULT 0.0"

  test "decimalGenerator unsigned":
    var nullable = true
    var isUnique, isDefault, isUnsigned = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' NUMERIC CHECK ('decimal' = null OR 'decimal' > 0)"

    nullable = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' NUMERIC NOT NULL CHECK ('decimal' > 0)"

  test "floatGenerator":
    let nullable = false
    let isUnique, isDefault, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' REAL"

  test "floatGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' REAL NOT NULL"

  test "floatGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' REAL UNIQUE"

  test "floatGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' REAL DEFAULT 0.0"

  test "floatGenerator unsigned":
    var nullable = true
    var isUnique, isDefault, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' REAL CHECK ('decimal' = null OR 'decimal' > 0)"

    nullable = false
    check floatGenerator("decimal", nullable, isUnique, isDefault, 0.0, isUnsigned) ==
      "'decimal' REAL NOT NULL CHECK ('decimal' > 0)"

suite "sqlite generators char":
  test "charGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check charGenerator("char", 255, nullable, isUnique, isDefault, "", isUnsigned) ==
      "'char' VARCHAR CHECK (length('char') <= 255)"

  test "charGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check charGenerator("char", 255, nullable, isUnique, isDefault, "", isUnsigned) ==
      "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

  test "charGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check charGenerator("char", 255, nullable, isUnique, isDefault, "", isUnsigned) ==
      "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

  test "charGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check charGenerator("char", 255, nullable, isUnique, isDefault, "", isUnsigned) ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

  test "charGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check charGenerator("char", 255, nullable, isUnique, isDefault, "", isUnsigned) ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255) CHECK (char > 0)"

  test "varcharGenerator":
    check varcharGenerator("char", 255, true, false, false, "", false) ==
      "'char' VARCHAR CHECK (length('char') <= 255)"

  test "varcharGenerator not null":
    check varcharGenerator("char", 255, false, false, false, "", false) ==
      "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

  test "varcharGenerator unique":
    check varcharGenerator("char", 255, true, true, false, "", false) ==
      "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

  test "varcharGenerator default":
    check varcharGenerator("char", 255, true, false, true, "", false) ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

  test "varcharGenerator unsigned":
    check varcharGenerator("char", 255, true, false, false, "", true) ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255) CHECK (char > 0)"

  test "textGenerator":
    check textGenerator("char", true, false, false, "", false) ==
      "'char' TEXT"

  test "textGenerator not null":
    check textGenerator("char", false, false, false, "", false) ==
      "'char' TEXT NOT NULL"

  test "textGenerator unique":
    check textGenerator("char", true, true, false, "", false) ==
      "'char' TEXT UNIQUE"

  test "textGenerator default":
    check textGenerator("char", true, false, true, "", false) ==
      "'char' TEXT DEFAULT ''"

  test "textGenerator unsigned":
    check textGenerator("char", true, false, false, "", true) ==
      "'char' TEXT CHECK (char > 0)"

suite "sqlite generators date":
  test "dateGenerator":
    var nullable = true
    let isUnique, isDefault, isUnsigned = false
    check dateGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATE"

  test "dateGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check dateGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATE NOT NULL"

  test "dateGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check dateGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATE UNIQUE"

  test "dateGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check dateGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATE DEFAULT CURRENT_TIMESTAMP"

  test "dateGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check dateGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATE CHECK (date > 0)"

  test "datetimeGenerator":
    check datetimeGenerator("date", true, false, false, false) ==
      "'date' DATETIME"

  test "datetimeGenerator not null":
    check datetimeGenerator("date", false, false, false, false) ==
      "'date' DATETIME NOT NULL"

  test "datetimeGenerator unique":
    check datetimeGenerator("date", true, true, false, false) ==
      "'date' DATETIME UNIQUE"

  test "datetimeGenerator default":
    check datetimeGenerator("date", true, false, true, false) ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "timeGenerator":
    check timeGenerator("date", true, false, false, false) ==
      "'date' TIME"

  test "timeGenerator not null":
    check timeGenerator("date", false, false, false, false) ==
      "'date' TIME NOT NULL"

  test "timeGenerator unique":
    check timeGenerator("date", true, true, false, false) ==
      "'date' TIME UNIQUE"

  test "timeGenerator default":
    check timeGenerator("date", true, false, true, false) ==
      "'date' TIME DEFAULT CURRENT_TIMESTAMP"

  test "timestampGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check timestampGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATETIME"

  test "timestampGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check timestampGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATETIME NOT NULL"

  test "timestampGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check timestampGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATETIME UNIQUE"

  test "timestampGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check timestampGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "timestampGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check timestampGenerator("date", nullable, isUnique, isDefault, isUnsigned) ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP CHECK (date > 0)"

  test "timestampsGenerator":
    check timestampsGenerator() ==
      "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "softDeleteGenerator":
    check softDeleteGenerator() == "deleted_at DATETIME"

suite "sqlite generators others":
  test "blobGenerator":
    check blobGenerator("blob", true, false) == "'blob' BLOB"
    check blobGenerator("blob", false, false) == "'blob' BLOB NOT NULL"
    check blobGenerator("blob", true, true) == "'blob' BLOB UNIQUE"

  test "boolGenerator unique":
    check boolGenerator("bool", true, false, false, false) ==
      "'bool' TINYINT"

  test "boolGenerator not null":
    check boolGenerator("bool", false, false, false, false) ==
      "'bool' TINYINT NOT NULL"

  test "boolGenerator unique":
    check boolGenerator("bool", true, true, false, false) ==
      "'bool' TINYINT UNIQUE"

  test "boolGenerator default":
    check boolGenerator("bool", true, false, true, false) ==
      "'bool' TINYINT DEFAULT false"

    check boolGenerator("bool", true, false, true, true) ==
      "'bool' TINYINT DEFAULT true"

  test "enumGenerator":
    check enumGenerator("enum", [%"a", %"b"], true, false, false, "") ==
      "'enum' VARCHAR CHECK ('enum' = null OR 'enum' = 'a' OR 'enum' = 'b')"

  test "enumGenerator not null":
    check enumGenerator("enum", [%"a", %"b"], false, false, false, "") ==
      "'enum' VARCHAR NOT NULL CHECK ('enum' = 'a' OR 'enum' = 'b')"

  test "enumGenerator unique":
    check enumGenerator("enum", [%"a", %"b"], true, true, false, "") ==
      "'enum' VARCHAR UNIQUE CHECK ('enum' = null OR 'enum' = 'a' OR 'enum' = 'b')"

  test "enumGenerator default":
    check enumGenerator("enum", [%"a", %"b"], true, false, true, "a") ==
      "'enum' VARCHAR DEFAULT 'a' CHECK ('enum' = null OR 'enum' = 'a' OR 'enum' = 'b')"

  test "jsonGenerator":
    check jsonGenerator("json", true, false) ==
      "'json' TEXT"

  test "jsonGenerator not null":
    check jsonGenerator("json", false, false) ==
      "'json' TEXT NOT NULL"

  test "jsonGenerator unique":
    check jsonGenerator("json", true, true) ==
      "'json' TEXT UNIQUE"

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
