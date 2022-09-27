# Zeppelin client running into YARN cluster in Docker

Zeppelin is a web-based notebook which brings data exploration, visualization, sharing and collaboration features to Spark.

Apache Spark is an open-source, distributed processing system used for big data workloads.

In this demo, a Zeppelin/Spark container uses a Hadoop YARN cluster as a resource management and job scheduling technology to perform distributed data processing.

This Docker image contains Zeppelin and Spark binaries prebuilt and uploaded in Docker Hub.

## Build Zeppelin/Spark image
```shell
$ git clone https://github.com/mkenjis/apache_binaries
$ wget https://archive.apache.org/dist/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz
$ wget https://downloads.apache.org/zeppelin/zeppelin-0.9.0/zeppelin-0.9.0-bin-netinst.tgz
$ docker image build -t mkenjis/ubzepp_img
$ docker login   # provide user and password
$ docker image push mkenjis/ubzepp_img
```

## Shell Scripts Inside 

> run_zeppl.sh

Sets up the environment for Zeppelin to get started by executing the following steps :
- sets environment variables for JAVA and ZEPPELIN
- starts the SSH service for passwordless SSH
- starts Zeppelin daemon

## Start Swarm cluster

1. start swarm mode in node1
```shell
$ docker swarm init --advertise-addr <IP node1>
$ docker swarm join-token manager  # issue a token to add a node as manager to swarm
```

2. add more managers in swarm cluster (node2, node3, ...)
```shell
$ docker swarm join --token <token> <IP nodeN>:2377
```

3. start a spark standalone cluster and spark client
```shell
$ docker stack deploy -c docker-compose.yml yarn
$ docker service ls
ID             NAME           MODE         REPLICAS   IMAGE                                 PORTS
io5i950qp0ac   yarn_hdp1      replicated   0/1        mkenjis/ubhdpclu_img:latest           
npmcnr3ihmb4   yarn_hdp2      replicated   0/1        mkenjis/ubhdpclu_img:latest           
uywev8oekd5h   yarn_hdp3      replicated   0/1        mkenjis/ubhdpclu_img:latest           
p2hkdqh39xd2   yarn_hdpmst    replicated   1/1        mkenjis/ubhdpclu_img:latest           
xf8qop5183mj   yarn_spk_cli   replicated   0/1        mkenjis/ubzepp_img:latest
```

## Set up Zeppelin/Spark client

1. access hadoop master node and copy hadoop conf files to spark client
```shell
$ docker container ls   # run in each node to identify hdpmst constainer
CONTAINER ID   IMAGE                         COMMAND                  CREATED              STATUS              PORTS      NAMES
a8f16303d872   mkenjis/ubhdpclu_img:latest   "/usr/bin/supervisord"   About a minute ago   Up About a minute   9000/tcp   yarn_hdp2.1.kumbfub0cl20q3jhdyrcep4eb
77fae0c411ce   mkenjis/ubhdpclu_img:latest   "/usr/bin/supervisord"   About a minute ago   Up About a minute   9000/tcp   yarn_hdpmst.1.r81pn190785n1hdktvrnovw86

$ docker container exec -it <hdpmst container ID> bash

$ vi setup_spark_files.sh
$ chmod u+x setup_spark_files.sh
$ ./setup_spark_files.sh
Warning: Permanently added 'spk_cli,10.0.2.11' (ECDSA) to the list of known hosts.
core-site.xml                                                      100%  137    75.8KB/s   00:00    
hdfs-site.xml                                                      100%  310   263.4KB/s   00:00    
yarn-site.xml                                                      100%  771   701.6KB/s   00:00
```

2. access spark client node and add parameters to spark-defaults.conf
```shell
$ docker container ls   # run it in each node and check which <container ID> is running the Spark client constainer
CONTAINER ID   IMAGE                                 COMMAND                  CREATED         STATUS         PORTS                                          NAMES
8f0eeca49d0f   mkenjis/ubzepp_img:latest   "/usr/bin/supervisord"   3 minutes ago   Up 3 minutes   4040/tcp, 7077/tcp, 8080-8082/tcp, 10000/tcp   yarn_spk_cli.1.npllgerwuixwnb9odb3z97tuh
e9ceb97de97a   mkenjis/ubhdpclu_img:latest           "/usr/bin/supervisord"   4 minutes ago   Up 4 minutes   9000/tcp                                       yarn_hdp1.1.58koqncyw79aaqhirapg502os

$ docker container exec -it <spk_cli ID> bash

$ vi $SPARK_HOME/conf/spark-defaults.conf
spark.driver.memory  1024m
spark.yarn.am.memory 1024m
spark.executor.memory  1536m
```

3. set Zeppelin binding address to 0.0.0.0 in $ZEPPL_HOME/conf/zeppelin-site.xml
```shell
$ cd $ZEPPL_HOME/conf   # this changes to /usr/local/zeppelin-0.9.0-bin-netinst/con
$ ls   
configuration.xsl  log4j.properties2              zeppelin-env.cmd.template
interpreter-list   log4j2.properties              zeppelin-env.sh.template
interpreter.json   log4j_yarn_cluster.properties  zeppelin-site.xml.template
log4j.properties   shiro.ini.template
$ cp zeppelin-site.xml.template zeppelin-site.xml         
$ vi zeppelin-site.xml  # change the binding address to 0.0.0.0

<property>
  <name>zeppelin.server.addr</name>
  <value>0.0.0.0</value>
  <description>Server binding address</description>
</property>
```

4. start the Zeppelin service
```shell
$ $ZEPPL_HOME/bin/zeppelin-daemon.sh start
Zeppelin start                                             [  OK  ]
$
```

5. in the browser, issue the address https://host:8080 to access the Zeppelin Notebook.

At upper right corner, click on anonymous -> Interpreter.

![ZEPPELIN home](docs/hdinsight-hive-zeppelin.png)

It shows many interpreters Zeppelin can work. Scroll down and look for spark framework.

![ZEPPELIN interpreter](docs/zeppelin-anon-interpreters.png)

Click on "edit" button and setup the following parameters :
```shell
spark.master = yarn
spark.submit.deployMode = client
spark.driver.memory = 1024m
spark.yarn.am.memory = 1024m
spark.executor.memory = 1536m
```

Click on Save -> OK to update and restart Zeppelin

Create a new notebook clicking on Notebook -> Create New Note and provide the following as shown

![ZEPPELIN query](docs/hdinsight-hive-zeppelin-create-notebook1.png)
![ZEPPELIN query](docs/hdinsight-hive-zeppelin-create-notebook2.png)

Issue Spark commands

![ZEPPELIN query](docs/hdinsight-hive-zeppelin-query.png)




