#/bin/bash
cat ../_data/calendar.ndjson | ndjson-reduce 'p + d.drawing.length' '0'