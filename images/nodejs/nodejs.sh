#!/usr/bin/env bash

runline="ba-tools nodejs $@"

if tty -s; then
    ($runline)
else
    cat - | ($runline)
fi
