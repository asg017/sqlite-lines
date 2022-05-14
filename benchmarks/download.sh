#!/bin/bash
mkdir -p _data
gsutil -m cp -n gs://quickdraw_dataset/full/simplified/calendar.ndjson ./_data
