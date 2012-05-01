#!/bin/sh
# Parallel Launcher v2.0
# by luojunqiang@gmail.com at 2012-04-07

LANG=C; export LANG
# set -x
set -u -e

log() { echo `date "+%Y-%m-%d %H:%M:%S"`" #  $@"; }

show_usage() {
    echo "## Parallel Launcher v2.0 ##"
    echo "usage: $0 command ..."
    echo "   $0 task_name run  batch_size data_file worker_count task_cmd args..."
    echo "   $0 task_name init batch_size data_file worker_count task_cmd args..."
    echo "   $0 task_name test"   # do a test run, only process one file then stop.
    echo "   $0 task_name start [worker_count]"
    echo "   $0 task_name stop  [worker_count]"
    echo "   $0 task_name abort"
    echo "   $0 task_name status [sleep_seconds [custom_command] ]"
    echo "   $0 task_name list"
    echo "   $0 task_name pack"
    echo "   $0 seq format from count step"
    echo "   $0 clean"
    echo
    echo "   Enviorment variables available in shell: PL_TASK_DIR  PL_INPUT_FILE"
    echo "   Notify exec file when done: \$task_name/pl_notify"
    echo
    echo " e.g."
    echo "   $0 create_tab_index run  5 parts.txt 20 create_index.sh billcompare/billcompare"
    echo "   $0 create_tab_index init 5 parts.txt 20 create_index.sh billcompare/billcompare"
    echo "   $0 create_tab_index start"
    echo "   $0 seq P%03d 1 10 1"
    echo
    exit 1 #$1
}

generate_seq() {
    local format=$1  i=$2  tmp=
    test $# -ge 4 && tmp=$4
    local limit=$((i+$3))  step=${tmp:=1}
    while [ $i -lt $limit ]; do
        printf "$format\n" $i
        i=$((i + step))
    done
}

clean_cwd() {
    date "+%Y%m%d %Y%m%d%H%M%S" | read day now
    mkdir -p pl.backup/$day
    test -f tmp.sh && mv tmp.sh pl.backup/$day/tmp.sh.$now && ls -l pl.backup/$day/tmp.sh.$now
}

check_task_valid()   { test -d $task_name/worker/running || { echo "[$task_name] is not a valid task directory!"; return 1; } }

check_task_stopped() {
    local rc=0;
    find $task_name/worker/running -type f |wc -l |read rc;
    test $rc -eq 0 || { echo "task[$task_name] has $rc workers still running!"; return 2; }
}

init_task() { # init batch_size data_file worker_count cmd_line...
    local split_lines=$2  data_file=$3  worker_count=$4
    shift 4
    mkdir -p $task_name
    mkdir $task_name/data $task_name/worker $task_name/tmp $task_name/log
    mkdir $task_name/data/ready $task_name/data/proc $task_name/data/done
    mkdir $task_name/worker/running $task_name/worker/stopped $task_name/worker/finished    # worker pid folders
    split -a4 -l $split_lines $data_file $task_name/data/ready/input.
    echo "$@" >$task_name/.pl.task_cmdline
    echo $worker_count >$task_name/.pl.worker_count
}

