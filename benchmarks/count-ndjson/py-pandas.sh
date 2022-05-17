#!/bin/bash
python3 -c '
import pandas as pd

df = pd.read_json("../_data/calendar.ndjson", lines=True)

print(len(df.index))
'
