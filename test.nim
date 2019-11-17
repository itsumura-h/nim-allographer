import json
var columns: seq[JsonNode]
columns.add(
  %*{"key": "value"}
)

echo columns