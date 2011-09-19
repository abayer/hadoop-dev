#!/usr/bin/env bash

#
# Unpack the tarball to the deployment dir and create 
# conf dirs for each pseudo "host".
#
function deploy_hadoop () {
    local user=$1
    # Create the deployment dir
    if [ -d "$HADOOP_HOME" ]; then
        sudo rm -rf $HADOOP_HOME
    fi
    sudo chown -R $user:$user $DEPLOY_BASE
    tar -xzf $HADOOP_TARBALL -C $DEPLOY_BASE
    # Create dirs and configs for each pseudo host
    for dir in dir-nn dir-2nn dir-jt dir-s1 dir-s2 dir-s3
    do
        dir_path=$HADOOP_HOME/$dir
        if [ -d "$dir_path" ] && [ "$dir_path" != "$HADOOP_HOME" ]; then
            rm -rf $dir_path
        fi
        mkdir $dir_path
        cp -r conf/20x $dir_path/conf
        # xx Use HADOOP_HOME 
        sed -i "s/_ROOT_/\/deploy\/$HADOOP_VERSION\/$dir/g" \
            $dir_path/conf/*
        sed -i "s/_USER_/$user/g" $dir_path/conf/*
        sudo chown root:hadoop $dir_path/conf
        for d in bin tmp logs pids dfs mapred
        do
            mkdir $dir_path/$d
            sudo chgrp -R hadoop $dir_path/$d
            sudo chmod g+w $dir_path/$d
        done
        sudo chown hdfs:hadoop $dir_path/dfs
        sudo chown mapred:hadoop $dir_path/mapred
        # Build and deploy the task-controller for each host since
        # the path to the config file is baked into the binary and
        # each config file contains host-specif paths.
        if [ "$dir" = "dir-s1" ] ||
           [ "$dir" = "dir-s2" ] ||
           [ "$dir" = "dir-s3" ]; then
            pushd $HADOOP_HOME
            ant task-controller -Dhadoop.conf.dir=$dir_path/conf
            cp ./build/$HADOOP_VERSION/bin/task-controller $dir_path/bin
            sudo chown root:mapred $dir_path/bin/task-controller
            sudo chmod 6050 $dir_path/bin/task-controller
            sudo chown root:mapred $dir_path/conf/taskcontroller.cfg
            sudo chmod 0400 $dir_path/conf/taskcontroller.cfg
            popd
        fi
        sudo chown root:hadoop $dir_path
    done
    # Paths including and leading up to the directories listed
    # in mapred.local.dir and hadoop.log.dir need to be owned by 
    # root and have 755 perms.
    sudo chown root:hadoop $HADOOP_HOME
    sudo chown root:hadoop $DEPLOY_BASE
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
    sudo -u $user $HADOOP_HOME/bin/hadoop-daemon.sh --config $conf $cmd $daemon
}

#
# Run a hadoop command
#
function run_cmd () {
    local dir="dir-nn"
    HADOOP_CONF_DIR=$HADOOP_HOME/$dir/conf $HADOOP_HOME/bin/hadoop $*
}

function run_hdfs_cmd () {
    local dir="dir-nn"
    HADOOP_CONF_DIR=$HADOOP_HOME/$dir/conf sudo -E -u hdfs \
        $HADOOP_HOME/bin/hadoop $*
}

#
# Run the given command on all the daemons
#
function exec_hdfs () {
    local cmd=$1
    run_daemon hdfs $cmd namenode dir-nn
    run_daemon hdfs $cmd datanode dir-s1
    run_daemon hdfs $cmd datanode dir-s2
    run_daemon hdfs $cmd datanode dir-s3
}

function exec_mr () {
    local cmd=$1
    run_daemon mapred $cmd jobtracker dir-jt
    run_daemon mapred $cmd tasktracker dir-s1
    run_daemon mapred $cmd tasktracker dir-s2
    run_daemon mapred $cmd tasktracker dir-s3
}


