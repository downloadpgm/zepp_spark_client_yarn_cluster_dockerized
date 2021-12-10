export SPARK_HOST=spk_cli
export HADOOP_HOME=/usr/local/hadoop-2.7.3
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_HOME=/usr/local/spark-2.3.2-bin-hadoop2.7

scp ${HADOOP_CONF_DIR}/core-site.xml root@${SPARK_HOST}:${SPARK_HOME}/conf/core-site.xml
scp ${HADOOP_CONF_DIR}/hdfs-site.xml root@${SPARK_HOST}:${SPARK_HOME}/conf/hdfs-site.xml
scp ${HADOOP_CONF_DIR}/yarn-site.xml root@${SPARK_HOST}:${SPARK_HOME}/conf/yarn-site.xml