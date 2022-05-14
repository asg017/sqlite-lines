#!/bin/bash
python3 -c '
import json

count = 0
with open("../_data/calendar.ndjson") as f:
  for line in f:
    count += len(json.loads(line).get("drawing"))
print(count)
'
