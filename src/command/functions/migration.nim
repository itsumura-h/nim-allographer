import ../../allographer/SchemaBuilder

proc migrate*(args:seq[string]):int =
  ## Create migrations table

  try:
    Schema().create([
      Table().create("migrations", [
        Column().increments("id"),
        Column().json("schema"),
        Column().datetime("created_at").default()
      ])
    ])
  except:
    echo getCurrentExceptionMsg()