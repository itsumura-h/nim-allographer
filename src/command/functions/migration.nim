import ../../allographer/SchemaBuilder

proc migrate*(rebuild=false, args:seq[string]):int =
  ## Create migrations table

  try:
    Schema().create([
      Table().create("migrations", [
        Column().increments("id"),
        Column().json("schema"),
        Column().datetime("created_at").default()
      ], isRebuild=rebuild)
    ])
  except:
    echo getCurrentExceptionMsg()