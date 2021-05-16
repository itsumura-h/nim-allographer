# import json, strutils, strformat, algorithm, options, asyncdispatch
# import base, builders
# import ../utils
# import ../connection


# proc selectSql*(self: RDB):string =
#   result = self.selectBuilder().sqlString & $self.placeHolder
#   echo result

# proc getColumns(db_columns:DbColumns):seq[array[3, string]] =
#   var columns = newSeq[array[3, string]](db_columns.len)
#   const DRIVER = getDriver()
#   for i, row in db_columns:
#     case DRIVER:
#     of "sqlite":
#       columns[i] = [row.name, row.typ.name, $row.typ.size]
#     of "mysql":
#       columns[i] = [row.name, $row.typ.kind, $row.typ.size]
#     of "postgres":
#       columns[i] = [row.name, $row.typ.kind, $row.typ.size]
#   return columns

# proc toJson(results:openArray[seq[string]], columns:openArray[array[3, string]]):seq[JsonNode] =
#   var response_table = newSeq[JsonNode](results.len)
#   const DRIVER = getDriver()
#   for index, rows in results.pairs:
#     var response_row = newJObject()
#     for i, row in rows:
#       let key = columns[i][0]
#       let typ = columns[i][1]
#       let size = columns[i][2]

#       case DRIVER:
#       of "sqlite":
#         if row == "":
#           response_row[key] = newJNull()
#         elif ["INTEGER", "INT", "SMALLINT", "MEDIUMINT", "BIGINT"].contains(typ):
#           response_row[key] = newJInt(row.parseInt)
#         elif ["NUMERIC", "DECIMAL", "DOUBLE"].contains(typ):
#           response_row[key] = newJFloat(row.parseFloat)
#         elif ["TINYINT", "BOOLEAN"].contains(typ):
#           response_row[key] = newJBool(row.parseBool)
#         else:
#           response_row[key] = newJString(row)
#       of "mysql":
#         if row == "":
#           response_row[key] = newJNull()
#         elif [$dbInt, $dbUInt].contains(typ) and size == "1":
#           if row == "0":
#             response_row[key] = newJBool(false)
#           elif row == "1":
#             response_row[key] = newJBool(true)
#         elif [$dbInt, $dbUInt].contains(typ):
#           response_row[key] = newJInt(row.parseInt)
#         elif [$dbDecimal, $dbFloat].contains(typ):
#           response_row[key] = newJFloat(row.parseFloat)
#         elif [$dbJson].contains(typ):
#           response_row[key] = row.parseJson
#         else:
#           response_row[key] = newJString(row)
#       of "postgres":
#         if row == "":
#           response_row[key] = newJNull()
#         elif [$dbInt, $dbUInt].contains(typ):
#           response_row[key] = newJInt(row.parseInt)
#         elif [$dbDecimal, $dbFloat].contains(typ):
#           response_row[key] = newJFloat(row.parseFloat)
#         elif [$dbBool].contains(typ):
#           if row == "f":
#             response_row[key] = newJBool(false)
#           elif row == "t":
#             response_row[key] = newJBool(true)
#         elif [$dbJson].contains(typ):
#           response_row[key] = row.parseJson
#         else:
#           response_row[key] = newJString(row)

#     response_table[index] = response_row
#   return response_table

# proc getAllRows(sqlString:string, args:seq[string]):seq[JsonNode] =
#   let db = db()
#   defer: db.close()

#   var db_columns: DbColumns
#   var rows = newSeq[seq[string]]()
#   for row in db.instantRows(db_columns, sql sqlString, args):
#     var columns = newSeq[string](row.len)
#     for i in 0..row.len()-1:
#       columns[i] = row[i]
#     rows.add(columns)

#   if rows.len == 0:
#     echoErrorMsg(sqlString & $args)
#     return newSeq[JsonNode](0)

#   let columns = getColumns(db_columns)
#   return toJson(rows, columns) # seq[JsonNode]

# proc getAllRows(db:DbConn, sqlString:string, args:seq[string]):seq[JsonNode] =
#   ## used in transaction
#   var db_columns: DbColumns
#   var rows = newSeq[seq[string]]()
#   for row in db.instantRows(db_columns, sql sqlString, args):
#     var columns = newSeq[string](row.len)
#     for i in 0..row.len()-1:
#       columns[i] = row[i]
#     rows.add(columns)

#   if rows.len == 0:
#     echoErrorMsg(sqlString & $args)
#     return newSeq[JsonNode](0)

#   let columns = getColumns(db_columns)
#   return toJson(rows, columns) # seq[JsonNode]

# proc getAllRowsPlain*(sqlString:string, args:varargs[string]):seq[seq[string]] =
#   let db = db()
#   defer: db.close()
#   return db.getAllRows(sql sqlString, args)

