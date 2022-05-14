#!/bin/bash
sqlite3x :memory: \
  '.bail on' '.load ../../dist/lines' \
  "select count(*)
  from lines_read('/usr/share/dict/words')
  where contents like 'sh%'
  "