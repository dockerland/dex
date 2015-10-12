#!/usr/bin/env bash

BLUEACORN_DIR=${BLUEACORN_DIR:-/etc/blueacorn}
BIN_DIR="$BLUEACORN_DIR/bin"

GENERAL_DOCKER_RUN_FLAGS="--rm"
FORCE_BUILD=false

DOCKER_BUILD_FLAGS="--rm -q --pull"

# This won't work with symlinks might need to revisit
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

normalize_image_name(){
    local DOCKER_NAME=${1,,}
    DOCKER_NAME="${DOCKER_NAME}_batool"
    DOCKER_NAME=${DOCKER_NAME//-/_}
    DOCKER_NAME=${DOCKER_NAME// /_}
    DOCKER_NAME=${DOCKER_NAME//[^a-z0-9_]/}

    echo $DOCKER_NAME
}

clean() {
    local DOCKER_IMAGE_NAME=$(normalize_image_name $1)

    # Removing containers
    for containerid in $(docker ps -a | grep $DOCKER_IMAGE_NAME | cut -f 1 --delimiter=" ") ; do
        docker rm -v $containerid
    done

    # Removing image
    docker rmi -f $(docker images -q $DOCKER_IMAGE_NAME)
}

build_image() {
    local EXECNAME=$1
    local DOCKER_IMAGE_NAME=$(normalize_image_name $EXECNAME)
    local DOCKER_BUILD_DIR="${SCRIPT_DIR}/images/${EXECNAME}/."

    echo "Building image for $EXECNAME"
    docker build $DOCKER_BUILD_FLAGS -t $DOCKER_IMAGE_NAME $DOCKER_BUILD_DIR
}

info(){
    local EXECNAME=$1
    local DOCKER_IMAGE_NAME=$(normalize_image_name $EXECNAME)
    local DOCKER_BUILD_DIR="${SCRIPT_DIR}/images/${EXECNAME}/"

    local FROM_IMAGE=$(cat ${DOCKER_BUILD_DIR}Dockerfile | grep FROM | cut -f 2 -d " ")
    local WORKDIR=$(cat ${DOCKER_BUILD_DIR}Dockerfile | grep WORKDIR | cut -f 2 -d " ")

    echo "Info for '$EXECNAME'"
    echo "Image: $DOCKER_IMAGE_NAME"
    echo "From: $FROM_IMAGE"
}

list(){
    for EXECNAME in $(find ${SCRIPT_DIR}/images -maxdepth 1 -mindepth 1 -type d -printf "%f ") ; do
	echo $EXECNAME
    done
}

install(){
    for EXECNAME in $@ ; do
	local SCRIPTNAME="${EXECNAME}.sh"
	local INSTALLNAME=$EXECNAME
	local SCRIPT=${SCRIPT_DIR}/images/${EXECNAME}/${SCRIPTNAME}
	read_image_env

	build_image $EXECNAME

	# Unlink existing symlink
	if [ -L $BIN_DIR/$INSTALLNAME ]; then
    	    echo "Unlinking old $INSTALLNAME"
    	    unlink $BIN_DIR/$INSTALLNAME
	fi

	# Archive existing file
	if [ -f $BIN_DIR/$INSTALLNAME ]; then
    	    current_time=$(date "+%Y.%m.%d-%H.%M.%S")
    	    echo "Archiving $INSTALLNAME as ${INSTALLNAME}.$current_time"
    	    mv $BIN_DIR/$INSTALLNAME $BIN_DIR/${INSTALLNAME}.$current_time
	fi

	# Install new symlink
	echo "Linking $INSTALLNAME to $SCRIPT"
	if [ ! -x $SCRIPT ]; then
	    echo "Making $SCRIPT executable"
	    chmod +x $SCRIPT
	fi
	ln -s $SCRIPT $BIN_DIR/${INSTALLNAME}
    done
}

read_image_env(){
    if [ -a ${SCRIPT_DIR}/images/${EXECNAME}/*.env ]; then
        source ${SCRIPT_DIR}/images/${EXECNAME}/*.env
    fi
}


run(){
    local EXECNAME=$1
    shift
    local WORKING_DIRECTORY=$(pwd)
    local DOCKER_IMAGE_NAME=$(normalize_image_name $EXECNAME)
    local PIPED=0

    if $FORCE_BUILD || [ -z "$(docker images -q $DOCKER_IMAGE_NAME)" ]; then
        build_image $EXECNAME
    fi

    read_image_env

    # Piping to Docker requires interactive
    if !(tty -s); then
	PIPED=1
	GENERAL_DOCKER_RUN_FLAGS="$GENERAL_DOCKER_RUN_FLAGS -i"
    fi

    # Detached mode negates piping
    # It's also incompatible with the --rm flag
    if [ $DETACH ]; then
	PIPED=0
	GENERAL_DOCKER_RUN_FLAGS=${GENERAL_DOCKER_RUN_FLAGS//--rm/-d}
    fi

    runline="docker run $GENERAL_DOCKER_RUN_FLAGS \
            $LOCAL_DOCKER_RUN_FLAGS \
            -v $WORKING_DIRECTORY:/workspace \
            -u $UID \
            $DOCKER_IMAGE_NAME $@ \
            $LOCAL_COMMAND_FLAGS"


    # This will re-pipe standard input
    if [ !$PIPED ]; then

	if [ $DETACH ]; then
	    PID=$($runline)
	    [ -z "$PID" ] && echo "Container failed to start!" && exit 1 || (docker wait $PID &>/dev/null && docker rm -v $PID &>/dev/null)&
	else
	    ($runline)
	fi

    else
    	cat - | ($runline)
    fi
}

# runtime
#########

runstr="display_help"

if [ $# -eq 0 ]; then
    # display_help 1
    echo ""
else
    case $1 in
	build)
	    runstr="build_image"
	    shift ;;
	install)
	    runstr="install"
	    shift ;;
	clean)
	    runstr="clean"
	    shift ;;
	list)
	    runstr="list"
	    shift ;;
	info)
	    runstr="info"
	    shift ;;
	*)                runstr="run" ;;
    esac

    $runstr $@
    exit $?
fi
