FROM mkenjis/ubspkcli_yarn_img

WORKDIR /usr/local

# wget https://downloads.apache.org/zeppelin/zeppelin-0.9.0/zeppelin-0.9.0-bin-netinst.tgz
ADD zeppelin-0.9.0-bin-netinst.tgz .

WORKDIR /root
RUN echo "" >>.bashrc \
 && echo 'export ZEPPL_HOME=/usr/local/zeppelin-0.9.0-bin-netinst' >>.bashrc \
 && echo 'export PATH=$PATH:$ZEPPL_HOME/bin' >>.bashrc \
 && echo 'export USE_HADOOP=false' >>.bashrc

# authorized_keys already create in ubjava_img to enable containers connect to each other via passwordless ssh
