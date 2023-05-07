import std/asyncdispatch
import std/httpclient
import std/strutils
import std/base64

const database = "test:test"
const user = "user"
const password = "password"


proc main() {.async.} =
  let client = newAsyncHttpClient()
  var headers = newHttpHeaders(true)
  headers["NS"] = database.split(":")[0]
  headers["DB"] = database.split(":")[1]
  headers["Accept"] = "application/json"
  headers["Authorization"] = "Basic " & base64.encode(user & ":" & password)
  client.headers = headers

  let url = "http://surreal:8000/status"
  let resp = client.get(url).await

  echo resp.status
  echo resp.body().await

waitFor main()
