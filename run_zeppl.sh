trap "{ echo Stopping play app >/tmp/msg.txt; /usr/bin/bash -c \"/root/stop_spark.sh\"; exit 0; }" SIGTERM

export JAVA_HOME=/usr/local/jre1.8.0
export CLASSPATH=$JAVA_HOME/lib
export PATH=$PATH:.:$JAVA_HOME/bin

export HADOOP_HOME=/usr/local/hadoop-2.7.3
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

export ZEPPL_HOME=/usr/local/zeppelin-0.9.0-bin-netinst
export PATH=$PATH:$ZEPPL_HOME/bin

service ssh start

echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
ssh-keyscan ${HOSTNAME} >~/.ssh/known_hosts
ssh-keyscan localhost >>~/.ssh/known_hosts
ssh-keyscan 0.0.0.0 >>~/.ssh/known_hosts

if [ -n "${SPARK_HOST_SLAVES}" ]; then

   sleep 20

   >${SPARK_HOME}/conf/slaves

   for SPARK_HOST in `echo ${SPARK_HOST_SLAVES} | tr ',' ' '`; do
      ssh-keyscan ${SPARK_HOST} >>~/.ssh/known_hosts
        ssh root@${SPARK_HOST} "cat /etc/hostname" >>${SPARK_HOME}/conf/slaves
   done

   # start Spark master and slaves nodes
   $SPARK_HOME/sbin/start-master.sh
   $SPARK_HOME/sbin/start-slaves.sh
fi

if [ -n "${HADOOP_HOST_MASTER}" ]; then

   sleep 30
   ssh-keyscan ${HADOOP_HOST_MASTER} >>~/.ssh/known_hosts
   scp root@${HADOOP_HOST_MASTER}:${HADOOP_CONF_DIR}/core-site.xml ${SPARK_HOME}/conf/core-site.xml
   scp root@${HADOOP_HOST_MASTER}:${HADOOP_CONF_DIR}/hdfs-site.xml ${SPARK_HOME}/conf/hdfs-site.xml
   scp root@${HADOOP_HOST_MASTER}:${HADOOP_CONF_DIR}/yarn-site.xml ${SPARK_HOME}/conf/yarn-site.xml

fi

$ZEPPL_HOME/bin/zeppelin-daemon.sh start