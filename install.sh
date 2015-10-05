#!/bin/sh

log ":: INSTALLING BLUEACORN DOCKER TOOLS"


# install all scripts (ending in *.sh) from this directory

for script in $(find $MY_DIR -type f -name "*.sh") ; do

  scriptname=$(basename "$script")

  if [ ! "$scriptname" = "install.sh" ] && [ ! "$scriptname" = "run.sh" ] && [ ! -L "$BIN_DIR/$scriptname" ]; then

    if [ -f $BIN_DIR/$scriptname ]; then
      current_time=$(date "+%Y.%m.%d-%H.%M.%S")
      echo "archiving $scriptname as ${scriptname}.$current_time"
      mv $BIN_DIR/$scriptname $BIN_DIR/${scriptname}.$current_time
    fi

    echo "linking $scriptname as ${scriptname::${#string}-3}..."
    chmod +x $script && ln -s $script $BIN_DIR/${scriptname::${#string}-3}
  fi
done

echo "complete"
