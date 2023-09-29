#!/bin/bash

cd $(dirname $0)

docker compose cp ../splunk_forward_to_kafka/local/outputs.conf splunk_hf:/opt/splunk/etc/system/local/outputs.conf
docker compose cp ../splunk_forward_to_kafka/local/props.conf splunk_hf:/opt/splunk/etc/system/local/props.conf
docker compose cp ../splunk_forward_to_kafka/local/transforms.conf splunk_hf:/opt/splunk/etc/system/local/transforms.conf
docker compose exec -T -u root splunk_hf chown splunk:splunk /opt/splunk/etc/system/local/outputs.conf
docker compose exec -T -u root splunk_hf chown splunk:splunk /opt/splunk/etc/system/local/props.conf
docker compose exec -T -u root splunk_hf chown splunk:splunk /opt/splunk/etc/system/local/transforms.conf
docker compose exec -T -u splunk splunk_hf /opt/splunk/bin/splunk enable app SplunkForwarder
docker compose exec -T -u splunk splunk_hf /opt/splunk/bin/splunk restart
