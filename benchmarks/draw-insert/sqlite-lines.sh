#!/bin/bash
sqlite3 sqlite-lines.db \
  '.bail on' '.load ../../dist/lines0' \
  "create table drawings as 
  select
    json_extract(line, '$.word') as word,
    json_extract(line, '$.countrycode') as countrycode,
    json_extract(line, '$.timestamp') as timestamp,
    json_extract(line, '$.recognized') as recognized,
    json_extract(line, '$.key_id') as key_id,
    json_extract(line, '$.drawing') as drawing
  from lines_read('../_data/calendar.ndjson')"