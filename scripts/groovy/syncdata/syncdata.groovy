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
import groovy.time.*

import com.huawei.cbs.common.CommonFunction

// CLASSPATH=$CLASSPATH:$ORACLE_HOME/jdbc/lib/ojdbc6.jar:encrypasswd.jar

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

class BreakException extends Exception {
    public Throwable fillInStackTrace() {}
}

@Slf4j
class SyncData {
    SyncData() {}

    def bindingVars = [:]
    def config
    def source
    def target
    int totalCount = 0

    def commit() {
        log.info 'commit work.'
        target.commit()
        source.commit()
    }

    def processRows(db, sqls, rows) {
        sqls.each { sql ->
            def text = sql.toString()
            log.info "executing SQL [$text] ..."
            db.withBatch(text) { stmt ->
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
        if (config.sync.batch_commit)
            commit()
        rows.clear()
    }

    def syncData() {
        log.info 'start syncing ...'
        def querySql = config.source.query.toString()
        while (true) {
            def batchCount = 0
            def rows = []
            try {
                def procClosure = { row ->
                    def rr = row.toRowResult()
                    rr.putAll(bindingVars)
                    rows << rr
                    if (rows.size() >= config.sync.batch_size) {
                        syncRows(rows)
                        ++batchCount
                        if (config.sync.max_batch_count > 0
                                && batchCount >= config.sync.max_batch_count) {
                            throw new BreakException()
                        }
                    }
                }
                log.info "query source: [$querySql]"
                if (source.preCheckForNamedParams(querySql)) {
                    source.eachRow(querySql, bindingVars, procClosure)
                } else {
                    source.eachRow(querySql, procClosure)
                }
                syncRows(rows)
                break
            } catch (BreakException be) {
                log.info("processed $batchCount batch.")
            }
        }
    }

    def executeSqls(dbName, db, sqls) {
        if (sqls.empty)
            return
        log.info "executing SQL on db [$dbName] ..."
        sqls.each { sql ->
            def text = sql.toString()
            log.info "executing SQL [$text]"
            if (db.preCheckForNamedParams(text)) {
                db.execute(text, bindingVars)
            } else {
                db.execute(text)
            }
        }
    }

    def initSync(args) {
        ParamManager pm = new ParamManager()
        pm.init()
        String syncConfigName = args.remove(0)
        String configText
        if (syncConfigName.startsWith("@")) {
            configText = pm.getConfigText(syncConfigName.substring(1))
        } else {
            configText = new File(syncConfigName).toURL().text
        }
        log.info "sync config:\n$configText"
        def configSluper = new ConfigSlurper()

        // set config binding variables
        args.each {
            int pos = it.indexOf('=')
            bindingVars[it.substring(0, pos)] = it.substring(pos + 1)
        }
        log.info("binding vars=$bindingVars")
        configSluper.setBinding(bindingVars)

        config = configSluper.parse(configText)

        // connect databases
        source = pm.getDbConnection(config.source.database.server)
        target = pm.getDbConnection(config.target.database.server)

        pm.close()
        pm = null
    }

    def preProcess() {
        log.info 'start preprocess ...'
        executeSqls('source', source, config.source.preprocess)
        executeSqls('target', target, config.target.preprocess)
    }

    def postProcess() {
        log.info 'start postprocess ...'
        executeSqls('source', source, config.source.postprocess)
        executeSqls('target', target, config.target.postprocess)
    }

    def run(args) {
        log.info 'start syncing ...'
        initSync(args as List)
        while (true) {
            totalCount = 0
            def timeStart = new Date()
            preProcess()
            syncData()
            postProcess()
            commit()
            def timeStop = new Date()
            def duration = TimeCategory.minus(timeStop, timeStart)
            def ms = duration.toMilliseconds()
            log.info "syncdata total synced ${totalCount} rows, used ${duration}(${ms} ms)."
            if (!config.sync.non_stop)
                break
            log.info "sleep $config.sync.sleep_seconds seconds ..."
            sleep(config.sync.sleep_seconds * 1000)
        }
    }
}

configLogger()
SyncData syncer = new SyncData()
syncer.run(args)


// On Error: Your JDBC driver may not support null arguments for setObject. Consider using Groovy's InParameter feature
// Try use a modern JDBC driver.

