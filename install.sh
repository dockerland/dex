#!/bin/sh

log ":: INSTALLING BLUEACORN DOCKER TOOLS"


scriptname="ba-tools.sh"

if [ ! -L "$BIN_DIR/$scriptname" ]; then

    if [ -f $BIN_DIR/$scriptname ]; then
	current_time=$(date "+%Y.%m.%d-%H.%M.%S")
	echo "archiving $scriptname as ${scriptname}.$current_time"
	mv $BIN_DIR/$scriptname $BIN_DIR/${scriptname}.$current_time
    fi

    echo "linking $scriptname as ${scriptname::${#string}-3}..."
    ln -s ${MY_DIR}/$scriptname $BIN_DIR/${scriptname::${#string}-3}
fi

ba-tools install gitk

echo "complete"
