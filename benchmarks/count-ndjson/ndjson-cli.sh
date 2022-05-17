#/bin/bash
cat ../_data/calendar.ndjson | ndjson-reduce 'p + 1' '0'