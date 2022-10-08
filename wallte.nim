import
  random,
  unicode

randomize()

proc randStr(
  size: int = 40,
  alphabet: string = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYG"
):string {.gcsafe.} =
  for _ in 1..size:
    let index = rand(alphabet.runeLen()-1)
    result.add($alphabet.toRunes[index])

echo "0xabcde" & randStr(35,"1234567890")
echo randStr(5, "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワオン")
echo randStr() & "@test.mail"