# proc getAllRowsPlain*(db:DbConn, sqlString:string, args:varargs[string]):seq[seq[string]] =
#   return db.getAllRows(sql sqlString, args)

# proc getRow(sqlString:string, args:varargs[string]):Option[JsonNode] =
#   let db = db()
#   defer: db.close()

#   var db_columns: DbColumns
#   var rows = newSeq[seq[string]]()
#   for row in db.instantRows(db_columns, sql sqlString, args):
#     var columns = newSeq[string](row.len)
#     for i in 0..row.len()-1:
#       columns[i] = row[i]
#     rows.add(columns)
#     break

#   if rows.len == 0:
#     echoErrorMsg(sqlString & $args)
#     return none(JsonNode)

#   let columns = getColumns(db_columns)
#   return toJson(rows, columns)[0].some

# proc getRow(db:DbConn, sqlString:string, args:varargs[string]):Option[JsonNode] =
#   ## used in transaction
#   var db_columns: DbColumns
#   var rows = newSeq[seq[string]]()
#   for row in db.instantRows(db_columns, sql sqlString, args):
#     var columns = newSeq[string](row.len)
#     for i in 0..row.len()-1:
#       columns[i] = row[i]
#     rows.add(columns)
#     break

#   if rows.len == 0:
#     echoErrorMsg(sqlString & $args)
#     return none(JsonNode)

#   let columns = getColumns(db_columns)
#   return toJson(rows, columns)[0].some

# proc getRowPlain(sqlString:string, args:varargs[string]):seq[string] =
#   let db = db()
#   defer: db.close()
#   return db.getRow(sql sqlString, args)

# proc getRowPlain(db:DbConn, sqlString:string, args:varargs[string]):seq[string] =
#   return db.getRow(sql sqlString, args)

# proc orm(rows:openArray[JsonNode], typ:typedesc):seq[typ.type] =
#   var response = newSeq[typ.type](rows.len)
#   for i, row in rows:
#     response[i] = row.to(typ.type)
#   return response

# proc orm(row:JsonNode, typ:typedesc):typ.type =
#   return row.to(typ)

# # ==================== async pg ====================
# when getDriver() == "postgres":
#   proc asyncGet*(self: RDB): Future[seq[JsonNode]] {.async.} =
#     defer: self.cleanUp()
#     self.sqlString = self.selectBuilder().sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       result = await asyncGetAllRows(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()
#       return newSeq[JsonNode](0)

#   proc asyncGetPlain*(self:RDB):Future[seq[Row]] {.async.}=
#     defer: self.cleanUp()
#     self.sqlString = self.selectBuilder().sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       return await asyncGetAllRowsPlain(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()
#       return newSeq[Row]()

#   proc asyncGetRow*(self:RDB):Future[Option[JsonNode]] {.async.}=
#     defer: self.cleanUp()
#     self.sqlString = self.selectBuilder().sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       return await asyncGetRow(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()
#       return none(JsonNode)

#   proc asyncGetRowPlain*(self:RDB):Future[Row] {.async.}=
#     defer: self.cleanUp()
#     self.sqlString = self.selectBuilder().sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       return await asyncGetRowPlain(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()
#       return newSeq[string](0)

#   proc asyncFirst*(self: RDB):Future[Option[JsonNode]] {.async.} =
#     defer: self.cleanUp()
#     self.sqlString = self.selectFirstBuilder().sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       return await asyncGetRow(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()
#       return none(JsonNode)

#   proc asyncFirstPlain*(self: RDB):Future[Row] {.async.} =
#     defer: self.cleanUp()
#     self.sqlString = self.selectFirstBuilder().sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       return await asyncGetRowPlain(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()
#       return newSeq[string](0)

#   proc asyncFind*(self: RDB, id: int, key="id"): Future[Option[JsonNode]] {.async.} =
#     defer: self.cleanUp()
#     self.placeHolder.add($id)
#     self.sqlString = self.selectFindBuilder(id, key).sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       return await asyncGetRow(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()
#       return none(JsonNode)

#   proc asyncFindPlain*(self: RDB, id: int, key="id"): Future[Row] {.async.} =
#     defer: self.cleanUp()
#     self.placeHolder.add($id)
#     self.sqlString = self.selectFindBuilder(id, key).sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       return await asyncGetRowPlain(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()
#       return newSeq[string](0)

#   proc asyncInsert*(self: RDB, items: JsonNode) {.async.} =
#     defer: self.cleanUp()
#     self.sqlString = self.insertValueBuilder(items).sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       await asyncExec(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()

#   proc asyncInsert*(self: RDB, rows: seq[JsonNode]) {.async.} =
#     defer: self.cleanUp()
#     self.sqlString = self.insertValuesBuilder(rows).sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       await asyncExec(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()

