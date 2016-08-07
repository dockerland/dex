# dex-tests


## test execution

Tests are executed in a docker container with bats, git, and some common shells.
Use the Makefile in our repository root to execute, e.g.

```
cd /path/to/dex.git
make tests
```

Some tests make remote network calls. This can slow things down, esp.
on a system with an unresponsive resolver. You can skip these by setting
`SKIP_NETWORK_TEST`, e.g.

```
export SKIP_NETWORK_TEST=true
make tests
```


## test development

TBD

### rebuild the test dockerfile

```
cd /path/to/dex.git
make clean
make tests
```

### updating the help.txt fixture

```
cd /path/to/dex.git
./dex.sh > tests/fixtures/help.txt
```
