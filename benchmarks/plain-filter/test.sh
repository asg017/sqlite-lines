#!/bin/bash

set -euo pipefail

SQLITE_LINES=`./sqlite-lines.sh`
UNIX=`./unix.sh`

if [ "$SQLITE_LINES" != "1478" ]; then
  echo "❌ failed sqlite-lines"
  exit 1
fi

if [ "$UNIX" != "    1478" ]; then
  echo "❌ failed unix"
  exit 1
fi

echo "✅ passed"