#   proc asyncInserts*(self: RDB, rows: seq[JsonNode]) {.async.} =
#     defer: self.cleanUp()
#     for row in rows:
#       let sqlString = self.insertValueBuilder(row).sqlString
#       logger(sqlString, self.placeHolder)
#       try:
#         await asyncExec(self.pool, sqlString, self.placeHolder)
#         self.placeHolder = @[]
#       except Exception:
#         echoErrorMsg(sqlString & $self.placeHolder)
#         getCurrentExceptionMsg().echoErrorMsg()
#         break

#   proc asyncUpdate*(self: RDB, items: JsonNode) {.async.} =
#     defer: self.cleanUp()
#     var updatePlaceHolder: seq[string]
#     for item in items.pairs:
#       if item.val.kind == JInt:
#         updatePlaceHolder.add($(item.val.getInt()))
#       elif item.val.kind == JFloat:
#         updatePlaceHolder.add($(item.val.getFloat()))
#       elif [JObject, JArray].contains(item.val.kind):
#         updatePlaceHolder.add($(item.val))
#       else:
#         updatePlaceHolder.add(item.val.getStr())

#     self.placeHolder = updatePlaceHolder & self.placeHolder
#     self.sqlString = self.updateBuilder(items).sqlString

#     try:
#       logger(self.sqlString, self.placeHolder)
#       await asyncExec(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()

#   proc asyncDelete*(self: RDB) {.async.} =
#     defer: self.cleanUp()
#     self.sqlString = self.deleteBuilder().sqlString
#     try:
#       logger(self.sqlString, self.placeHolder)
#       await asyncExec(self.pool, self.sqlString, self.placeHolder)
#     except Exception:
#       echoErrorMsg(self.sqlString & $self.placeHolder)
#       getCurrentExceptionMsg().echoErrorMsg()

# # =============================================================================

# proc toSql*(self: RDB): string =
#   self.sqlString = self.selectBuilder().sqlString
#   return self.sqlString

# proc get*(self: RDB):seq[JsonNode] =
#   defer: self.cleanUp()
#   self.sqlString = self.selectBuilder().sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       result = getAllRows(self.sqlString, self.placeHolder)
#     else:
#       result = getAllRows(self.db, self.sqlString, self.placeHolder)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return newSeq[JsonNode](0)

# proc get*(self: RDB, typ: typedesc): seq[typ.type] =
#   defer: self.cleanUp()
#   self.sqlString = self.selectBuilder().sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getAllRows(self.sqlString, self.placeHolder).orm(typ)
#     else:
#       return getAllRows(self.db, self.sqlString, self.placeHolder).orm(typ)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return newSeq[typ.type](0)

# proc getPlain*(self:RDB):seq[seq[string]] =
#   defer: self.cleanUp()
#   self.sqlString = self.selectBuilder().sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getAllRowsPlain(self.sqlString, self.placeHolder)
#     else:
#       return getAllRowsPlain(self.db, self.sqlString, self.placeHolder)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return newSeq[seq[string]](0)

# proc getRaw*(self: RDB): seq[JsonNode] =
#   defer: self.cleanUp()
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getAllRows(self.sqlString, self.placeHolder)
#     else:
#       return getAllRows(self.db, self.sqlString, self.placeHolder)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return newSeq[JsonNode](0)

# proc getRaw*(self: RDB, typ: typedesc): seq[typ.type] =
#   defer: self.cleanUp()
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getAllRows(self.sqlString, self.placeHolder).orm(typ)
#     else:
#       return getAllRows(self.db, self.sqlString, self.placeHolder).orm(typ)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return newSeq[typ.type](0)

# proc first*(self: RDB):Option[JsonNode] =
#   defer: self.cleanUp()
#   self.sqlString = self.selectFirstBuilder().sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getRow(self.sqlString, self.placeHolder)
#     else:
#       return getRow(self.db, self.sqlString, self.placeHolder)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return none(JsonNode)

# proc first*(self: RDB, typ: typedesc):Option[typ.type] =
#   defer: self.cleanUp()
#   self.sqlString = self.selectFirstBuilder().sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getRow(self.sqlString, self.placeHolder).get.orm(typ).some
#     else:
#       return getRow(self.db, self.sqlString, self.placeHolder).get.orm(typ).some
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return none(typ.type)

# proc firstPlain*(self: RDB): seq[string] =
#   defer: self.cleanUp()
#   self.sqlString = self.selectFirstBuilder().sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getRowPlain(self.sqlString, self.placeHolder)
#     else:
#       return getRowPlain(self.db, self.sqlString, self.placeHolder)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return newSeq[string](0)

