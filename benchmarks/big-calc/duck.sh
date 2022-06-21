#!/bin/bash
duckdb :memory: '.mode list' '.header off' \
  "select
    sum(json_array_length(json, '$.coordinates')) as num_strokes
  from read_json_objects('../_data/Brazil.geojsonl')"
