#!/usr/bin/env bash


HADOOP_VERSION=${HADOOP_VERSION:-hadoop-0.20.206.0-SNAPSHOT}
HADOOP_SRC=${HADOOP_SRC:-/home/eli/src/cloudera/hadoop1}
HADOOP_TARBALL=${HADOOP_TARBALL:-$HADOOP_SRC/build/$HADOOP_VERSION.tar.gz}
DEPLOY_BASE=${DEPLOY_BASE:-/deploy}
HADOOP_HOME=$DEPLOY_BASE/$HADOOP_VERSION
USER=${USER:-eli}

. util.sh

J=$HADOOP_HOME/hadoop-examples-*.jar
run_cmd fs -rmr /user/$USER/PiEstimator*
run_cmd jar $J pi -Dmapred.map.tasks=3 2 10

