import ../src/allographer/schema_builder
import ../src/allographer/query_builder

schema([
  table("auth", [
    Column().increments("id"),
    Column().string("name"),
    Column().timestamps()
  ]),
  table("users", [
    Column().increments("id"),
    Column().string("name"),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ], reset=true)
])

let users = rdb()
          .table("users")
          .select("id", "name")
          .paginate(3, 1)
