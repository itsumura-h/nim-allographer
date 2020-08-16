import asyncdispatch, asyncnet

type
  AcyncpgConnection = ref object
  ConnectionParameters = ref object
    user* :string
    password* :string
    database* :string
    timeOut* :int



proc connection*(host="localhost", port=5432, user="", password="", database=""):owned(Future[void]) =
  let socket = newAsyncSocket()
  return socket.connect(address=host, port=Port(port))

when isMainModule:
  echo connection(host="postgres").repr
