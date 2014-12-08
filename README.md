# Getting JBoss Data Virtualization to run in the Demo

## What it's all about
This demo has been build to demostration a combination of various Red Hat JBoss products, aimed to have something to demo them and to get an idea on how to achieve an integration.

The scenario covered is the request for a household insurance and is build upon the following services.

(https://raw.githubusercontent.com/PatrickSteiner/BPM_FSW_DV_Docker/master/Documentation/Images/System_Overview.png)

## Prerequisites

### Salesforce.com Demo Account
In this demo we will use JBoss Data Virtualization to

	1. access data from a Postgres database
	2. access data from a Salesforce.com account
	3. join these two to one virtual database

The installer for this demo will take care of the creation of the Postgres database, but in order to work with Salesforce.com you will need your companies account for Salesforce.com or a free-of-charge demo account.


To register for a demo account please do follow the https://www.salesforce.com/form/signup/freetrial-sales.jsp[instructions] from Salesforce. +
As we will be using Salesforce.com via their API, you need to also register for a https://success.salesforce.com/answers?id=90630000000glADAAY[security token].

Details on how to create the correct datarecords will be covered at a later step in this manual.

### Dockerhost
The entire demo is build on https://www.docker.com/[Docker]. The various elements, like JBoss BPM Suite, JBoss Fuse, Postgres and JBoss Data Virtualization all run in their own container.


(https://raw.githubusercontent.com/PatrickSteiner/BPM_FSW_DV_Docker/master/Documentation/Images/Overview.png)

Shows an overview on how these Docker images are build on each other. We will cover the details in the relevant sections later in this manual.

Please do follow the instructions on how to install Docker on your host, based on the https://docs.docker.com/installation/[relevant pages] from Docker.com

### Maven, Ant & JDK
As our installation procedure will build a few jars for you convenience, please do have the appropriate tools up and running on your Docker host.

## Building the Demo Environment

### Getting the code

The procedure to build the various requried Docker container has been automated for your convenience, all you need to do is to clone the most current version of the demo from github
----
git clone https://github.com/PatrickSteiner/BPM_FSW_DV_Docker.git
----

### Customizing the code
JBoss Data Virtualization needs to know your Salesforce.com login and password to be able to retrieve data. To add your credetials to this environment, please open `./HEISE_DV_Image/config/standalone.xml` in your editor of choice and search for the section
----
<resource-adapter id="Salesforce_DS">
	<module id="org.jboss.teiid.resource-adapter.salesforce" slot="main"/>
	<transaction-support>NoTransaction</transaction-support>
	<connection-definitions>
		<connection-definition class-name="org.teiid.resource.adapter.salesforce.SalesForceManagedConnectionFactory" enabled="true" jndi-name="java:/Salesforce_DS" pool-name="Salesforce_DS">
			<config-property name="password">
				[your password+security-token]
            </config-property>
			<config-property name="username">
				[your login]
            </config-property>
		</connection-definition>
	</connection-definitions>
</resource-adapter>
----
Replace `[your password+security-token]` and `[your login]` with your personal data.

### Providing the Red Hat JBoss Products
I have not included the various JBoss products in the git repository, so it will be your obligation to retrieve them and to place them in their directories.

	* `jboss-eap-6.1.1.zip` into `./EAP_Image`
	* `jboss-bpms-6.0.3.GA-redhat-1-deployable-eap6.x.zip` into `./BPM_Image`
	* `jboss-fsw-installer-6.0.0.GA-redhat-4.jar` into `./FSW_Image`
	* `jboss-dv-installer-6.0.0.GA-redhat-4.jar`into `DV_Image/software`
	* `jbdevstudio-product-universal-7.1.1.GA-v20140314-2145-B688.jar` into `DV_JBDS_Image/software`
	* `jbdevstudio-product-universal-7.1.1.GA-v20140314-2145-B688.jar` into `BPM_JBDS_Image/software`


### Building the Docker container

After changing into the `BPM_FSW_DV_Docker` directory, all you need to do is run the provided script, take a cup of coffee ( make it a big one ) and start
----
./demo.sh build all
----

Once the script has finished, you can verify with `docker images` the status of the created container. You should have at least the following entries in your local image repository

----
[psteiner@localhost BPM_FSW_DV_Docker]$ docker images
REPOSITORY                TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
psteiner/bpm_jbds         latest              472eb4d21693        5 minutes ago       3.07 GB
psteiner/dv_jbds          latest              a77ef429eb2a        10 minutes ago      2.148 GB
psteiner/heise_datavirt   latest              c813de973667        14 minutes ago      1.075 GB
psteiner/heise_fsw        latest              a2d613de584f        15 minutes ago      1.813 GB
psteiner/heise_bpm        latest              ace41f79378c        17 minutes ago      1.916 GB
psteiner/datavirt         latest              e4649011004b        18 minutes ago      1.072 GB
psteiner/fsw              latest              f34ea54366bd        22 minutes ago      1.807 GB
psteiner/bpm              latest              f04c90fd3de9        25 minutes ago      1.396 GB
psteiner/eap              latest              6cdbce7d918d        27 minutes ago      705.1 MB
psteiner/postgres         latest              be9d80a000b1        About an hour ago   415.6 MB
centos                    centos6             70441cac1ed5        4 weeks ago         215.8 MB
----

## Starting the environment

Once you have completed the previous step, you can run the demo in your own environment. Simply use `./demo.sh start all` to start all images with the required parameter and configurations.

When completed, the script will have started container for JBoss BPM Suite, JBoss Fuse Service Works, JBoss Data Virtualization and a Postgress.

If you want to verify the start, you can do so with `docker ps`. It should show something like

----
CONTAINER ID        IMAGE                            COMMAND                CREATED             STATUS              PORTS                                                                                               NAMES
3dc317c9b1ed        psteiner/heise_bpm:latest        "\"/bin/sh -c 'su jb   4 seconds ago       Up 3 seconds        22/tcp, 0.0.0.0:49160->8080/tcp, 0.0.0.0:49170->9990/tcp                                            loving_heisenberg
6c8d9dfdd0fb        psteiner/heise_datavirt:latest   "/bin/sh -c /home/jb   5 seconds ago       Up 4 seconds        9999/tcp, 22/tcp, 27017/tcp, 3306/tcp, 5432/tcp, 0.0.0.0:49200->8080/tcp, 0.0.0.0:49210->9990/tcp   datavirt
4ee71b4cca5c        psteiner/postgres:latest         "/bin/sh -c $HOME/po   5 seconds ago       Up 4 seconds        0.0.0.0:49165->5432/tcp, 0.0.0.0:49166->80/tcp                                                      postgres
d889dd7ae152        psteiner/heise_fsw:latest        "/bin/sh -c '$HOME/f   6 seconds ago       Up 5 seconds        22/tcp, 0.0.0.0:49220->8080/tcp, 0.0.0.0:49230->9990/tcp                                            fsw
----

Due to the way the demo is started, you can access all relevant web frontends via `localhost`.

[cols="3*", options="header"]
|===
|Product
|Console
|URL

|JBoss BPM Suite
|Business Central
|http://http://localhost:49160/business-central

|JBoss BPM Suite
|Admin Console
|http://localhost:49170/console/index.html

|JBoss Data Virtualization
|Admin Console
|http://localhost:49210/console/index.html
|===

For authentication please use the following user-id and password for all places where you need to authenticate

[cols="2*", options="header"]
|===
|User-ID
|Password

|psteiner
|change12_me
|===

## What's in the box
Overall this demo is about a fictional request for a new household insurance. As in reality this process is not a single step, but consists of various tasks which need to be done in a certain order. In our case

 1. request the data for the object that needs insurance
 2. calculate a insurance policy, based on a few rules
 3. ask applicant to accept the calculated policy
 4. check if this applicant is already known to us
 5. ask for his address if he is unknown
 6. document everthing for later dashboarding ( Business Activity Monitoring )

To implement these tasks, the demo makes use of various products and feature of the JBoss product family.

### Process Management
The steps described above are orchestrated via the process management capabilities of JBoss BPM Suite.

(https://raw.githubusercontent.com/PatrickSteiner/BPM_FSW_DV_Docker/master/Documentation/Images/process_model.png)

### Rules Management
The steps __Calculate tariff__ and __Calculate max/min__ in above process model, are implemented via the Rules Management part of the JBoss BPM Suite. With the aid of rules management, it is possible to

 * break many complex rules into small pieces
 * make the rules readable and manageable for business people

(https://raw.githubusercontent.com/PatrickSteiner/BPM_FSW_DV_Docker/master/Documentation/Images/rules.png)

### Data Virtualization
As in many real business, our demo lacks a central point of information for customer data - well, ok - in the case of the demo, this was intentional ...

In our case we have two distinct datasources, a Postgress Database and a table from Salesforce.com, which we access via the remote.

For simplicity reasons, the Postgres database only consists of two fields which hold the name of a customer and one for the rather complex Salesforce-ID.

(https://raw.githubusercontent.com/PatrickSteiner/BPM_FSW_DV_Docker/master/Documentation/Images/postgres_db.png)

Salesforce has a very large dataset for contacts, which we do make use of.

(https://raw.githubusercontent.com/PatrickSteiner/BPM_FSW_DV_Docker/master/Documentation/Images/salesforce_db.png)

JBoss Data Virtualization does join these two datasources, which are based on different technologies and different server and presents it to the business process as one __virtual database__

(https://raw.githubusercontent.com/PatrickSteiner/BPM_FSW_DV_Docker/master/Documentation/Images/vdb.png)

### Business Activity Monitoring
For many users of process management systems, it is of high importance to be able to see what has happened. In our case this would be monitoring things like

 * how many contracts have been signed
 * how much money did we earny
 * which contracts sold how good/bad
 * ...

(https://raw.githubusercontent.com/PatrickSteiner/BPM_FSW_DV_Docker/master/Documentation/Images/bam.png)

### How it's been done

tbd

## Creating the VDB - Virtual Database

tbd

## Creating a WebService

tbd

## How to add it all to the demo

tbd
