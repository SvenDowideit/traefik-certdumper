#!/bin/sh
set -e

if [ $CERTDUMPER_MODE == "consul" ]; then
    exec /run_consul.sh
else
    exec /run_default.sh
fi
