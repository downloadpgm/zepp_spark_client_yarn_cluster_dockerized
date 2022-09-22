FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=US/Central

RUN apt-get update && apt-get install -y supervisor openssh-server openssh-client vim iputils-ping
 
WORKDIR /usr/local

# git clone https://github.com/mkenjis/apache_binaries
ADD jre-8u181-linux-x64.tar.gz .
# wget https://archive.apache.org/dist/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz
ADD spark-2.3.2-bin-hadoop2.7.tgz .
# wget https://downloads.apache.org/zeppelin/zeppelin-0.9.0/zeppelin-0.9.0-bin-netinst.tgz
ADD zeppelin-0.9.0-bin-netinst.tgz .

WORKDIR /root
RUN echo "" >>.bashrc \
 && echo 'export JAVA_HOME=/usr/local/jre1.8.0_181' >>.bashrc \
 && echo 'export CLASSPATH=$JAVA_HOME/lib' >>.bashrc \
 && echo 'export PATH=$PATH:.:$JAVA_HOME/bin' >>.bashrc \
 && echo "" >>.bashrc \
 && echo 'export SPARK_HOME=/usr/local/spark-2.3.2-bin-hadoop2.7' >>.bashrc \
 && echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native' >>.bashrc \
 && echo 'export HADOOP_CONF_DIR=$SPARK_HOME/conf' >>.bashrc \
 && echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >>.bashrc \
 && echo "" >>.bashrc \
 && echo 'export ZEPPL_HOME=/usr/local/zeppelin-0.9.0-bin-netinst' >>.bashrc \
 && echo 'export PATH=$PATH:$ZEPPL_HOME/bin' >>.bashrc \
 && echo 'export USE_HADOOP=false' >>.bashrc

# creates ssh private and public keys, 
# and creates authorized_keys to enable containers connect to each other via passwordless ssh
RUN /usr/bin/bash -c "ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null" \
 && cp .ssh/id_rsa.pub .ssh/authorized_keys
 
COPY run_zeppl.sh .
RUN chmod +x run_zeppl.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord"]