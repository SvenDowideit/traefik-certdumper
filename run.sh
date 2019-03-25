#!/bin/sh
set -e

###
# log()
#
function log() {
    echo "[$(date)] $@"
}

log "Starting dumper into $CERTDUMPER_MODE mode"

if [ $CERTDUMPER_MODE == "consul" ]; then
    exec /run_consul.sh
else
    exec /run_default.sh
fi
