# dex-tests


## test execution

Tests are executed in a docker container with bats, git, and some common shells.
Use the Makefile in our repository root to execute. The following runs all tests

```
cd /path/to/dex.git
make tests
```

Limit which tests to run by exporting or passing `TEST`, e.g.
```
make TEST=07-run.bats tests
```

Some tests make remote network calls. This can slow things down, esp.
on a system with an unresponsive resolver. Skip these by exporting or passing `SKIP_NETWORK_TEST`, e.g.

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
