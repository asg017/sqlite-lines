#!/bin/bash
set -euo pipefail

SQLITE_LINES=`./sqlite-lines.sh`
if [ "$SQLITE_LINES" != "3104740" ]; then
  echo "❌ failed sqlite-lines"
  exit 1
fi

SQLITE_LINES_CLI=`./sqlite-lines-cli.sh`
if [ "$SQLITE_LINES_CLI" != "3104740" ]; then
  echo "❌ failed sqlite-lines-cli"
  exit 1
fi

DUCK=`./duck.sh`
if [ "$DUCK" != "3104740.0" ]; then
  echo "❌ failed duck"
  exit 1
fi

NDJSON_CLI=`./ndjson-cli.sh`
if [ "$NDJSON_CLI" != "3104740" ]; then
  echo "❌ failed ndjson-cli"
  exit 1
fi

echo "✅ passed"
