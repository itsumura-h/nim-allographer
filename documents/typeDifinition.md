
## index
<!--ts-->
      * [index](#index)
      * [JInt](#jint)
      * [JFloat](#jfloat)
      * [JBool](#jbool)

<!-- Added by: root, at: Wed Feb  9 18:56:30 UTC 2022 -->

<!--te-->
---

|allographer|sqlite|mysql|postgres|return type|
|---|---|---|---|---|
|increments|INTEGER|INT|INTEGER|JInt
|integer|INTEGER|INT|INTEGER|JInt
|smallInteger|INTEGER|SMALLINT|SMALLINT|JInt
|mediumInteger|INTEGER|MEDIUMINT|INTEGER|JInt
|bigInteger|INTEGER|BIGINT|BIGINT|JInt
|decimal|NUMERIC|DECIMAL|NUMERIC|JFloat
|double|NUMERIC|DOUBLE|NUMERIC|JFloat
|float|DOUBLE|DOUBLE|NUMERIC|JFloat
|char|VARCHAR|CHAR|CHAR|JString
|string|VARCHAR|VARCHAR|VARCHAR|JString
|text|TEXT|TEXT|TEXT|JString
|mediumText|TEXT|MEDIUMTEXT|TEXT|JString
|longText|TEXT|LONGTEXT|TEXT|JString
|date|DATE|DATE|DATE|JString
|datetime|DATETIME|DATETIME|TIMESTAMP|JString
|time|TIME|TIME|TIME|JString
|timestamp|DATETIME|DATETIME|TIMESTAMP|JString
|timestamps|DATETIME|DATETIME|TIMESTAMP|JString
|softDelete|DATETIME|DATETIME|TIMESTAMP|JString
|binary|BLOB|BLOB|BYTEA|JString
|boolean|TINYINT|TINYINT|BOOLEAN|JBool
|enumField|VARCHAR|ENUM|CHARACTER|JString
|json|TEXT|JSON|JSON|JString
|foreign|INTEGER|INT|INT|JInt


## JInt
```
["INTEGER", "INT", "SMALLINT", "MEDIUMINT", "BIGINT"]
```

## JFloat
```
["NUMERIC", "DECIMAL", "DOUBLE"]
```

## JBool
```
["TINYINT", "BOOLEAN"]
```