# proc find*(self: RDB, id: int, key="id"):Option[JsonNode] =
#   defer: self.cleanUp()
#   self.placeHolder.add($id)
#   self.sqlString = self.selectFindBuilder(id, key).sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getRow(self.sqlString, self.placeHolder)
#     else:
#       return getRow(self.db, self.sqlString, self.placeHolder)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return none(JsonNode)

# proc find*(self: RDB, id: int, typ:typedesc, key="id"):Option[typ.type] =
#   defer: self.cleanUp()
#   self.placeHolder.add($id)
#   self.sqlString = self.selectFindBuilder(id, key).sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getRow(self.sqlString, self.placeHolder).get.orm(typ).some
#     else:
#       return getRow(self.db, self.sqlString, self.placeHolder).get.orm(typ).some
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return none(typ.type)

# proc findPlain*(self:RDB, id:int, key="id"):seq[string] =
#   defer: self.cleanUp()
#   self.placeHolder.add($id)
#   self.sqlString = self.selectFindBuilder(id, key).sqlString
#   try:
#     logger(self.sqlString, self.placeHolder)
#     if self.db.isNil:
#       return getRowPlain(self.sqlString, self.placeHolder)
#     else:
#       return getRowPlain(self.db, self.sqlString, self.placeHolder)
#   except Exception:
#     echoErrorMsg(self.sqlString & $self.placeHolder)
#     getCurrentExceptionMsg().echoErrorMsg()
#     return newSeq[string](0)


# # ==================== INSERT ====================

# proc insertSql*(self: RDB, items: JsonNode):string =
#   result = self.insertValueBuilder(items).sqlString & $self.placeHolder
#   echo result

# proc insert*(self: RDB, items: JsonNode) =
#   defer: self.cleanUp()
#   self.sqlString = self.insertValueBuilder(items).sqlString
#   if self.db.isNil:
#     logger(self.sqlString, self.placeHolder)
#     let db = db()
#     defer: db.close()
#     db.exec(sql self.sqlString, self.placeHolder)
#   else:
#     logger(self.sqlString, self.placeHolder)
#     self.db.exec(sql self.sqlString, self.placeHolder)

# proc insert*(self: RDB, rows: openArray[JsonNode]) =
#   defer: self.cleanUp()
#   self.sqlString = self.insertValuesBuilder(rows).sqlString
#   if self.db.isNil:
#     logger(self.sqlString, self.placeHolder)
#     let db = db()
#     defer: db.close()
#     db.exec(sql self.sqlString, self.placeHolder)
#   else:
#     logger(self.sqlString, self.placeHolder)
#     self.db.exec(sql self.sqlString, self.placeHolder)

# proc inserts*(self: RDB, rows: openArray[JsonNode]) =
#   defer: self.cleanUp()
#   if self.db.isNil:
#     let db = db()
#     defer: db.close()
#     for row in rows:
#       let sqlString = self.insertValueBuilder(row).sqlString
#       logger(sqlString, self.placeHolder)
#       db.exec(sql sqlString, self.placeHolder)
#       self.placeHolder = @[]
#   else:
#      # in Transaction
#     for row in rows:
#       let sqlString = self.insertValueBuilder(row).sqlString
#       logger(sqlString, self.placeHolder)
#       self.db.exec(sql sqlString, self.placeHolder)
#       self.placeHolder = @[]

# proc insertID*(self: RDB, items: JsonNode):int =
#   defer: self.cleanUp()
#   self.sqlString = self.insertValueBuilder(items).sqlString
#   if self.db.isNil:
#     let db = db()
#     defer: db.close()
#     logger(self.sqlString, self.placeHolder)
#     result = db.tryInsertID(sql self.sqlString, self.placeHolder).int()
#   else:
#     # in Transaction
#     logger(self.sqlString, self.placeHolder)
#     result = self.db.tryInsertID(sql self.sqlString, self.placeHolder).int()

# proc insertID*(self: RDB, rows: openArray[JsonNode]):int =
#   defer: self.cleanUp()
#   self.sqlString = self.insertValuesBuilder(rows).sqlString
#   var response: int
#   if self.db.isNil:
#     logger(self.sqlString, self.placeHolder)
#     let db = db()
#     defer: db.close()
#     response = db.tryInsertID(sql self.sqlString, self.placeHolder).int()
#     self.placeHolder = @[]
#   else:
#     logger(self.sqlString, self.placeHolder)
#     response = self.db.tryInsertID(sql self.sqlString, self.placeHolder).int()
#     self.placeHolder = @[]
#   return response

