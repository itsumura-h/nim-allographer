import json
from strformat import `&`

import base, generators


## ==================== SELECT ====================

proc select*(this: RDB): RDB =
  return this
        .selectSql()
        .fromSql()
        .joinSql()
        .whereSql()
        .orWhereSql()
        .limitSql()
        .offsetSql()
