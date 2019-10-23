import json, strformat

# =============================================================================
# int
# =============================================================================
proc serialGenerator*(name:string):string =
  result = &"`{name}` INT NOT NULL PRIMARY KEY"

proc intGenerator*(name:string, nullable:bool, isDefault:bool, default:int,
                    isUnsigned:bool, size:string):string =
  if size == "normal":
    result = &"`{name}` INT"
  elif size == "small":
    result = &"`{name}` SMALLINT"
  elif size == "medium":
    result = &"`{name}` MEDIUMINT"
  elif size == "big":
    result = &"`{name}` BIGINT"

  if isDefault:
    result.add(&" DEFAULT {default}")
  
  if isUnsigned:
    result.add(" UNSIGNED")

  if not nullable:
    result.add(" NOT NULL")


# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                        isDefault:bool, default:float,
                        isUnsigned:bool):string =
  result = &"`{name}` DECIMAL({maximum}, {digit})"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if isUnsigned:
    result.add(" UNSIGNED")

  if not nullable:
    result.add(" NOT NULL")

proc floatGenerator*(name:string, isWithOption:bool, maximum:int, digit:int,
                      nullable:bool, isDefault:bool, default:float,
                      isUnsigned:bool):string =
  if isWithOption:
    result = &"`{name}` DOUBLE({maximum}, {digit})"
  else:
    result = &"`{name}` DOUBLE"

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(" UNSIGNED")

  if not nullable:
    result.add(" NOT NULL")
# =============================================================================
# char
# =============================================================================
proc charGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"`{name}` CHAR({maxLength})"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

proc varcharGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"`{name}` VARCHAR({maxLength})"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

proc textGenerator*(name:string, size:string, nullable:bool, isDefault:bool,
                    default:string):string =
  if size == "normal":
    result = &"`{name}` TEXT"
  elif size == "medium":
    result = &"`{name}` MEDIUMTEXT"
  elif size == "long":
    result = &"`{name}` LONGTEXT"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"`{name}` DATE"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (NOW())"
    )

proc datetimeGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"`{name}` DATETIME"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (NOW())"
    )

proc timeGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"`{name}` TIME"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (NOW())"
    )

proc timestampGenerator*(name:string, nullable:bool, isDefault:bool,
                          status:string):string =
  if status == "timestamp":
    result = &"`{name}` DATETIME"

    if not nullable:
      result.add(" NOT NULL")

    if isDefault:
      result.add(
        &" DEFAULT (NOW())"
      )
  elif status == "timestamps":
    result = "`created_at` DATETIME, "
    result.add("`updated_at` DATETIME DEFAULT (NOW())")
  elif status == "softDeletes":
    result = "`deleted_at` DATETIME"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(name:string, nullable:bool):string =
  result = &"`{name}` BLOB"

  if not nullable:
    result.add(" NOT NULL")

proc boolGenerator*(name:string, nullable:bool, isDefault:bool, 
                    default:bool):string =
  result = &"`{name}` TINYINT"

  if isDefault:
    let defaultInt = if default: 1 else: 0
    result.add(
      &" DEFAULT {defaultInt}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc enumOptionsGenerator(name:string, options:varargs[JsonNode]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0:
      optionsString.add(", ")
    optionsString.add(
      &"'{option.getStr}'"
    )
  
  return optionsString

proc enumGenerator*(name:string, options:varargs[JsonNode], nullable:bool,
                    isDefault:bool, default:string):string =
  let optionsString = enumOptionsGenerator(name, options)
  result = &"`{name}` ENUM({optionsString})"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

proc jsonGenerator*(name:string, nullable:bool):string =
  result = &"{name} JSON"

  if not nullable:
    result.add(" NOT NULL")
