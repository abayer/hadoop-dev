#!/usr/bin/env bash

#
# Create conf dirs for each pseudo "host"
#
function create_confs () {
    local user=$1
    for dir in dir-nn dir-2nn dir-jt dir-s1 dir-s2 dir-s3
    do
        dir_path=$HADOOP_HOME/$dir
        if [ -d "$dir_path" ] && [ "$dir_path" != "$HADOOP_HOME" ]; then
            rm -rf $dir_path
        fi
        mkdir $dir_path
        cp -r conf/20x $dir_path/conf
        # xx use HADOOP_HOME 
        sed -i "s/_ROOT_/\/home\/eli\/src\/cloudera\/hadoop1\/$dir/g" \
            $dir_path/conf/*
        sed -i "s/_USER_/$user/g" $dir_path/conf/*
        for d in tmp logs pids dfs mapred
        do
            mkdir $dir_path/$d
        done
    done
}

#
# Run the given daemon using the given and command, out of the given
# directory with the given configuration dir. Restarts the daemon if
# it's already running.
#
function run_daemon () {
    local user=$1
    local cmd=$2
    local daemon=$3
    local dir=$4
    local conf=$HADOOP_HOME/$dir/conf
    . $HADOOP_HOME/bin/hadoop-config.sh
    local pid_file=$HADOOP_HOME/$dir/pids/hadoop-$user-$daemon.pid
    if [ -e $pid_file ] && [ "start" = "$cmd" ]; then
        pid=`cat $pid_file`
        if [ -e /proc/$pid ]; then
            echo $daemon already running
            run_daemon $user stop $daemon $dir
            while [ -e /proc/$pid ]; do
                echo wait for $daemon to stop
                sleep 1
            done
        fi
    fi
    $HADOOP_HOME/bin/hadoop-daemon.sh --config $conf $cmd $daemon
}

#
# Run a hadoop command with a given conf dir
#
function run_cmd () {
    local dir=$1
    shift
    HADOOP_CONF_DIR=$HADOOP_HOME/$dir/conf $HADOOP_HOME/bin/hadoop $*
}

function format_nn () {
    run_cmd dir-nn namenode -format
}

#
# Run the given command on all the daemons
#
function exec_all () {
    local user=$1
    local cmd=$2
    run_daemon $user $cmd namenode dir-nn
    run_daemon $user $cmd jobtracker dir-jt
    run_daemon $user $cmd datanode dir-s1
    run_daemon $user $cmd datanode dir-s2
    run_daemon $user $cmd datanode dir-s3
    run_daemon $user $cmd tasktracker dir-s1
    run_daemon $user $cmd tasktracker dir-s2
    run_daemon $user $cmd tasktracker dir-s3
}
