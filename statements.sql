/*
  Declare a stream over the raw input topic.
*/
CREATE STREAM SPLUNK (
    rawMessage VARCHAR
  ) WITH (
    KAFKA_TOPIC='splunk-syslog-tcp',
    VALUE_FORMAT='JSON'
  );

/*
  Explode the rawMessage to yield discrete metadata & event fields.
*/
CREATE STREAM SPLUNK_META AS
SELECT SPLIT_TO_MAP(rawMessage, '||', '=') PAYLOAD
FROM SPLUNK
EMIT CHANGES;

/*
  Add the necessary metadata fields to yield the "cooked" data
  expected by the Splunk indexer.
*/
CREATE STREAM TOHECWITHSPLUNK AS SELECT
  SPLUNK_META.PAYLOAD['sourcetype'] `sourcetype`,
  SPLUNK_META.PAYLOAD['source'] `source`,
  SPLUNK_META.PAYLOAD['time'] `time`,
  SPLUNK_META.PAYLOAD['event'] `event`,
  SPLUNK_META.PAYLOAD['host'] `host`
FROM SPLUNK_META SPLUNK_META
EMIT CHANGES;

/*
  Create a filtered stream containing only log events
  from the launchd service, excluding "Notice" level messages.
*/
CREATE STREAM LAUNCHD_NO_NOTICE AS
SELECT *
FROM TOHECWITHSPLUNK
WHERE `sourcetype` = 'launchd'
AND `event` NOT LIKE '%<Notice>%'
;
