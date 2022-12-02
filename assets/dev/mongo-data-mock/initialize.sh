#!/usr/bin/env bash

set -e

cd -- "$( dirname -- "${BASH_SOURCE[0]}" )"

mongod &
MONGOD_PID=$!

mongorestore ./dump/

kill "${MONGOD_PID}"
