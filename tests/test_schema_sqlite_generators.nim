import unittest
include ../src/allographer/schema_builder/generators/sqlite_generators


suite "sqlite generators int":
  test "serialGenerator":
    check serialGenerator("id") == "'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"

  test "intGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
      "'int' INTEGER"

  test "intGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
      "'int' INTEGER NOT NULL"

  test "intGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
      "'int' INTEGER UNIQUE"

  test "intGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
      "'int' INTEGER DEFAULT 0"

  test "intGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault = false
    check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
      "'int' INTEGER CHECK (int > 0)"

    nullable= false
    check intGenerator("int", nullable, isUnique, isUnsigned, isDefault, 0) ==
      "'int' INTEGER NOT NULL CHECK (int > 0)"


suite "sqlite generators float":
  test "decimalGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' NUMERIC"

  test "decimalGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' NUMERIC NOT NULL"

  test "decimalGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' NUMERIC DEFAULT 0.0"

  test "decimalGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' NUMERIC CHECK (decimal > 0)"

    nullable = false
    check decimalGenerator("decimal", 5, 3, nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' NUMERIC NOT NULL CHECK (decimal > 0)"

  test "floatGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' REAL"

  test "floatGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' REAL NOT NULL"

  test "floatGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' REAL UNIQUE"

  test "floatGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' REAL DEFAULT 0.0"

  test "floatGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault = false
    check floatGenerator("decimal", nullable, isUnique, isUnsigned, isDefault, 0.0) ==
      "'decimal' REAL CHECK (decimal > 0)"

suite "sqlite generators char":
  test "charGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR CHECK (length('char') <= 255)"

  test "charGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

  test "charGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

  test "charGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

  test "charGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault = false
    check charGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR CHECK (length('char') <= 255) CHECK (char > 0)"

  test "varcharGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR CHECK (length('char') <= 255)"

  test "varcharGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR NOT NULL CHECK (length('char') <= 255)"

  test "varcharGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR UNIQUE CHECK (length('char') <= 255)"

  test "varcharGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR DEFAULT '' CHECK (length('char') <= 255)"

  test "varcharGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check varcharGenerator("char", 255, nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' VARCHAR CHECK (length('char') <= 255) CHECK (char > 0)"

  test "textGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' TEXT"

  test "textGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' TEXT NOT NULL"

  test "textGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' TEXT UNIQUE"

  test "textGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' TEXT DEFAULT ''"

  test "textGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check textGenerator("char", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'char' TEXT CHECK (char > 0)"

suite "sqlite generators date":
  test "dateGenerator":
    var nullable = true
    let isUnique, isDefault, isUnsigned = false
    check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATE"

  test "dateGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATE NOT NULL"

  test "dateGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATE UNIQUE"

  test "dateGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATE DEFAULT CURRENT_TIMESTAMP"

  test "dateGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check dateGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATE CHECK (date > 0)"

  test "datetimeGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME"

  test "datetimeGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME NOT NULL"

  test "datetimeGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME UNIQUE"

  test "datetimeGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "datetimeGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check datetimeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME CHECK (date > 0)"

  test "timeGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' TIME"

  test "timeGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' TIME NOT NULL"

  test "timeGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' TIME UNIQUE"

  test "timeGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' TIME DEFAULT CURRENT_TIMESTAMP"

  test "timeGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check timeGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' TIME CHECK (date > 0)"

  test "timestampGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME"

  test "timestampGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME NOT NULL"

  test "timestampGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME UNIQUE"

  test "timestampGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "timestampGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check timestampGenerator("date", nullable, isUnique, isUnsigned, isDefault) ==
      "'date' DATETIME CHECK (date > 0)"

  test "timestampsGenerator":
    check timestampsGenerator() ==
      "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP"

  test "softDeleteGenerator":
    check softDeleteGenerator() == "deleted_at DATETIME"

suite "sqlite generators others":
  test "blobGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'blob' BLOB"

  test "blobGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'blob' BLOB NOT NULL"

  test "blobGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'blob' BLOB UNIQUE"

  test "blobGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'blob' BLOB DEFAULT ''"

  test "blobGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check blobGenerator("blob", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'blob' BLOB CHECK (blob > 0)"

  test "boolGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, false) ==
      "'bool' TINYINT"

  test "boolGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, false) ==
      "'bool' TINYINT NOT NULL"

  test "boolGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, false) ==
      "'bool' TINYINT UNIQUE"

  test "boolGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, false) ==
      "'bool' TINYINT DEFAULT false"

    check boolGenerator("bool", nullable, isUnique, isUnsigned, isDefault, true) ==
      "'bool' TINYINT DEFAULT true"

  test "boolGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    try:
      discard boolGenerator("blob", nullable, isUnique, isUnsigned, isDefault, false)
      check false
    except DbError:
      check true

  test "enumGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "") ==
      "'enum' VARCHAR CHECK (enum = 'a' OR enum = 'b')"

  test "enumGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "") ==
      "'enum' VARCHAR NOT NULL CHECK (enum = 'a' OR enum = 'b')"

  test "enumGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "") ==
      "'enum' VARCHAR UNIQUE CHECK (enum = 'a' OR enum = 'b')"

  test "enumGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "a") ==
      "'enum' VARCHAR DEFAULT 'a' CHECK (enum = 'a' OR enum = 'b')"

  test "enumGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    try:
      discard enumGenerator("enum", [%"a", %"b"], nullable, isUnique, isUnsigned, isDefault, "a")
      check false
    except DbError:
      check true

  test "jsonGenerator":
    let nullable = true
    let isUnique, isDefault, isUnsigned = false
    check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'json' TEXT"

  test "jsonGenerator not null":
    let nullable, isUnique, isDefault, isUnsigned = false
    check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'json' TEXT NOT NULL"

  test "jsonGenerator unique":
    let nullable, isUnique = true
    let isDefault, isUnsigned = false
    check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'json' TEXT UNIQUE"

  test "jsonGenerator default":
    let nullable, isDefault = true
    let isUnique, isUnsigned = false
    check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'json' TEXT DEFAULT ''"

  test "jsonGenerator unsigned":
    var nullable, isUnsigned = true
    var isUnique, isDefault= false
    check jsonGenerator("json", nullable, isUnique, isUnsigned, isDefault, "") ==
      "'json' TEXT CHECK (json > 0)"

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
