#!/bin/bash
sqlite3x :memory: \
  '.bail on' '.load ../../dist/lines' \
  "select
    sum(json_array_length(contents, '$.drawing')) as num_strokes
  from lines_read('../_data/calendar.ndjson')"