#!/bin/bash
sqlite-utils memory \
  /Volumes/Sandisk1/draw/data/simplified/calendar.ndjson:nl \
  'select sum(json_array_length(drawing)) as num_strokes from calendar' \
| jq '.[0].num_strokes'

#'select * from calendar limit 1'