# Zeppelin client running into YARN cluster in Docker

Zeppelin is a web-based notebook which brings data exploration, visualization, sharing and collaboration features to Spark.

Apache Spark is an open-source, distributed processing system used for big data workloads.

In this demo, a Zeppelin/Spark container uses a Hadoop YARN cluster as a resource management and job scheduling technology to perform distributed data processing.

This Docker image contains Zeppelin and Spark binaries prebuilt and uploaded in Docker Hub.

## Steps to Build Zeppelin/Spark image
```shell
$ git clone https://github.com/mkenjis/apache_binaries
$ wget https://archive.apache.org/dist/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz
$ wget https://downloads.apache.org/zeppelin/zeppelin-0.9.0/zeppelin-0.9.0-bin-netinst.tgz
$ docker image build -t mkenjis/ubzepp_img
$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: mkenjis
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
$ docker image push mkenjis/ubzepp_img
```

## Shell Scripts Inside 

> run_zeppl.sh

Sets up the environment for Zeppelin to get started by executing the following steps :
- sets environment variables for JAVA and ZEPPELIN
- starts the SSH service for passwordless SSH
- starts Zeppelin daemon

## Initial Steps on Docker Swarm

To start with, start Swarm mode in Docker in node1
```shell
$ docker swarm init
Swarm initialized: current node (xv7mhbt8ncn6i9iwhy8ysemik) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token <token> <IP node1>:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

Add more workers in cluster hosts (node2, node3, ...) by joining them to manager.
```shell
$ docker swarm join --token <token> <IP node1>:2377
```

Change the workers as managers in node2, node3, ...
```shell
$ docker node promote node2
$ docker node promote node3
$ docker node promote ...
```

Start Docker stack using docker-compose.yml 
```shell
$ docker stack deploy -c docker-compose.yml yarn
```

Check the status of each service started
```shell
$ docker service ls
ID             NAME           MODE         REPLICAS   IMAGE                                 PORTS
io5i950qp0ac   yarn_hdp1      replicated   0/1        mkenjis/ubhdpclu_img:latest           
npmcnr3ihmb4   yarn_hdp2      replicated   0/1        mkenjis/ubhdpclu_img:latest           
uywev8oekd5h   yarn_hdp3      replicated   0/1        mkenjis/ubhdpclu_img:latest           
p2hkdqh39xd2   yarn_hdpmst    replicated   1/1        mkenjis/ubhdpclu_img:latest           
xf8qop5183mj   yarn_spk_cli   replicated   0/1        mkenjis/ubzepp_img:latest
```

## Steps to Set up Zeppelin/Spark client container

Identify which Docker container started as Hadoop master and logged into it
```shell
$ docker container ls   # run it in each node and check which <container ID> is running the Hadoop master constainer
CONTAINER ID   IMAGE                         COMMAND                  CREATED              STATUS              PORTS      NAMES
a8f16303d872   mkenjis/ubhdpclu_img:latest   "/usr/bin/supervisord"   About a minute ago   Up About a minute   9000/tcp   yarn_hdp2.1.kumbfub0cl20q3jhdyrcep4eb
77fae0c411ce   mkenjis/ubhdpclu_img:latest   "/usr/bin/supervisord"   About a minute ago   Up About a minute   9000/tcp   yarn_hdpmst.1.r81pn190785n1hdktvrnovw86

$ docker container exec -it <container ID> bash
```

Copy the setup_spark_files.sh into Hadoop master container.

Run it to copy the Hadoop conf files into Zeppelin/Spark client container.
```shell
$ vi setup_spark_files.sh
$ chmod u+x setup_spark_files.sh
$ ping spk_cli          
PING spk_cli (10.0.2.11) 56(84) bytes of data.
64 bytes from 10.0.2.11 (10.0.2.11): icmp_seq=1 ttl=64 time=0.163 ms
64 bytes from 10.0.2.11 (10.0.2.11): icmp_seq=2 ttl=64 time=0.116 ms
^C
--- spk_cli ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.116/0.139/0.163/0.023 ms
$ ./setup_spark_files.sh
Warning: Permanently added 'spk_cli,10.0.2.11' (ECDSA) to the list of known hosts.
core-site.xml                                                      100%  137    75.8KB/s   00:00    
hdfs-site.xml                                                      100%  310   263.4KB/s   00:00    
yarn-site.xml                                                      100%  771   701.6KB/s   00:00
```

Identify which Docker container started as Zeppelin/Spark client and logged into it
```shell
$ docker container ls   # run it in each node and check which <container ID> is running the Spark client constainer
CONTAINER ID   IMAGE                                 COMMAND                  CREATED         STATUS         PORTS                                          NAMES
8f0eeca49d0f   mkenjis/ubzepp_img:latest   "/usr/bin/supervisord"   3 minutes ago   Up 3 minutes   4040/tcp, 7077/tcp, 8080-8082/tcp, 10000/tcp   yarn_spk_cli.1.npllgerwuixwnb9odb3z97tuh
e9ceb97de97a   mkenjis/ubhdpclu_img:latest           "/usr/bin/supervisord"   4 minutes ago   Up 4 minutes   9000/tcp                                       yarn_hdp1.1.58koqncyw79aaqhirapg502os

$ docker container exec -it <container ID> bash
```

Add the following parameters to $SPARK_HOME/conf/spark-defaults.conf
```shell
$ vi $SPARK_HOME/conf/spark-defaults.conf
spark.driver.memory  1024m
spark.yarn.am.memory 1024m
spark.executor.memory  1536m
```

Change Zeppelin default binding address to 0.0.0.0 in $ZEPPL_HOME/conf/zeppelin-site.xml
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

Start the Zeppelin service
```shell
$ $ZEPPL_HOME/bin/zeppelin-daemon.sh start
Zeppelin start                                             [  OK  ]
$
```

In the browser, issue the address https://host:8080 to access the Zeppelin Notebook.

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




