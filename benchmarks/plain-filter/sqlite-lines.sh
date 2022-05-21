#!/bin/bash
sqlite3 :memory: \
  '.bail on' '.load ../../dist/lines0' \
  "select count(*)
  from lines_read('/usr/share/dict/words')
  where line like 'sh%'
  "
