__local_docker(){
  (
    __deactivate_machine
    exec docker "$@"
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
