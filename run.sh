#!/usr/bin/env bash

HADOOP_HOME=/home/eli/src/cloudera/hadoop1

. util.sh

#exec_all eli stop
#exit

#create_confs eli
#format_nn
#exit

exec_all eli start
run_cmd dir-nn dfsadmin -safemode leave

run_cmd dir-nn fs -lsr /

J=$HADOOP_HOME/build/hadoop-examples-*.jar
run_cmd dir-nn jar $J pi -Dmapred.map.tasks=3 2 10

