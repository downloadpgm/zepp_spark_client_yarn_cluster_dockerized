FROM mkenjis/ubjava_img

#ARG DEBIAN_FRONTEND=noninteractive
#ENV TZ=US/Central

WORKDIR /usr/local

# wget https://archive.apache.org/dist/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz
ADD spark-2.3.2-bin-hadoop2.7.tgz .
# wget https://downloads.apache.org/zeppelin/zeppelin-0.9.0/zeppelin-0.9.0-bin-netinst.tgz
ADD zeppelin-0.9.0-bin-netinst.tgz .

WORKDIR /root
RUN echo "" >>.bashrc \
 && echo 'export SPARK_HOME=/usr/local/spark-2.3.2-bin-hadoop2.7' >>.bashrc \
 && echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native' >>.bashrc \
 && echo 'export HADOOP_CONF_DIR=$SPARK_HOME/conf' >>.bashrc \
 && echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >>.bashrc \
 && echo "" >>.bashrc \
 && echo 'export ZEPPL_HOME=/usr/local/zeppelin-0.9.0-bin-netinst' >>.bashrc \
 && echo 'export PATH=$PATH:$ZEPPL_HOME/bin' >>.bashrc \
 && echo 'export USE_HADOOP=false' >>.bashrc

# authorized_keys already create in ubjava_img to enable containers connect to each other via passwordless ssh
 
COPY run_zeppl.sh .
RUN chmod +x run_zeppl.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord"]