#!/usr/bin/env bash

HADOOP_VERSION=hadoop-0.20.207.0-SNAPSHOT
DEPLOY_BASE=/deploy
HADOOP_HOME=$DEPLOY_BASE/$HADOOP_VERSION
USER=eli

. util.sh

J=$HADOOP_HOME/hadoop-examples-*.jar
run_cmd fs -rmr /user/$USER/PiEstimator*
run_cmd jar $J pi -Dmapred.map.tasks=3 2 10