# proc insertsID*(self: RDB, rows: openArray[JsonNode]):seq[int] =
#   defer: self.cleanUp()
#   var response = newSeq[int](rows.len)
#   if self.db.isNil:
#     let db = db()
#     defer: db.close()
#     for i, row in rows:
#       let sqlString = self.insertValueBuilder(row).sqlString
#       logger(sqlString, self.placeHolder)
#       response[i] = db.tryInsertID(sql sqlString, self.placeHolder).int()
#       self.placeHolder = @[]
#   else:
#     for i, row in rows:
#       let sqlString = self.insertValueBuilder(row).sqlString
#       logger(sqlString, self.placeHolder)
#       response[i] = self.db.tryInsertID(sql sqlString, self.placeHolder).int()
#       self.placeHolder = @[]
#   return response

# # ==================== UPDATE ====================

# proc updateSql*(self: RDB, items: JsonNode):string =
#   defer: self.cleanUp()
#   var updatePlaceHolder: seq[string]
#   for item in items.pairs:
#     if item.val.kind == JInt:
#       updatePlaceHolder.add($(item.val.getInt()))
#     elif item.val.kind == JFloat:
#       updatePlaceHolder.add($(item.val.getFloat()))
#     elif [JObject, JArray].contains(item.val.kind):
#       updatePlaceHolder.add($(item.val))
#     else:
#       updatePlaceHolder.add(item.val.getStr())

#   let placeHolder = updatePlaceHolder & self.placeHolder
#   let sqlString = self.updateBuilder(items).sqlString

#   result = sqlString & $placeHolder
#   echo result

# proc update*(self: RDB, items: JsonNode) =
#   defer: self.cleanUp()
#   var updatePlaceHolder: seq[string]
#   for item in items.pairs:
#     if item.val.kind == JInt:
#       updatePlaceHolder.add($(item.val.getInt()))
#     elif item.val.kind == JFloat:
#       updatePlaceHolder.add($(item.val.getFloat()))
#     elif item.val.kind == JBool:
#       updatePlaceHolder.add($(item.val.getBool()))
#     elif [JObject, JArray].contains(item.val.kind):
#       updatePlaceHolder.add($(item.val))
#     else:
#       updatePlaceHolder.add(item.val.getStr())

#   self.placeHolder = updatePlaceHolder & self.placeHolder
#   self.sqlString = self.updateBuilder(items).sqlString

#   if self.db.isNil:
#     logger(self.sqlString, self.placeHolder)
#     let db = db()
#     defer: db.close()
#     db.exec(sql self.sqlString, self.placeHolder)
#   else:
#     logger(self.sqlString, self.placeHolder)
#     self.db.exec(sql self.sqlString, self.placeHolder)


# # ==================== DELETE ====================

# proc deleteSql*(self: Rdb):string =
#   result = self.deleteBuilder().sqlString & $self.placeHolder
#   echo result

# proc delete*(self: RDB) =
#   defer: self.cleanUp()
#   self.sqlString = self.deleteBuilder().sqlString
#   if self.db.isNil:
#     logger(self.sqlString, self.placeHolder)
#     let db = db()
#     defer: db.close()
#     db.exec(sql self.sqlString, self.placeHolder)
#   else:
#     logger(self.sqlString, self.placeHolder)
#     self.db.exec(sql self.sqlString, self.placeHolder)

# proc delete*(self: RDB, id: int, key="id") =
#   defer: self.cleanUp()
#   self.placeHolder.add($id)
#   self.sqlString = self.deleteByIdBuilder(id, key).sqlString
#   if self.db.isNil:
#     logger(self.sqlString, self.placeHolder)
#     let db = db()
#     defer: db.close()
#     db.exec(sql self.sqlString, self.placeHolder)
#   else:
#     # in Transaction
#     logger(self.sqlString, self.placeHolder)
#     self.db.exec(sql self.sqlString, self.placeHolder)


# # ==================== EXEC ====================

# proc exec*(self: RDB) =
#   ## It is only used with raw()
#   defer: self.cleanUp()
#   if self.db.isNil:
#     let db = db()
#     defer: db.close()
#     logger(self.sqlString, self.placeHolder)
#     db.exec(sql self.sqlString, self.placeHolder)
#   else:
#     logger(self.sqlString, self.placeHolder)
#     self.db.exec(sql self.sqlString, self.placeHolder)


# # ==================== Aggregates ====================

# proc count*(self:RDB): int =
#   self.sqlString = self.countBuilder().sqlString
#   logger(self.sqlString, self.placeHolder)
#   let response =  getRow(self.sqlString, self.placeHolder)
#   if response.isSome:
#     let DRIVER = getDriver()
#     case DRIVER
#     of "sqlite":
#       return response.get["aggregate"].getStr().parseInt()
#     of "mysql":
#       return response.get["aggregate"].getInt()
#     of "postgres":
#       return response.get["aggregate"].getInt()
#   else:
#     return 0

