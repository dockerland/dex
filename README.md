# dex

dex manages docker executables

## what are docker executables

docker executables look and behave like normal executables supporting
 [redirection](https://en.wikipedia.org/wiki/Redirection_%28computing%29) and [piping](https://en.wikipedia.org/wiki/Redirection_%28computing%29#Piping), except they
  * run as a docker container, e.g. from a [Dockerfile](https://docs.docker.com/engine/reference/builder/) containing the application and its dependencies
  * are launched from a [shell alias](#shell alias)

### What's cool about this?

* _docker_ and _dex_ are now your only dependencies - your OS is a clean OS.
* dependency isolation - different versions of python? no problem
* test tools from other platforms - `dex install sed:darwin && dsed --help`


## WIP

dex is coming soon to a theatre near you.

### design ideas

* prefix executables with 'd', similar to homebrew prefixing `coreutils` with a 'g'.
* support docker tag convention when publishing/installing. e.g. `dex install sed`, `dex install sed:latest`, `dex install sed:darwin`, `dex install sed:darwin-sierra`
* support dex api versioning, e.g. v1 executable, v2, &c


## running docker executables

### shell alias
TBD


## developing docker executables
TBD
