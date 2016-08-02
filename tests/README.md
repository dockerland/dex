# dex-tests


## test execution

Tests are executed in a docker container with bats, git, and some common shells.
Use the Makefile in our repository root to execute, e.g.

```
cd /path/to/dex.git
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
