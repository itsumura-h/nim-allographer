|orator|DbTypeKind|sqlite|mysql|pgsql|
|---|---|---|---|---|
|increments|dbSerial|INTEGER|3,int|integer
|big_integer|dbInt|INTEGER|8,bigint|bigint
|binary|dbBlob|BLOB|252,blob|bytea
|boolean|dbBool|TINYINT|1,tinyint|boolean
|char|dbFixedChar|VARCHAR|254,char|character
|date|dbDate|DATE|10,date|date
|datetime|dbDatetime|DATETIME|12,datetime|timestamp
|decimal|dbDecimal|NUMERIC|246,decimal|numeric
|double|dbFloat|FLOAT|5,double|double
|enum|dbEnum|VARCHAR|254,enum|character
|float|dbFloat|FLOAT|5,double|double
|integer|dbInt|INTEGER|3,int|integer
|json|dbJson|TEXT|245,json|json
|long_text|dbXml|TEXT|252,longtext|text
|medium_integer|dbInt|INTEGER|9,mediumint|integer
|medium_text|dbXml|TEXT|252,mediumtext|text
|morphs||INTEGER, VARCHAR|3:int, 253:varchar|integer, character
|small_integer|dbInt|INTEGER|2,smallint|smallint
|string|dbVarchar|VARCHAR|253,varchar|character
|string_with_len|dbVarchar|VARCHAR|253,varchar|character
|text|dbXml|TEXT|252,text|text
|time|dbTime|TIME|11,time|time
|timestamp|dbTimestamp|DATETIME|7,timestamp|timestamp
|soft_deletes|dbTimestamp|DATETIME|7,timestamp|timestamp
|timestamps|dbTimestamp|DATETIME|7,timestamp|timestamp

---

## int
|orator|DbTypeKind|sqlite|mysql|pgsql|
|---|---|---|---|---|
|increments|dbSerial|INTEGER|3,int|integer
|integer|dbInt|INTEGER|3,int|integer
|small_integer|dbInt|INTEGER|2,smallint|smallint
|medium_integer|dbInt|INTEGER|9,mediumint|integer
|big_integer|dbInt|INTEGER|8,bigint|bigint

## float
|orator|DbTypeKind|sqlite|mysql|pgsql|
|---|---|---|---|---|
|decimal|dbDecimal|NUMERIC|246,decimal|numeric
|double|dbFloat|FLOAT|5,double|double
|float|dbFloat|FLOAT|5,double|double

## char
|orator|DbTypeKind|sqlite|mysql|pgsql|
|---|---|---|---|---|
|char|dbFixedChar|VARCHAR|254,char|character
|string|dbVarchar|VARCHAR|253,varchar|character
|string_with_len|dbVarchar|VARCHAR|253,varchar|character
|text|dbXml|TEXT|252,text|text
|medium_text|dbXml|TEXT|252,mediumtext|text
|long_text|dbXml|TEXT|252,longtext|text

## date
|orator|DbTypeKind|sqlite|mysql|pgsql|
|---|---|---|---|---|
|date|dbDate|DATE|10,date|date
|datetime|dbDatetime|DATETIME|12,datetime|timestamp
|time|dbTime|TIME|11,time|time
|timestamp|dbTimestamp|DATETIME|7,timestamp|timestamp
|timestamps|dbTimestamp|DATETIME|7,timestamp|timestamp
|soft_deletes|dbTimestamp|DATETIME|7,timestamp|timestamp

## others
|orator|DbTypeKind|sqlite|mysql|pgsql|
|---|---|---|---|---|
|binary|dbBlob|BLOB|252,blob|bytea
|boolean|dbBool|TINYINT|1,tinyint|boolean
|enum|dbEnum|VARCHAR|254,enum|character
|json|dbJson|TEXT|245,json|json
|morphs||INTEGER, VARCHAR|3:int, 253:varchar|integer, character
