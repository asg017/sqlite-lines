#!/bin/bash
sqlite3x :memory: \
  '.bail on' '.load ../../dist/lines0' \
  "select
    count(*)
  from lines_read('../_data/calendar.ndjson')"