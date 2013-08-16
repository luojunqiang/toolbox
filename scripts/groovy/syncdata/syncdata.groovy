#!/usr/bin/env groovy

import groovy.util.logging.*
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import ch.qos.logback.classic.encoder.PatternLayoutEncoder;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.classic.Level;
import ch.qos.logback.core.ConsoleAppender;
import ch.qos.logback.classic.LoggerContext;

import groovy.sql.Sql

// CLASSPATH=$CLASSPATH:$ORACLE_HOME/jdbc/lib/ojdbc6.jar

def configLogger() {
    LoggerContext lc = (LoggerContext) LoggerFactory.getILoggerFactory();
    ConsoleAppender<ILoggingEvent> ca = new ConsoleAppender<ILoggingEvent>();
    ca.setContext(lc);
    ca.setName('console');
    PatternLayoutEncoder pl = new PatternLayoutEncoder();
    pl.setContext(lc);
    //pl.setPattern("%d{YYYY-MM-DD HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n");
    pl.setPattern("%d{YYYY-MM-DD HH:mm:ss.SSS} %-5level %logger{36} - %msg%n");
    pl.start();
    ca.setEncoder(pl);
    ca.start();
    Logger rootLogger = lc.getLogger(Logger.ROOT_LOGGER_NAME);
    rootLogger.detachAndStopAllAppenders()
    rootLogger.addAppender(ca);
    rootLogger.setLevel(Level.INFO);
}

@Slf4j
class SyncData {
    SyncData() {}

    def config
    def source
    def target
    int totalCount = 0

    def parseParam(String configFile) {
        config = new ConfigSlurper().parse(new File(configFile).toURL())
        
        log.info "sync config sync = ${config.sync}"
        //log.info "sync config source = ${config.source}"
        //log.info "sync config target = ${config.target}"
    }

    def commit() {
        log.info 'commit work.'
        target.commit()
        source.commit()
    }

    def processRows(db, sqls, rows) {
        sqls.each { sql ->
            log.info "executing SQL [$sql] ..."
            db.withBatch(sql) { stmt ->
                rows.each { row ->
                    //println "row = $row"
                    stmt.addBatch(row)
                }
                int[] counts = stmt.executeBatch()
                //println "result = $counts"
            }
        }
    }

    def syncRows(rows) {
        if (rows.empty)
            return
        log.info "processing on source db ..."
        processRows(source, config.source.delete, rows)
        log.info "processing on target db ..."
        processRows(target, config.target.insert, rows)
        totalCount += rows.size()
        log.info "batch synced ${rows.size()} rows."
        if (config.sync.batchCommit)
            commit()
        rows.clear()
    }

    def syncData() {
        def rows = []
        source.eachRow(config.source.query) { row ->
            rows << row.toRowResult()
            if (rows.size() >= config.sync.batchCount) {
                syncRows(rows)
            }
        } 
        syncRows(rows)
    }

    def executeSqls(dbName, db, sqls) {
        if (sqls.empty)
            return
        log.info "executing SQL on db [$dbName] ..."
        sqls.each { sql ->
            log.info "executing SQL [$sql]"
            db.execute(sql)
        }
    }

    def connectDatabase() {
        source = Sql.newInstance("jdbc:oracle:thin:@127.0.0.1:1521:testdb", "testsync",
                      "testsync", "oracle.jdbc.driver.OracleDriver")
        source.connection.autoCommit = false
        target = Sql.newInstance("jdbc:oracle:thin:@127.0.0.1:1521:testdb", "testsync",
                      "testsync", "oracle.jdbc.driver.OracleDriver")
        target.connection.autoCommit = false
    }

    def run() {
        log.info 'start syncing ...'
        connectDatabase()
        log.info 'start preprocess ...'
        executeSqls('source', source, config.source.preprocess)
        executeSqls('target', target, config.target.preprocess)
        log.info 'start syncing ...'
        syncData()
        log.info 'start postprocess ...'
        executeSqls('source', source, config.source.postprocess)
        executeSqls('target', target, config.target.postprocess)
        commit()
        log.info "syncdata finished. total synced ${totalCount} rows."
    }
}

configLogger()
SyncData syncer = new SyncData()
syncer.parseParam(args[0])
syncer.run()
