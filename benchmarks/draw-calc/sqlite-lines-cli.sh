#!/bin/bash
cat /Volumes/Sandisk1/draw/data/simplified/calendar.ndjson |
  ../../dist/sqlite-lines 'sum(json_array_length(d, "$.drawing"))'