# proc max*(self:RDB, column:string):Option[string] =
#   self.sqlString = self.maxBuilder(column).sqlString
#   logger(self.sqlString, self.placeHolder)
#   let response =  getRow(self.sqlString, self.placeHolder)
#   if response.isSome:
#     case response.get["aggregate"].kind
#     of JInt:
#       return some($(response.get["aggregate"].getInt))
#     of JFloat:
#       return some($(response.get["aggregate"].getFloat))
#     else:
#       return some(response.get["aggregate"].getStr)
#   else:
#     return none(string)

# proc min*(self:RDB, column:string):Option[string] =
#   self.sqlString = self.minBuilder(column).sqlString
#   logger(self.sqlString, self.placeHolder)
#   let response =  getRow(self.sqlString, self.placeHolder)
#   if response.isSome:
#     case response.get["aggregate"].kind
#     of JInt:
#       return some($(response.get["aggregate"].getInt))
#     of JFloat:
#       return some($(response.get["aggregate"].getFloat))
#     else:
#       return some(response.get["aggregate"].getStr)
#   else:
#     return none(string)

# proc avg*(self:RDB, column:string): Option[float] =
#   self.sqlString = self.avgBuilder(column).sqlString
#   logger(self.sqlString, self.placeHolder)
#   let response =  getRow(self.sqlString, self.placeHolder)
#   if response.isSome:
#     let DRIVER = getDriver()
#     case DRIVER
#     of "sqlite":
#       return response.get["aggregate"].getStr().parseFloat.some
#     else:
#       return response.get["aggregate"].getFloat.some
#   else:
#     return none(float)

# proc sum*(self:RDB, column:string): Option[float] =
#   self.sqlString = self.sumBuilder(column).sqlString
#   logger(self.sqlString, self.placeHolder)
#   let response =  getRow(self.sqlString, self.placeHolder)
#   if response.isSome:
#     let DRIVER = getDriver()
#     case DRIVER
#     of "sqlite":
#       return response.get["aggregate"].getStr.parseFloat.some
#     else:
#       return response.get["aggregate"].getFloat.some
#   else:
#     return none(float)


# # ==================== Paginate ====================

# from grammars import where, limit, offset, orderBy, Order

# proc paginate*(self:RDB, display:int, page:int=1): JsonNode =
#   if not page > 0: raise newException(Exception, "Arg page should be larger than 0")
#   let total = self.count()
#   let offset = (page - 1) * display
#   let currentPage = self.limit(display).offset(offset).get()
#   let count = currentPage.len()
#   let hasMorePages = if page * display < total: true else: false
#   let lastPage = int(total / display)
#   let nextPage = if page + 1 <= lastPage: page + 1 else: lastPage
#   let perPage = display
#   let previousPage = if page - 1 > 0: page - 1 else: 1
#   return %*{
#     "count": count,
#     "currentPage": currentPage,
#     "hasMorePages": hasMorePages,
#     "lastPage": lastPage,
#     "nextPage": nextPage,
#     "perPage": perPage,
#     "previousPage": previousPage,
#     "total": total
#   }


# proc getFirstItem(self:RDB, keyArg:string, order:Order=Asc):int =
#   var sqlString = self.sqlString
#   if order == Asc:
#     sqlString = &"{sqlString} ORDER BY {keyArg} ASC LIMIT 1"
#   else:
#     sqlString = &"{sqlString} ORDER BY {keyArg} DESC LIMIT 1"
#   let row = getRow(sqlString, self.placeHolder)
#   let key = if keyArg.contains("."): keyArg.split(".")[1] else: keyArg
#   if row.isSome:
#     return row.get[key].getInt
#   else:
#     return 0


# proc getLastItem(self:RDB, keyArg:string, order:Order=Asc):int =
#   var sqlString = self.sqlString
#   if order == Asc:
#     sqlString = &"{sqlString} ORDER BY {keyArg} DESC LIMIT 1"
#   else:
#     sqlString = &"{sqlString} ORDER BY {keyArg} ASC LIMIT 1"
#   let row = getRow(sqlString, self.placeHolder)
#   let key = if keyArg.contains("."): keyArg.split(".")[1] else: keyArg
#   if row.isSome:
#     return row.get[key].getInt
#   else:
#     return 0


