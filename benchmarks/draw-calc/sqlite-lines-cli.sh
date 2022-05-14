#!/bin/bash
cat ../_data/calendar.ndjson |
  ../../dist/sqlite-lines 'sum(json_array_length(d, "$.drawing"))'