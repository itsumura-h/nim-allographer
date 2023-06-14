```nim
rdb.create(
  table("user", [
    Column.increment("id"),
    Column.string("name").index(),
  ])
)

rdb.alter(
  table("user", [
    Column.increment("id"),
    Column.string("name").index(),
  ])
)
```

```nim
# schema_builder/models/column.nim
proc increment*(_:type Column, name:string):Column

# schema_builder/models/table.nim
proc table*(name:string, columns:seq[Column]):Table

# schema_builder/usecases/create.nim
proc create*(rdb:Rdb, tables:varges[Table])

# schema_builder/usecases/alter.nim
proc alter*(rdb:Rdb, tables:varges[Table])
```
