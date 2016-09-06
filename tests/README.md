# Testing Dex


## test execution

Use the root `Makefile` to build and run tests in a container preloaded with
with [bats](https://github.com/sstephenson/bats), git, and common shells.

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

### manual test execution

If you have [bats](https://github.com/sstephenson/bats) installed, you can
manually trigger tests as well.

```
cd /path/to/dex.git
cd tests
bats .
```


## test development

TBD - for now use existing bats/ files as reference. We prefer to numericaly
prefix filenames to maintain execution order.

### fixtures

Use fixtures to mock complicated/larger expected output.

#### updating help fixtures

```
cd /path/to/dex.git
./dex.sh --help > tests/fixtures/help.txt
./dex.sh help vars > tests/fixtures/help-vars.txt
# &c...
```
