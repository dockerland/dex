#!/usr/bin/env bash

runline="ba-tools magerun $@"

if tty -s; then
    ($runline)
else
    cat - | ($runline)
fi
