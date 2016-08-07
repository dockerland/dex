#!/usr/bin/env bash

BLUEACORN_DIR=${BLUEACORN_DIR:-/etc/blueacorn}
BIN_DIR="$BLUEACORN_DIR/bin"

GENERAL_DOCKER_RUN_FLAGS="--rm --log-driver=none"
FORCE_BUILD=false

DOCKER_BUILD_FLAGS="--rm -q --pull"

# This won't work with symlinks might need to revisit
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# utility
#########

error(){
  printf "\033[31m%s\n\033[0m" "$@" >&2
  exit 1
}

out_info() {
    colorize Green "[$@]"
}

# Should probably stick this somewhere better
colorize() {
    local COLOR_WORD=$1
    shift

    # Reset
    Color_Off='\e[0m'       # Text Reset

    # Regular Colors
    Black='\e[0;30m'        # Black
    Red='\e[0;31m'          # Red
    Green='\e[0;32m'        # Green
    Yellow='\e[0;33m'       # Yellow
    Blue='\e[0;34m'         # Blue
    Purple='\e[0;35m'       # Purple
    Cyan='\e[0;36m'         # Cyan
    White='\e[0;37m'        # White

    # Bold
    BBlack='\e[1;30m'       # Black
    BRed='\e[1;31m'         # Red
    BGreen='\e[1;32m'       # Green
    BYellow='\e[1;33m'      # Yellow
    BBlue='\e[1;34m'        # Blue
    BPurple='\e[1;35m'      # Purple
    BCyan='\e[1;36m'        # Cyan
    BWhite='\e[1;37m'       # White

    # Underline
    UBlack='\e[4;30m'       # Black
    URed='\e[4;31m'         # Red
    UGreen='\e[4;32m'       # Green
    UYellow='\e[4;33m'      # Yellow
    UBlue='\e[4;34m'        # Blue
    UPurple='\e[4;35m'      # Purple
    UCyan='\e[4;36m'        # Cyan
    UWhite='\e[4;37m'       # White

    echo -e "${!COLOR_WORD}$@$Color_Off"
}

