Streaming data from Splunk to Kafka using KSQLDB for filtering, while keeping all the Splunk MetaData (source,sourcetype,host,event) <jmirza@confluent.io>
v1.00, 3 November 2020

TL;DR
```
QuickStart
1. git clone https://github.com/JohnnyMirza/splunk_forward_to_kafka.git
2. docker-compose up -d
3. Configure Splunk UF’s to send to the above instance
```

![image](splunk_forward_to_kafka.png)

This app is a set custom inputs/transforms that allows you to send "under-cooked" data to apache kafka. Spin up using Docker-Compose and just forward your UFs to the instance.


### Getting started

1. Bring the Docker Compose up

```
docker-compose up -d
```

2. Make sure everything is up and running

```
#docker-compose ps
```
```     Name                    Command                  State                    Ports
broker            /etc/confluent/docker/run        Up             0.0.0.0:9092->9092/tcp
control-center    /etc/confluent/docker/run        Up             0.0.0.0:9021->9021/tcp
elasticsearch     /tini -- /usr/local/bin/do ...   Up             0.0.0.0:9200->9200/tcp, 9300/tcp
kafka-connect     bash -c echo "Installing c ...   Up (healthy)   0.0.0.0:5555->5555/tcp, 0.0.0.0:8083->8083/tcp, 9092/tcp
kibana            /usr/local/bin/dumb-init - ...   Up             0.0.0.0:5601->5601/tcp
ksqldb            /etc/confluent/docker/run        Up             0.0.0.0:8088->8088/tcp
schema-registry   /etc/confluent/docker/run        Up             0.0.0.0:8081->8081/tcp
splunk_hf         /sbin/entrypoint.sh start- ...   Up (healthy)   0.0.0.0:8001->8000/tcp, 8065/tcp, 8088/tcp, 8089/tcp,
                                                                  8191/tcp, 9887/tcp, 0.0.0.0:9997->9997/tcp
splunk_search     /sbin/entrypoint.sh start- ...   Up (healthy)   0.0.0.0:8000->8000/tcp, 8065/tcp, 8088/tcp, 8089/tcp,
                                                                  8191/tcp, 9887/tcp, 0.0.0.0:9998->9997/tcp
zookeeper         /etc/confluent/docker/run        Up             2181/tcp, 2888/tcp, 3888/tcp
```

**Note:** The `splunk_hf` container runs an Ansible playbook on startup to install Splunk. This will take a couple of minutes to complete before the Heavy Forwarder is ready for subsequent steps. Wait for `splunk_hf` to be in the `Up (healthy)` state before proceeding.

3. Run the `configure_splunk_hf.sh` script to finish configuring the Heavy Forwarder:

```
bash scripts/configure_splunk_hf.sh
```

4. Deploy the syslog source connector to Kafka Connect:

```
bash scripts/submit_syslog_splunk.sh
```

### Create ksqlDB stream processing queries

Open Confluent Control Center by going to http://localhost:9021 and go to the ksqlDB Editor to run the below KSQL commands.

1. Run the KSQL commands in `statements.sql` to create Splunk Streams to extract the undercooked data & transform it into cooked data we can send to a Splunk receiver/indexer.

2. Stream the data to Splunk with Kafka Connect.

```
bash scripts/submit_splunk_sink.sh
```

**NOTE:** I haven't been able to make this work successfully with the `splunk_search` container in this repo. Getting the following error after setting `allowRemoteLogin = always` in `server.conf`:
```
{"error_code":500,"message":"Bad splunk configurations with status code:401 response:<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<response>\n  <messages>\n    <msg type=\"WARN\">call not properly authenticated</msg>\n  </messages>\n</response>\n"}
```

### Send some logs!

For this demo, we'll assume you're on MacOS, and do NOT already have a Splunk Universal Forwarder deployed locally by your company's IT department.

1. Install the Splunk Universal Forwarder.

2. Configure your Splunk UF's (outputs.conf) to send data to the HF in this docker-compose instance (`localhost:9997`).

3. Set the UF to begin monitoring `/var/log`

```
splunk add monitor /var/log
```

You should soon see data flowing through the Kafka topics / ksqlDB streams.

**Confluent KSQLDB Flow**
![image](Ksqldb.png)

5. Visualise your data in splunk or Elasticsearch
- Splunk - http://localhost:8000. (admin/Password1)

### Notes

- In this instance the props.conf is configured to forward all events from a specific host (my local machine) to Kafka. To instead filter by specific sources/sourcetypes, edit `props.conf` on the HF ([Splunk docs](https://docs.splunk.com/Documentation/Splunk/9.1.1/Forwarding/Routeandfilterdatad)).

- For Multiline events use the below SEDCMD in the required sourcetype stanza to replace `\n\r`` with a tab:
```
SEDCMD-LF = s/(?ims)\n/ /g
SEDCMD-CR = s/(?ims)\r/ /g
```
