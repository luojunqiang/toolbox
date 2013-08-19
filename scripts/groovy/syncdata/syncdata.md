# syncdata 说明 #

## 简介 ##

syncdata 用于将源表中的数据同步到目标表中。可以支持跨数据库的同步。


## syncdata的配置文件说明 ##

配置文件样例参考`syncdata.conf`。

### 配置参数说明 ###

* `sync.batch_size = 200`

    每批次的条数。每从源表中查询出`sync.batch_size`条记录，就会批量进行一次数据同步。
    
* `sync.batch_commit = true`

    达到批次条数，完成批量同步后，是否执行数据库提交操作。

* `sync.max_batch_count = 0`

    处理`sync.max_batch_count`批次后，重新打开源数据库上的查询游标获取待同步的数据。

* `sync.non_stop = true`

    同步程序是否一直执行不退出。

* `sync.sleep_seconds = 30`

    在同步程序不退出的模式下，完成一次全量数据的同步后，再进行下一次同步前休眠的秒数。

* `source.database.server = "data_sync_src"`

    数据同步源数据库的连接名称

* `source.preprocess = [ "sql1", "sql2", ...]`

    数据同步前在源数据库执行的SQL列表。

* `source.query = "select * from source_table_name"`

    同步数据源查询SQL。

* `source.delete = ["delete from source_table_name where rowid=:rowid and ..."]`

    删除源数据的SQL列表。配置为空则不做源删除操作。也可以配置update语句修改源数据的同步状态。

* `source.postprocess = ["sql1", "sql2", ...]`

    所有数据同步完成后，在源数据库上执行的后处理SQL语句列表。

* `target.database.server = "data_sync_dst"`

    数据同步目标数据库的连接名称

* `target.preprocess = [ "sql1", "sql2", ...]`

    数据同步前在目标数据库执行的SQL列表。

* `target.insert = ["insert into target_table_name (...) values (...)"]`

    数据同步在目标数据库增加记录的SQL语句。可以配置多条语句同步到多个目标表中。

* `target.postprocess = ["sql1", "sql2", ...]`

    所有数据同步完成后，在目标数据库上执行的后处理SQL语句列表。

### 配置中的变量使用 ###

在配置文件中的SQL语句中可以使用两类变量：

1. `source.query`查询SQL语句中查询出的字段

  这种字段可以以`:COLUMN_NAME`的方式在`source.delete`和`target.insert`SQL语句中作为绑定变量使用，建议使用大写。
  `source.query`查询SQL语句中查询出的每个字段都需要有名字，否则无法在其他的同步用SQL中引用该字段的值。

2. 在程序命令行上指定的变量

  此类变量在命令行上以`var_name=var_value`的方式进行定义。
  可以以`:var_name`的方式用于任何SQL语句中作为绑定变量，
  也可以以`${var_name}`或`$var_name`的方式用于任何配置中作为替换变量将配置中的变量替换为其对应的取值。


## syncdata的工作流程 ##

    连接源数据库和目标数据库
    while (true) {
        准备同步
            在源数据库上依次执行`source.preprocess`中配置的所有SQL
            在目标数据库上依次执行`source.preprocess`中配置的所有SQL
        while (true) {
            batchCount = 0
            在源数据库上执行`source.query`中配置的SQL查询待同步的记录
            while (true) {
                从查询结果中读取一批次sync.batch_size条记录执行同步
                    在源数据库上执行`source.delete`中配置的SQL删除源数据
                    在目标数据库上执行`target.insert`中配置的SQL增加记录
                    如果`sync.batch_commit`配置为`true`则依次提交目标和源数据库
                ++batchCount
                if (sync.maxBatchCount != 0 && batchCount >= sync.maxBatchCount)
                    break
                if 所有源数据都已同步完成
                    break
            }
            if 所有源数据都已同步完成
                break
        }        
        进行后处理操作
            在源数据库上执行`source.postprocess`中配置的SQL
            在目标数据库上执行`target.postprocess`中配置的SQL
        依次提交目标和源数据库
        if (not `sync.nonStop`)
            break
        sleep(sync.sleep_seconds)        
    }


## syncdata的运行 ##

运行syncdata的命令行如下：

    syncdata.groovy <配置文件名> var1=value1 var2=value2 ...

* 其中`<配置文件名>`用于指定本地的配置文件
* 其中的变量定义可以用于替换配置中的内容，实现配置模板的能力，避免相似的配置需要重复进行配置的情况。

## 其他注意事项 ##

* 运行syncdata需要安装groovy，并配置好相关的CLASSPATH。
* JDBC驱动程序尽量使用新版本，旧版本可能不支持某些特性。

