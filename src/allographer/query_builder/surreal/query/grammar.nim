import std/json
import ../surreal_types


# https://surrealdb.com/docs/surrealql/statements/select
#[
SELECT
FROM
WHERE
SPLIT AT
ORDER BY
GROUP BY
LIMIT BY
START AT
FETCH
TIMEOUT
PARALLEL
]#


# ============================== Raw query ==============================

proc raw*(self:SurrealDb, sql:string, arges:varargs[string]): RawQuerySurrealDb =
  return  RawQuerySurrealDb(
    conn:self.conn,
    log: self.log,
    query: newJObject(),
    queryString: sql,
    placeHolder: @arges,
    isInTransaction:self.isInTransaction,
    transactionConn:self.transactionConn
  )