normalize_image_name(){
    local DOCKER_NAME=${1,,}
    DOCKER_NAME="${DOCKER_NAME}_batool"
    DOCKER_NAME=${DOCKER_NAME//-/_}
    DOCKER_NAME=${DOCKER_NAME// /_}
    DOCKER_NAME=${DOCKER_NAME//[^a-z0-9_]/}

    echo $DOCKER_NAME
}

clean() {
    local EXECLIST=$(if_all $@)

    for EXECNAME in $EXECLIST ; do
        local DOCKER_IMAGE_NAME=$(normalize_image_name $EXECNAME)

        out_info "Cleaning $DOCKER_IMAGE_NAME"

        out_info "Removing containers"
        for containerid in $(docker ps -a | grep $DOCKER_IMAGE_NAME | cut -f 1 --delimiter=" ") ; do
            docker rm -v $containerid
        done

        out_info "Removing image"
        docker rmi -f $(docker images -q $DOCKER_IMAGE_NAME)
    done
}

build_image() {
    local EXECLIST=$(if_all $@)

    for EXECNAME in $EXECLIST ; do
        local DOCKER_IMAGE_NAME=$(normalize_image_name $EXECNAME)
        local DOCKER_BUILD_DIR="${SCRIPT_DIR}/images/${EXECNAME}/."

        out_info "Building image for $EXECNAME"
        docker build $DOCKER_BUILD_FLAGS -t $DOCKER_IMAGE_NAME $DOCKER_BUILD_DIR
    done
}

info(){
    local EXECLIST=$(if_all $@)

    for EXECNAME in $EXECLIST ; do
        local DOCKER_IMAGE_NAME=$(normalize_image_name $EXECNAME)
        local DOCKER_BUILD_DIR="${SCRIPT_DIR}/images/${EXECNAME}/"

        local FROM_IMAGE=$(cat ${DOCKER_BUILD_DIR}Dockerfile | grep FROM | cut -f 2 -d " ")
        local WORKDIR=$(cat ${DOCKER_BUILD_DIR}Dockerfile | grep WORKDIR | cut -f 2 -d " ")
        local BUILD_STATUS=$(docker inspect $DOCKER_IMAGE_NAME >/dev/null 2>&1 && echo $(colorize Green "Built") || echo $(colorize Red "Not built"))

        echo $(colorize UWhite "Info for '$EXECNAME'")
        echo "$(colorize BWhite Image:) $DOCKER_IMAGE_NAME"
        echo "$(colorize BWhite From:) $FROM_IMAGE"
        echo "$(colorize BWhite "Build status:") $BUILD_STATUS"
        echo
    done
}

print_list(){
    for EXECNAME in $(list) ; do
        echo $EXECNAME
    done
}

list(){
    local EXECLIST=""
    for EXECNAME in $(find ${SCRIPT_DIR}/images -maxdepth 1 -mindepth 1 -type d -printf "%f ") ; do
        EXECLIST+="$EXECNAME "
    done

    echo $EXECLIST
}

if_all(){
    if [ "$1" = "all" ]; then
        echo $(list)
    else
        echo $@
    fi
}

remove(){
    local EXECLIST=$(if_all $@)

    for EXECNAME in $EXECLIST ; do
        local INSTALLNAME=$EXECNAME
        read_image_env

        clean $EXECNAME

        # Unlink existing symlink
        if [ -L $BIN_DIR/$INSTALLNAME ]; then
            out_info "Unlinking $INSTALLNAME"
            unlink $BIN_DIR/$INSTALLNAME
        fi
    done
}

install(){
    local EXECLIST=$(if_all $@)

    for EXECNAME in $EXECLIST ; do
        local SCRIPTNAME="${EXECNAME}.sh"
        local INSTALLNAME=$EXECNAME
        local SCRIPT=${BLUEACORN_BOOTSTRAP_DIR}/tools/ba-docker-exec/images/${EXECNAME}/${SCRIPTNAME}
        read_image_env

        build_image $EXECNAME

        # Unlink existing symlink
        if [ -L $BIN_DIR/$INSTALLNAME ]; then
            out_info "Unlinking old $INSTALLNAME"
            unlink $BIN_DIR/$INSTALLNAME
        fi

        # Archive existing file
        if [ -f $BIN_DIR/$INSTALLNAME ]; then
            current_time=$(date "+%Y.%m.%d-%H.%M.%S")
            out_info "Archiving $INSTALLNAME as ${INSTALLNAME}.$current_time"
            mv $BIN_DIR/$INSTALLNAME $BIN_DIR/${INSTALLNAME}.$current_time
        fi

        # Install new symlink
        out_info "Linking $INSTALLNAME to $SCRIPT"
        if [ ! -x $SCRIPT ]; then
            out_info "Making $SCRIPT executable"
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
    local WORKING_DIRECTORY_PATH=$(pwd)
    local DOCKER_IMAGE_NAME=$(normalize_image_name $EXECNAME)
    local PIPED=0
    local DOCKER_USER=$UID

    if $FORCE_BUILD || [ -z "$(docker images -q $DOCKER_IMAGE_NAME)" ]; then
        build_image $EXECNAME
    fi

    read_image_env

    local WORKING_DIRECTORY_NAME=${WORKING_DIRECTORY_PATH##*/}
    local DOCKER_WORKING_DIRECTORY_PATH="/workspace/$WORKING_DIRECTORY_NAME"

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
            -v $WORKING_DIRECTORY_PATH:$DOCKER_WORKING_DIRECTORY_PATH \
            -w $DOCKER_WORKING_DIRECTORY_PATH \
            -u $DOCKER_USER \
            $DOCKER_IMAGE_NAME $@ \
            $LOCAL_COMMAND_FLAGS"


    # This will re-pipe standard input
    if [ !$PIPED ]; then

        if [ $DETACH ]; then
            # echo $runline
            PID=$($runline)
            [ -z "$PID" ] && error "Container failed to start!" || (docker wait $PID &>/dev/null && docker rm -v $PID &>/dev/null)&
        else
            ($runline)
            # echo $runline
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
        install|add)
            runstr="install"
            shift ;;
        remove|uninstall|rm)
            runstr="remove"
            shift ;;
        clean)
            runstr="clean"
            shift ;;
        list|ls)
            runstr="print_list"
            shift ;;
        info)
            runstr="info"
            shift ;;
        *)                runstr="run" ;;
    esac

    $runstr $@
    exit $?
fi