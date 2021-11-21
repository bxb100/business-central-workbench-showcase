Business-Central Showcase Docker image
============================================

Build for ARM version
Everything is copy from <https://github.com/jboss-dockerfiles/business-central>

docker version descripe:
> baseOn:
>
> * base: CentOS 7
> * base-jdk: openJDK11
> * wildfly: 23.0.2.Final
> * drools-workbench: 7.61.0.Final

---

* Introduction
* Usage
* Users and roles
* Logging
* GIT internal repository access
* Persistent configuration
* Experimenting
* Troubleshooting
* Notes
* Release notes

Introduction
------------

The image contains:

* JBoss Wildfly 23.0.2.Final
* KIE Business-Central Workbench 7.61.0.Final

This image inherits from `bxb100/business-central-workbench:latest` and provides some additional configurations:

* Default users and roles
* Some examples

This is a **ready to run Docker image for JBoss Business-Central Workbench**. Just run it and try the JBoss Business-Central Workbench!

Usage
-----

To run a container:

    docker run -p 8080:8080 -p 8001:8001 -d --name jbpm-workbench bxb100/business-central-workbench-showcase:latest

Once container and web applications started, you can navigate to it using one of the users described in section `Users and roles`, using the following URL:

        http://localhost:8080/business-central

Users and roles
----------------

This showcase image contains default users and roles:

    USER        PASSWORD    ROLE
    *************************************************
    admin       admin       admin,analyst,kiemgmt
    krisv       krisv       admin,analyst
    john        john        analyst,Accounting,PM
    sales-rep   sales-rep   analyst,sales
    katy        katy        analyst,HR
    jack        jack        analyst,IT

Logging
-------

You can see all logs generated by the `standalone` binary running:

    docker logs [-f] <container_id>

You can attach the container by running:

    docker attach <container_id>

The JBoss Business-Central Workbench web application logs can be found inside the container at path:

    /opt/jboss/wildfly/standalone/log/server.log
    
    Example:
    sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $(docker ps -lq)) -m -u -i -n -p -w
    -bash-4.2# tail -f /opt/jboss/wildfly/standalone/log/server.log

GIT internal repository access
------------------------------

The workbench stores all the project artifacts in an internal GIT repository. By default, the protocol available for accessing the GIT repository is `SSH` at port `8001`.

As an example, if you import the `IT_Orders` sample project, you can clone it by running:

    git clone ssh://admin@localhost:8001/MySpace/IT_Orders

By default, the GIT repository is created when the application starts for first time at `$WORKING_DIR/.niogit`, considering `$WORKING_DIR` as the current directory where the application server is started.

You can specify a custom repository location by setting the following Java system property to your target file system directory:

        -Dorg.uberfire.nio.git.dir=/home/youruser/some/path

NOTE: This directory can be shared with your docker host and with another containers using shared volumes when running the container, if you need so.

If necessary you can make GIT repositories available from outside localhost using the following Java system property:

        -org.uberfire.nio.git.ssh.host=0.0.0.0

You can set this Java system properties permanent by adding the following lines in your `standalone-full.xml` file as:

        <system-properties>
          <!-- Custom repository location. -->
          <property name="org.uberfire.nio.git.dir" value="/home/youruser/some/path"/>
          <!-- Make GIT repositories available from outside localhost. -->
          <property name="org.uberfire.nio.git.ssh.host" value="0.0.0.0"/>
        </system-properties>

NOTE: Users and password for ssh access are the same that for the web application users defined at the realm files.

Persistent configuration
------------------------

As Docker defaults, once a container has been removed, the data within that container is removed as well.

At first glance this should not imply any issues as the assets authored on your workbench containers are not lost if you don't remove the container, you can stop and restart it
as many times as you need, and have different kie execution server container's consuming those assets, the problem comes if you need to remove and create new workbench containers.

