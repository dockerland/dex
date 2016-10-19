#
# lib.d/helpers/preconf.sh for dex -*- shell-script -*-
#

# usage: preconf-container-name <image name>
preconf-container-name(){
  echo $1"_original"
}

# usage: preconf-init-temp-dir <image name>
preconf-init-temp-dir(){
  local preconf_dir="$DEX_HOME/preconf_temp/$1"
  rm -rf $preconf_dir
  mkdir -p $preconf_dir
  echo $preconf_dir
}

# usage: preconf-install <image name>
preconf-install(){
    local container_name=$(preconf-container-name $1)
    __local_docker rm --force --volumes $container_name
    __local_docker run docker run --entrypoint=/dev/null --name $container_name $1
}

# usage: preconf-runtime <image name>
preconf-runtime(){
    local container_name=$(preconf-container-name $1)
    local temp_dir=$(preconf-init-temp-dir $1)
    
    passwd_file="$temp_dir/etc/passwd"
    groups_file="$temp_dir/etc/passwd"

    docker cp $container_name:/etc/passwd $passwd_file
    docker cp $container_name:/etc/group $group_file

    echo "$DEX_HOST_USER:x:$DEX_HOST_UID:$DEX_HOST_UID:fullname:/dex/home:/bin/sh" >> $passwd_file
    echo "$DEX_HOST_GROUP:x:$DEX_HOST_GID:" >> $group_file
}

