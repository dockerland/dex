__local_docker(){
  (
    __deactivate_machine
    exec docker "$@"
  )
}

__local_docker_compose(){
  (
    __deactivate_machine
    exec docker-compose "$@"
  )
}

__deactivate_machine(){
  # @TODO support boot2docker / concept of "default" machine
  type docker-machine &>/dev/null && {
    eval $(docker-machine env --unset --shell bash)
    return
  }
  # lets be safe and unset if missing docker-machine
  unset DOCKER_HOST DOCKER_TLS_VERIFY DOCKER_CERT_PATH DOCKER_MACHINE_NAME
}

docker_safe_name(){
  local name="$@"
  set -- "${name:0:1}" "${name:1}"
  printf "%s%s" "${1//[^a-zA-Z0-9]/0}" "${2//[^a-zA-Z0-9_.-]/_}"
}
