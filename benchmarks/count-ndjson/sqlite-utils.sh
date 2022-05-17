#!/bin/bash
sqlite-utils memory \
  ../_data/calendar.ndjson:nl \
  'select count(*) from calendar'

#'select * from calendar limit 1'