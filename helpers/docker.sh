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
  }
}
