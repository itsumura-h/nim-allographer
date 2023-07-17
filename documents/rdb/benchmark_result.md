## index
<!--ts-->
   * [index](#index)
   * [0.23.4](#0234)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->
<!-- Added by: root, at: Mon Jul 17 07:17:11 UTC 2023 -->

<!--te-->

## 0.23.4
```sh
cd example
DB_POSTGRES=true nim c -r -d:release --threads:off -d:danger --mm:orc benchmark
```

query
|num|time|
|---|---|
|1|0.938770656|
|2|6.643012469|
|3|6.493994112999999|
|4|6.292020136999998|
|5|6.618309597|
|Avg|5.3972213944|

update
|num|time|
|---|---|
|1|0.3599897400000001|
|2|0.2508196720000004|
|3|0.1847369050000012|
|4|0.2267158040000012|
|5|0.2636497700000007|
|Avg|0.2571823782000007|
