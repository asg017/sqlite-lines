#!/bin/bash
cat '/usr/share/dict/words' | ../../dist/sqlite-lines 'count(*)' 'd like "sh%"'