# proc fastPaginate*(self:RDB, display:int, key="id", order:Order=Asc):JsonNode =
#   self.sqlString = @[self.selectBuilder().sqlString][0]
#   if order == Asc:
#     self.sqlString = &"{self.sqlString} ORDER BY {key} ASC LIMIT {display + 1}"
#   else:
#     self.sqlString = &"{self.sqlString} ORDER BY {key} DESC LIMIT {display + 1}"
#   logger(self.sqlString, self.placeHolder)
#   var currentPage = getAllRows(self.sqlString, self.placeHolder)
#   if currentPage.len > 0:
#     let newKey = if key.contains("."): key.split(".")[1] else: key
#     let nextId = currentPage[currentPage.len-1][newKey].getInt()
#     var hasNextId = true
#     if currentPage.len > display:
#       discard currentPage.pop()
#     else:
#       hasNextId = false
#     return %*{
#       "previousId": 0,
#       "hasPreviousId": false,
#       "currentPage": currentPage,
#       "nextId": nextId,
#       "hasNextId": hasNextId
#     }
#   else:
#     %*{
#       "previousId": 0,
#       "hasPreviousId": false,
#       "currentPage": currentPage,
#       "nextId": 0,
#       "hasNextId": false
#     }


# proc fastPaginateNext*(self:RDB, display:int, id:int, key="id",
#       order:Order=Asc):JsonNode =
#   if not id > 0: raise newException(Exception, "Arg id should be larger than 0")
#   self.sqlString = @[self.selectBuilder().sqlString][0]
#   let firstItem = getFirstItem(this, key, order)

#   let where = if self.sqlString.contains("WHERE"): "AND" else: "WHERE"
#   if order == Asc:
#     self.sqlString = &"""
# SELECT * FROM (
#   {self.sqlString} {where} {key} < {id} ORDER BY {key} DESC LIMIT 1
# ) x
# UNION ALL
# SELECT * FROM (
#   {self.sqlString} {where} {key} >= {id} ORDER BY {key} ASC LIMIT {display+1}
# ) x
# """
#   else:
#     self.sqlString = &"""
# SELECT * FROM (
#   {self.sqlString} {where} {key} > {id} ORDER BY {key} ASC LIMIT 1
# ) x
# UNION ALL
# SELECT * FROM (
#   {self.sqlString} {where} {key} <= {id} ORDER BY {key} DESC LIMIT {display+1}
# ) x
# """
#   self.placeHolder &= self.placeHolder
#   logger(self.sqlString, self.placeHolder)
#   var currentPage = getAllRows(self.sqlString, self.placeHolder)
#   if currentPage.len > 0:
#     let newKey = if key.contains("."): key.split(".")[1] else: key
#     # previous
#     var previousId = currentPage[0][newKey].getInt()
#     var hasPreviousId = true
#     if previousId != firstItem:
#       currentPage.delete(0)
#     else:
#       hasPreviousId = false
#     # next
#     var nextId = currentPage[currentPage.len-1][newKey].getInt()
#     var hasNextId = true
#     if currentPage.len > display:
#       discard currentPage.pop()
#     else:
#       hasNextId = false

#     return %*{
#       "previousId": previousId,
#       "hasPreviousId": hasPreviousId,
#       "currentPage": currentPage,
#       "nextId": nextId,
#       "hasNextId": hasNextId
#     }
#   else:
#     return %*{
#       "previousId": 0,
#       "hasPreviousId": false,
#       "currentPage": currentPage,
#       "nextId": 0,
#       "hasNextId": false
#     }


# proc fastPaginateBack*(self:RDB, display:int, id:int, key="id",
#       order:Order=Asc):JsonNode =
#   if not id > 0: raise newException(Exception, "Arg id should be larger than 0")
#   self.sqlString = @[self.selectBuilder().sqlString][0]
#   let lastItem = getLastItem(this, key, order)

#   let where = if self.sqlString.contains("WHERE"): "AND" else: "WHERE"
#   if order == Asc:
#     self.sqlString = &"""
# SELECT * FROM (
#   {self.sqlString} {where} {key} > {id} ORDER BY {key} ASC LIMIT 1
# ) x
# UNION ALL
# SELECT * FROM (
#   {self.sqlString} {where} {key} <= {id} ORDER BY {key} DESC LIMIT {display+1}
# ) x
# """
#   else:
#     self.sqlString = &"""
# SELECT * FROM (
#   {self.sqlString} {where} {key} < {id} ORDER BY {key} DESC LIMIT 1
# ) x
# UNION ALL
# SELECT * FROM (
#   {self.sqlString} {where} {key} >= {id} ORDER BY {key} ASC LIMIT {display+1}
# ) x
# """
#   self.placeHolder &= self.placeHolder
#   logger(self.sqlString, self.placeHolder)
#   var currentPage = getAllRows(self.sqlString, self.placeHolder)
#   if currentPage.len > 0:
#     let newKey = if key.contains("."): key.split(".")[1] else: key
#     # next
#     let nextId = currentPage[0][newKey].getInt()
#     var hasNextId = true
#     if nextId != lastItem:
#       currentPage.delete(0)
#     else:
#       hasNextId = false
#     # previous
#     let previousId = currentPage[currentPage.len-1][newKey].getInt
#     var hasPreviousId = true
#     if currentPage.len > display:
#       discard currentPage.pop()
#     else:
#       hasPreviousId = false