start_workers() { # start/test [number_of_new_workers]
    local worker_count=0 i=1 worker_num_limit=0
    if [ "$1" = test ]; then
        check_task_stopped || return 1
        i=0  worker_count=1  worker_num_limit=1
    else
        test -f $task_name/.pl.next_worker_num && i=`<$task_name/.pl.next_worker_num`
        if [ $# -ge 2 ]; then  # specified number_of_new_workers
            worker_count=$2
            worker_num_limit=$((i + worker_count))
        else
            worker_count=`<$task_name/.pl.worker_count`
            worker_num_limit=$((1 + worker_count))
        fi
        echo $worker_num_limit > $task_name/.pl.next_worker_num
    fi
    touch $task_name/pl.running.ctl  # worker controller
    while [ $i -lt $worker_num_limit ]; do
        local worker_num=`printf %04d $i`
        nohup $0 $task_name _pl_worker_ $worker_num >>$task_name/worker/worker.$worker_num.log 2>>$task_name/worker/worker.$worker_num.err &
        log "launched worker.$worker_num [$!]."
        i=$((i + 1))
    done
    log "total started $worker_count workers."
}

run_worker() { # cmd worker_num
    local worker_num=$2  task_stop_flag=  work_file=  task_cmdline=`<$task_name/.pl.task_cmdline`
    log "worker $task_name - $worker_num [pid=$$] started."
    echo $$ >$task_name/worker/running/worker.$worker_num.pid
    trap "task_stop_flag=${task_stop_flag:-stopped}" INT TERM EXIT
    while test -z "$task_stop_flag" ; do
        test -f $task_name/pl.running.ctl ||{ log "canceling worker." && task_stop_flag=stopped && break; }
        ls $task_name/data/ready/ |read task_file ||{ log "no more input." && task_stop_flag=finished && break; }
        work_file=$task_file.$worker_num
        if mv $task_name/data/ready/$task_file $task_name/data/proc/$work_file 2>/dev/null; then
            log "processing [$task_file]."
            PL_TASK_DIR=$task_name PL_INPUT_FILE=$task_name/data/proc/$work_file \
            $task_cmdline <$task_name/data/proc/$work_file >$task_name/log/$work_file.out 2>$task_name/log/$work_file.err || {
                log "run [$task_cmdline] to process [$task_file] failed!"
                task_stop_flag=stopped && break;
            }
            mv $task_name/data/proc/$work_file $task_name/data/done/$work_file
        fi
        test ${worker_num} -eq 0 && task_stop_flag=stopped && log "one file processed, test worker stopping."
    done
    mv $task_name/worker/running/worker.$worker_num.pid $task_name/worker/$task_stop_flag/
    log "worker $task_name - $worker_num [pid=$$] $task_stop_flag."
    test -x $task_name/pl_notify && test `ls $task_name/worker/running/|wc -l` -eq 0 && {  # notify when all worker finished.
        if mv $task_name/pl_notify $task_name/pl_notify.$worker_num 2>/dev/null; then
            log "all worker done, exec notify."
            task_name=$task_name $task_name/pl_notify.$worker_num $task_name
        fi
    }
    trap - INT TERM EXIT
}

show_status() {
    local sleep_seconds=0  has_custom_cmd=n
    case $# in
    1)   ;;
    2)   sleep_seconds=$2; shift 1 ;;
    *)   sleep_seconds=$2; has_custom_cmd=y; shift 2 ;;
    esac
    while true; do
        log "task[$task_name] status:"
        echo log "info ==="
        ls -ltr $task_name/log/|tail -n 15
        echo
        find $task_name/data -type f -name 'input.*'|awk '/\/ready\//{r+=1} /\/proc\//{p+=1} /\/done\//{d+=1}
            END{printf("task status: ======\n  task ready: %4d\n  task proc:  %4d\n  task done:  %4d\n\n",r,p,d)}'
        find $task_name/worker -type f -name '*.pid'|awk '/\/finished\//{f+=1} /\/stopped\//{s+=1} /\/running\//{r+=1}
            END{printf("worker status: ======\n  worker running:  %4d\n  worker stopped:  %4d\n  worker finished: %4d\n\n",r,s,f)}'
        test $has_custom_cmd = y && $@
        test $sleep_seconds -eq 0 && break
        check_task_stopped && echo "=== All worker stopped. ===" && break
        sleep $sleep_seconds
        echo ==========================================
    done
}

pack_dir() {
    if [ $task_name = "." ]; then
        task_name=`pwd`
        task_name=`basename $task_name`
        cd ..
    fi
    date "+%Y%m%d %Y%m%d%H%M%S" | read day now
    mkdir -p pl.backup/$day
    tar cf - $task_name |gzip -c > pl.backup/$day/$task_name.$now.tgz && rm -rf $task_name
    ls -l pl.backup/$day/$task_name.$now.tgz
}

###########################################################
test $# -gt 0 || show_usage

case $1 in
seq)   shift; generate_seq "$@"; exit;;
clean) shift; clean_cwd "$@"; exit;;
help)  show_usage; exit;;
esac

task_name=$1
shift
cmd=$1

case $cmd in
run|launch|init) : ;;
*) check_task_valid || exit 1 ;;
esac

case $cmd in
run|launch)  # run batch_size data_file worker_count task_cmd args...
    init_task "$@" && start_workers $task_name ;;
init)   init_task "$@" ;;    # init batch_size data_file worker_count task_cmd args...
start)  start_workers "$@" ;;    # start [worker_count]
test)   start_workers "$@" ;;    # test
stop)   rm $task_name/pl.running.ctl ;;
abort)  rm -f $task_name/pl.running.ctl && cat $task_name/worker/running/worker.*.pid |xargs echo kill -9 ;;
abort!) rm -f $task_name/pl.running.ctl && cat $task_name/worker/running/worker.*.pid |xargs kill -9 ;;
list)   find $task_name/worker/running/ -type f -name '*.pid' -exec cat {} \;|awk '{printf("  running_worker_pid: %s\n", $0)}' ;;
status) show_status "$@";;
pack)   check_task_stopped && pack_dir ;;
pack!)  pack_dir ;;
#----------------------------------------------------------
_pl_worker_)  run_worker "$@";;
*)  log "error: unknown command[$cmd]!" && show_usage ;;
esac
# EOF #
