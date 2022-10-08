import asyncdispatch, random

randomize()

type Connection = ref object
  isBusy:bool
  id:int

proc getFreeConn(pool:seq[Connection]):Future[int] {.async.} =
  while true:
    for i in 0..pool.len-1:
      if not pool[i].isBusy:
        pool[i].isBusy = true
        return i
        break
    sleepAsync(10).await

proc freeConn(pool:seq[Connection], connI:int) {.async.} =
  pool[connI].isBusy = false

proc process1(pool:seq[Connection]) {.async.} =
  let connI = getFreeConn(pool).await
  echo connI
  sleepAsync(rand(100..2000)).await # 時間がかかる処理
  freeConn(pool, connI).await

proc process2(pool:seq[Connection]) {.async.} =
  let connI = getFreeConn(pool).await
  echo connI
  sleepAsync(rand(100..2000)).await # 時間がかかる処理
  freeConn(pool, connI).await

proc main() {.async.}=
  var pool = newSeq[Connection]()
  for i in 0..100:
    pool.add(Connection(isBusy:false, id:i))

  var futures1 = newSeq[Future[void]]()
  var futures2 = newSeq[Future[void]]()
  for _ in 0..200:
    futures1.add(process1(pool))
    futures2.add(process2(pool))

  all(futures1).await
  all(futures2).await

main().waitFor
