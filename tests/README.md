# Testing

## test execution

Use the root `Makefile` to build and run tests in a container preloaded with
with [bats](https://github.com/sstephenson/bats) and other dependencies.

```sh
cd /path/to/project
make tests
```

Limit which tests to run by exporting or passing `TEST`, e.g.
```sh
make tests TEST=00-makefile.bats
```

Some tests make remote network calls. This can slow things down, esp.
on a system with an unresponsive resolver. Skip these by exporting or passing `SKIP_NETWORK_TEST`, e.g.

```sh
SKIP_NETWORK_TEST=true make tests
```

### manual test execution

Already have [bats](https://github.com/sstephenson/bats) installed?
Manually trigger tests from the [tests/bats](bats/) directory -- clearing the temp directory beforehand.

```sh
rm -rf tests/bats/tmp && bats tests/bats/
```

## test development

For now, use existing [bats/](bats/) files as reference. Group tests in a well named file and numerically
prefix to maintain execution order.

### fixtures

Fixtures are useful for mocking larger output and structures, and stored under the [tests/fixtures](fixtures/) directory.

Functions for working with fixtures are provided by [helpers.bash](bats/helpers.bash) (`fixture/cat` and `fixture/cp`).


#### example fixture/cat

compare the application's output to a fixture named 'sources.list'.

```sh
diff $TMPDIR/output <(fixture/cat sources.list)
```

#### example fixture/cp

copy the 'sources.list' fixture to TMPDIR/sources.list
```sh
fixture/cp sources.list $TMPDIR/sources.list
```
