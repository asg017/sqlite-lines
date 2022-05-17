#!/bin/bash
cat ../_data/calendar.ndjson |
  ../../dist/sqlite-lines 'count(*)'