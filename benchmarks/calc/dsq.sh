#!/bin/bash
dsq ../_data/calendar.ndjson 'select sum(json_array_length(drawing)) as total from {}'