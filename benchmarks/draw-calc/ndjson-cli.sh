#/bin/bash
cat /Volumes/Sandisk1/draw/data/simplified/calendar.ndjson | ndjson-reduce 'p + d.drawing.length' '0'