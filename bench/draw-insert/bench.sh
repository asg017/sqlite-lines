#!/bin/bash
hyperfine \
  --prepare 'rm sqlite-lines.db' './sqlite-lines.sh'\
  --prepare 'rm sqlite-utils.db' './sqlite-utils.sh'