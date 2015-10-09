#!/usr/bin/env bash

GENERAL_DOCKER_RUN_FLAGS="--rm"
FORCE_BUILD=false

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

    docker build $DOCKER_BUILD_FLAGS -t $DOCKER_IMAGE_NAME $DOCKER_BUILD_DIR
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

    if [ -a ${SCRIPT_DIR}/images/${EXECNAME}/*.env ]; then
        source ${SCRIPT_DIR}/images/${EXECNAME}/*.env
    fi

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
	clean)
	    runstr="clean"
	    shift ;;
	*)                runstr="run" ;;
    esac

    $runstr $@
    exit $?
fi
