#!/bin/bash
sqlite3 :memory: \
  '.bail on' '.load ../../dist/lines0' \
  "select
    sum(json_array_length(line, '$.drawing')) as num_strokes
  from lines_read('../_data/calendar.ndjson')"
