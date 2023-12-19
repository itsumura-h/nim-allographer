query_builder/models/xx/xx_exec.nim

```nim
# public exec

# return json
get() / first() / find() / insert() / insertId() / update() / delete()

# return string
getPlain() / firstPlain() / findPlain()

# aggregate
count()  / min() / max() / avg() / sum()
```

```nim
# private exec
getAllRows() / getRow() / exec() / insertId()
getAllRowsPlain() / getRowPlain()
```

query_builder/libs/xx/xx_impl.nim
```nim
query() / exec() / execGetValue()
rawQuery() / rawExec()
```

---
