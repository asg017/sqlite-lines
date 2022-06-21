#!/bin/bash
duckdb duck.db \
  "create table drawings as 
  select
    json_extract_string(json, '$.word') as word,
    json_extract_string(json, '$.countrycode') as countrycode,
    json_extract_string(json, '$.timestamp') as timestamp,
    json_extract_string(json, '$.recognized') as recognized,
    json_extract_string(json, '$.key_id') as key_id,
    json_extract_string(json, '$.drawing') as drawing
  from read_json_objects('../_data/calendar.ndjson')"

