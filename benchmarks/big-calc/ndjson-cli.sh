#/bin/bash
cat ../_data/Brazil.geojsonl | ndjson-reduce 'p + d.coordinates.length' '0'