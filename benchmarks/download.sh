#!/bin/bash
mkdir -p _data
gsutil -m cp -n gs://quickdraw_dataset/full/simplified/calendar.ndjson ./_data
wget -O _data/Brazil.geojsonl.zip https://minedbuildings.blob.core.windows.net/southamerica/Brazil.geojsonl.zip
unzip _data/Brazil.geojsonl.zip
