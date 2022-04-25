#!/bin/bash
sqlite3x sqlite-lines.db \
  '.bail on' '.load ../../dist/lines' \
  "create table drawings as 
  select
    contents ->> '$.word' as word,
    contents ->> '$.countrycode' as countrycode,
    contents ->> '$.timestamp' as timestamp,
    contents ->> '$.recognized' as recognized,
    contents ->> '$.key_id' as key_id,
    contents ->> '$.drawing' as drawing
  from lines_read('/Volumes/Sandisk1/draw/data/simplified/calendar.ndjson')"