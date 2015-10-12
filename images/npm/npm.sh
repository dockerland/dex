#!/usr/bin/env bash

runline="ba-tools npm $@"

if tty -s; then
    ($runline)
else
    cat - | ($runline)
fi
