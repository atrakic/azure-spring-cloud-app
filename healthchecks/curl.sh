#!/usr/bin/env bash

set -eo pipefail


curl -o /dev/null -sf -X 'GET' \
  'http://localhost:8080' && echo "OK: $(date +%T)" || exit 1