In the case you need to create a persistent environment you can use an approach based on [Docker Volumes](https://docs.docker.com/engine/tutorials/dockervolumes/). Here are two ways of doing it.

**Using default GIT root directory**

By default, the internal GIT root directory for the workbench container is located at `/opt/jboss/wildfly/bin/.niogit`, so you can make this directory persistent in your docker host by running the container using a docker shared volume as:

    # Use -v <SOURCE_FS_PATH>:<CONTAINER_FS_PATH>
    docker run -p 8080:8080 -p 8001:8001 -v /home/myuser/wb_git:/opt/jboss/wildfly/bin/.niogit:Z -d --name jbpm-workbench bxb100/jbpm-workbench-showcase:latest

Please create `/home/myuser/wb_git` before running the docker container and ensure you have set the right permissions.
As the above command, now your workbench git repository will be persistent at your host filesystem's path `/home/myuser/wb_git`. So if you remove this container and start a new one just by using same shared volume, you'll find all your assets on the new workbench's container as well.

**Using custom GIT root directory**

Considering this showcase module as the base for this example, follow the next steps:

1.- Edit the [jbpm-custom.cli](./etc/jbpm-custom.cli) and uncomment the default GIT repository location for your favourite one:

    # Make GIT repositories root directory at /opt/jboss/wildfly/mygit.
    # if (outcome != success) of /system-property=org.uberfire.nio.git.dir:read-resource
    # /system-property=org.uberfire.nio.git.dir:add(value="/opt/jboss/wildfly/mygit")
    # else
    #     /system-property=org.uberfire.nio.git.dir:write-attribute(name=value,value="/opt/jboss/wildfly/mygit")
    # end-if

2.- Edit the [Dockerfile](./Dockerfile) and add these lines:

    USER root
    RUN mkdir -p $JBOSS_HOME/mygit
    RUN chown jboss:jboss $JBOSS_HOME/mygit
    USER jboss

3.- Create your Docker image:

    docker build --rm -t quay.io/kiegroup/business-central-workbench-showcase:MY_TAG

At this point, the default GIT root directory for the workbench will be located inside the Docker container at `/opt/jboss/wildfly/mygit/`. So all your assets will be stored in the underlying git structure on this path.

In order to keep the git repositories between different containers you can just start the container by configuring a new host volume as:

    # Use -v <SOURCE_FS_PATH>:<CONTAINER_FS_PATH>
    docker run -p 8080:8080 -p 8001:8001 -v /home/myuser/wb_git:/opt/jboss/wildfly/mygit:Z -d --name business-central-workbench quay.io/kiegroup/business-central-workbench-showcase:MY_TAG

As the above command, now your workbench git repository will be persistent at your local filesystem path `/home/myuser/wb_git`. So if you remove this container and start a new one just by using same shared volume, you'll find all your assets on the new workbench's container as well.

Experimenting
-------------

To spin up a shell in one of the containers try:

    docker run -t -i -p 8080:8080 -p 8001:8001 quay.io/kiegroup/business-central-workbench-showcase:latest /bin/bash

You can then noodle around the container and run stuff & look at files etc.

Troubleshooting
---------------

If the application can't be accessed via browser (http://localhost:8080/business-central) please run the container in [host network mode](https://docs.docker.com/engine/reference/run/#network-settings). It seems that latest docker versions have some restrictions on the networking side. Using an older daemon version this does not happen.
Try:

    docker run ... --network="host" ...

Notes
-----

* The context path for KIE Business-Central Workbench web application is `business-central`
* KIE Business-Central Workbench version is `7.61.0.Final`
* Examples and demos are always available, also when not connected to internet
* No support for clustering
* Use of embedded H2 database server by default
* No support for Wildfly domain mode, just standalone mode
* This image is not intended to be run on cloud environments such as RedHat OpenShift or Amazon EC2, as it does not meet all the requirements.
* Please give us your feedback or report a issue at [jBPM Setup](https://groups.google.com/forum/#!forum/jbpm-setup) or [jBPM Usage](https://groups.google.com/forum/#!forum/jbpm-usage) Google groups.
* WildFly was upgraded to version 23.0.2.Final

Release notes
--------------

**7.61.0.Final**

* See release notes for [Business-Central](http://docs.jboss.org/jbpm/release/7.61.0.Final/jbpm-docs/html_single/#_jbpmreleasenotes)
