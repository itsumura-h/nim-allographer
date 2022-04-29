import ../table
import ../column

type IMigrate* = tuple
  migrateSql:proc(table:Table):string
  createIndex:proc(table, column:string):(string, string)
  # createIndex:proc(table, column:string):string
  dropTableQuery:proc(tableName:string):string
  dropIndexQuery:proc(indexName:string):string
  saveHistoryQuery:proc(query, txHash:string, status:bool, runAt:string):string
  migrateAlter:proc(column:Column, table:string):string
