# Creating Solr Cloud Server with a classic schema mode (for a Korean Postal Address service)

- Download Korean Postal Address Data from https://www.epost.go.kr/search/zipcode/areacdAddressDown.jsp
- Download Apache Solr from https://solr.apache.org/downloads.html
- Unzip the downloaded Solr and move to the home directory.
- I am creating two Solr cloud instances on the following two directories:
```text
./server/solr/cloud/node1/solr 
./server/solr/cloud/node2/solr
```

- Therefore, create necessary directories. (server/solr already exists)
```text
mkdir server/solr/cloud
mkdir server/solr/cloud/node1
mkdir server/solr/cloud/node1/solr

mkdir server/solr/cloud/node2
mkdir server/solr/cloud/node2/solr
```
- Open a bin/solr file and find this block of script
```text
if [ "${SOLR_HOME:0:${#EXAMPLE_DIR}}" = "$EXAMPLE_DIR" ]; then
  LOG4J_PROPS="$DEFAULT_SERVER_DIR/resources/log4j2.xml"
  SOLR_LOGS_DIR="$SOLR_HOME/../logs"
fi
```
- Since I will run two instances on a same server, commenting out the 'if' statement will create separate logs per an instance.
```text
# if [ "${SOLR_HOME:0:${#EXAMPLE_DIR}}" = "$EXAMPLE_DIR" ]; then
  LOG4J_PROPS="$DEFAULT_SERVER_DIR/resources/log4j2.xml"
  SOLR_LOGS_DIR="$SOLR_HOME/../logs"
# fi
```
- (Optional) May change ```verbose=false``` to ```verbose=true``` in the bin/solr file.
- Start two solr cloud servers on the directories created above.
```text
bin/solr start -cloud -p 8983 -s server/solr/cloud/node1/solr
bin/solr start -cloud -p 8984 -s server/solr/cloud/node2/solr -z 127.0.0.1:9983
```
- Create a Solr cloud collection named 'address' with two shards and two replicas
```text
bin/solr create_collection -c address -shards 2 -replicationFactor 2
```

- Download zookeeper configuration files (to a zk-config-down directory)
```text
bin/solr zk downconfig -z localhost:9983 -n address -d ./zk-config-down
```

- Delete a managed-schema file on the zookeeper
```text
bin/solr zk rm /configs/address/managed-schema.xml -z localhost:9983
```

- Now modify configuration files downloaded from the zookeeper. Open the solrconfig.xml in the ./zk-config-down directory.  Then add this 'ClassicIndexSchemaFactory' to set the usage of a schema mode.
```text
<schemaFactory class="ClassicIndexSchemaFactory"/>  
```
- In the same file, we see this.  
```text
<!-- The update.autoCreateFields property can be turned to false to disable schemaless mode -->
  <updateRequestProcessorChain name="add-unknown-fields-to-the-schema" default="${update.autoCreateFields:true}"
           processor="uuid,remove-blank,field-name-mutating,parse-boolean,parse-long,parse-double,parse-date,add-schema-fields">
    <processor class="solr.LogUpdateProcessorFactory"/>
    <processor class="solr.DistributedUpdateProcessorFactory"/>
    <processor class="solr.RunUpdateProcessorFactory"/>
  </updateRequestProcessorChain>
```
as indicated, change to ```default="${update.autoCreateFields:false}```

- To assign/update a unique field automatically, we may need to add this element.
```text
<updateRequestProcessorChain>
	<processor class="solr.UUIDUpdateProcessorFactory">
		<str name="fieldName">id</str>
	</processor>
	<processor class="solr.LogUpdateProcessorFactory" />
	<processor class="solr.RunUpdateProcessorFactory" />
</updateRequestProcessorChain>
```
- **NOW create a file 'schema' in the zk-config-down directory. (or rename managed-schema to schema and define fields based on your need)**


- Upload changed/updated config files to the zookeeper
```text
bin/solr zk cp -r file:zk-config-down/conf zk:/configs/address -z 121.0.0.1:9983
```

- Restart solr servers
```text
bin/solr restart -c -p 8983 -s server/solr/cloud/node1/solr

bin/solr restart -c -p 8984 -z localhost:9983 -s server/solr/cloud/node2/solr 
```

For more configuration info: https://solr.apache.org/guide/solr/latest/deployment-guide/solr-control-script-reference.html
