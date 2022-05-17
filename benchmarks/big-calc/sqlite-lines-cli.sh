#!/bin/bash
cat ../_data/Brazil.geojsonl |
  ../../dist/sqlite-lines 'sum(json_array_length(d, "$.coordinates"))'