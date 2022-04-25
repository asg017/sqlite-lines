#!/bin/bash
python3 -c '
import json

count = 1
with open("/Volumes/Sandisk1/draw/data/simplified/calendar.ndjson") as f:
  for line in f:
    count += len(json.loads(line).get("drawing"))
print(count)
'
