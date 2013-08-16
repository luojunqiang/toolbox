# syncdata 说明 #

## 简介 ##

syncdata 用于将源表中的数据同步到目标表中。可以支持跨数据库的同步。


## syncdata的配置文件说明 ##

* `sync.driver = 'oracle.jdbc.driver.OracleDriver'`

    连接参数数据库的驱动类名。
    
* `sync.batchCount = 200`

    每批次的条数。每从源表中查询出batchCount条记录，就会批量进行一次数据同步。
    
* `sync.batchCommit = true`

    达到批次条数，完成批量同步后，是否执行数据库提交操作。

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

配置文件样例参考`syncdata.conf`。


## syncdata的工作流程 ##

1. 连接源数据库和目标数据库

2. 准备操作
  
  2.1 在源数据库上依次执行`source.preprocess`中配置的所有SQL
  
  2.2 在目标数据库上依次执行`source.preprocess`中配置的所有SQL

3. 在源数据库上执行`source.query`中配置的SQL查询待同步的记录

4. 对查询出的记录按批次执行同步，直至所有记录处理完毕

  4.1 在源数据库上执行`source.delete`中配置的SQL删除源数据
  
  4.2 在目标数据库上执行`target.insert`中配置的SQL增加记录
  
  4.3 如果`sync.batchCommit`配置为`true`则依次提交目标和源数据库

5. 进行后处理操作

  5.1 在源数据库上执行`source.postprocess`中配置的SQL
  
  5.2 在目标数据库上执行`target.postprocess`中配置的SQL

6. 依次提交目标和源数据库

7. syncdata的所有处理完成。


## syncdata的运行 ##

运行syncdata的命令行如下：

    syncdata.groovy <配置文件名>

运行syncdata需要安装groovy，并配置好相关的CLASSPATH。

