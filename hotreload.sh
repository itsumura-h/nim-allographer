if [ $# -ne 2 ]; then
  echo "実行するには2個の引数が必要です。
  第一引数: 監視対象ファイル名
  第二引数: 監視対象ファイルが更新された際に実行されるコ>マンド
  例： ./autoexec.sh a.cpp 'g++ a.cpp && ./a.cpp'"
  exit 1
fi
echo "監視対象 $1"
echo "実行コマンド $2"
INTERVAL=1 #監視間隔, 秒で指定
last=`ls --full-time $1 | awk '{print $6"-"$7}'`
while true; do
  sleep $INTERVAL
  current=`ls --full-time $1 | awk '{print $6"-"$7}'`
  if [ $last != $current ] ; then
    echo ""
    echo "updated: $current"
    last=$current
    eval $2
  fi
done