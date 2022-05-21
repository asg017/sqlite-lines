#!/bin/bash
sqlite3 :memory: \
  '.bail on' '.load ../../dist/lines0' \
  "select
    sum(json_array_length(line, '$.coordinates'))
  from lines_read('../_data/Brazil.geojsonl')"