#     currentPage.reverse()

#     return %*{
#       "previousId": previousId,
#       "hasPreviousId": hasPreviousId,
#       "currentPage": currentPage,
#       "nextId": nextId,
#       "hasNextId": hasNextId
#     }
#   else:
#     return %*{
#       "previousId": 0,
#       "hasPreviousId": false,
#       "currentPage": currentPage,
#       "nextId": 0,
#       "hasNextId": false
#     }

import json, options, asyncdispatch, strutils
import database
import ../connection, ../utils, base, builders

proc toJson(driver:string, names, types:openArray[string], rows:openArray[seq[string]]):seq[JsonNode] =
  var response_table = newSeq[JsonNode](rows.len)
  for index, row in rows:
    var response_row = newJObject()
    for i, column in row:
      if column.len == 0:
        response_row[names[i]] = newJNull()
        continue
      case driver
      of "sqlite":
        discard
      of "mysql":
        discard
      of "postgres":
        if ["INT4"].contains(types[i]):
          response_row[names[i]] = newJInt(column.parseInt)
        else:
          response_row[names[i]] = newJString(column)

    response_table[index] = response_row
  return response_table

proc get*(self:Rdb):seq[JsonNode] =
  defer: self.cleanUp()
  self.sqlString = self.selectBuilder().sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    let r = self.db.query(self.sqlString, self.placeHolder)
    return toJson(
      getDriver(),
      r.columnNames(),
      r.columnTypes(),
      r.all()
    )
  except:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[JsonNode](0)

proc first*(self: Rdb):Option[JsonNode] =
  defer: self.cleanUp()
  self.sqlString = self.selectFirstBuilder().sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    let r = self.db.query(self.sqlString, self.placeHolder)
    return toJson(
      getDriver(),
      r.columnNames(),
      r.columnTypes(),
      @[r.all()[0]]
    )[0].some
  except:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return none(JsonNode)

# ========== insert ==========
proc insert*(self: RDB, items: JsonNode) =
  defer: self.cleanUp()
  self.sqlString = self.insertValueBuilder(items).sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    discard self.db.query(self.sqlString, self.placeHolder)
  except:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()

proc insert*(self: RDB, rows: openArray[JsonNode]) =
  defer: self.cleanUp()
  self.sqlString = self.insertValuesBuilder(rows).sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    discard self.db.query(self.sqlString, self.placeHolder)
  except:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()

proc inserts*(self: RDB, rows: openArray[JsonNode]) =
  defer: self.cleanUp()
  try:
    for row in rows:
      let sqlString = self.insertValueBuilder(row).sqlString
      logger(sqlString, self.placeHolder)
      discard self.db.query(sqlString, self.placeHolder)
      self.placeHolder = @[]
  except:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()

proc insertID*(self: RDB, items: JsonNode) =
  defer: self.cleanUp()
  self.sqlString = self.insertValueBuilder(items).sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    let r = self.db.query(self.sqlString, self.placeHolder)
    echo r.all()
  except:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()

# proc insertID*(self: RDB, rows: openArray[JsonNode]):int =
#   defer: self.cleanUp()
#   self.sqlString = self.insertValuesBuilder(rows).sqlString
#   var response: int
#   if self.db.isNil:
#     logger(self.sqlString, self.placeHolder)
#     let db = db()
#     defer: db.close()
#     response = db.tryInsertID(sql self.sqlString, self.placeHolder).int()
#     self.placeHolder = @[]
#   else:
#     logger(self.sqlString, self.placeHolder)
#     response = self.db.tryInsertID(sql self.sqlString, self.placeHolder).int()
#     self.placeHolder = @[]
#   return response

# proc insertsID*(self: RDB, rows: openArray[JsonNode]):seq[int] =
#   defer: self.cleanUp()
#   var response = newSeq[int](rows.len)
#   if self.db.isNil:
#     let db = db()
#     defer: db.close()
#     for i, row in rows:
#       let sqlString = self.insertValueBuilder(row).sqlString
#       logger(sqlString, self.placeHolder)
#       response[i] = db.tryInsertID(sql sqlString, self.placeHolder).int()
#       self.placeHolder = @[]
#   else:
#     for i, row in rows:
#       let sqlString = self.insertValueBuilder(row).sqlString
#       logger(sqlString, self.placeHolder)
#       response[i] = self.db.tryInsertID(sql sqlString, self.placeHolder).int()
#       self.placeHolder = @[]
#   return response


proc exec*(self: Rdb) =
  defer: self.cleanUp()
  try:
    logger(self.sqlString, self.placeHolder)
    discard self.db.query(self.sqlString, self.placeHolder)
  except:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
