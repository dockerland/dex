#!/usr/bin/env bash

runline="ba-tools ag $@"

if tty -s; then
    ($runline)
else
    cat - | ($runline)
fi
