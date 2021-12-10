export JAVA_HOME=/usr/local/jre1.8.0
export CLASSPATH=$JAVA_HOME/lib
export PATH=$PATH:.:$JAVA_HOME/bin

export ZEPPL_HOME=/usr/local/zeppelin-0.9.0-bin-netinst
export PATH=$PATH:$ZEPPL_HOME/bin

service ssh start

$ZEPPL_HOME/bin/zeppelin-daemon.sh start