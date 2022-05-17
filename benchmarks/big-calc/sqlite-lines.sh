#!/bin/bash
sqlite3x :memory: \
  '.bail on' '.load ../../dist/lines0' \
  "select
    sum(json_array_length(contents, '$.coordinates'))
  from lines_read('../_data/Brazil.geojsonl')"