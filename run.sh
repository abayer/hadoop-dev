#!/usr/bin/env bash

HADOOP_VERSION=hadoop-0.20.207.0-SNAPSHOT
HADOOP_SRC=/home/eli/src/cloudera/hadoop1
DEPLOY_BASE=/deploy
HADOOP_HOME=$DEPLOY_BASE/$HADOOP_VERSION
USER=eli

. util.sh

# Create and deploy hadoop configuration
deploy_hadoop $USER

# Initialize and start the file system
run_hdfs_cmd namenode -format

exec_hdfs start

run_hdfs_cmd dfsadmin -safemode leave

run_hdfs_cmd fs -chown hdfs:hadoop /

run_hdfs_cmd fs -mkdir /user/$USER
run_hdfs_cmd fs -chmod 755 /user/$USER
run_hdfs_cmd fs -chown $USER:$USER /user/$USER

run_hdfs_cmd fs -mkdir /tmp
run_hdfs_cmd fs -chmod 777 /tmp

run_hdfs_cmd fs -mkdir /mapred/system
run_hdfs_cmd fs -chmod 755 /mapred/system
run_hdfs_cmd fs -chown -R mapred:hadoop /mapred

# Create a file as a normal user
tmp=`mktemp`
run_cmd fs -put $tmp $(basename $tmp)
run_cmd fs -lsr /

# Start MR and run a job
exec_mr start

J=$HADOOP_HOME/hadoop-examples-*.jar
run_cmd jar $J pi -Dmapred.map.tasks=3 2 10

# Restart the daemons and run the job again
exec_mr stop
exec_hdfs stop
exec_hdfs start
run_hdfs_cmd dfsadmin -safemode leave
exec_mr start

run_cmd jar $J pi -Dmapred.map.tasks=3 2 10

exec_mr stop
exec_hdfs stop
