# Testing

## test execution

Use the root `Makefile` to build and run tests in a container preloaded with
with [bats](https://github.com/sstephenson/bats), git, and common shells.

```
cd /path/to/project
make tests
```

Limit which tests to run by exporting or passing `TEST`, e.g.
```
make TEST=00-makefile.bats tests
```

Some tests make remote network calls. This can slow things down, esp.
on a system with an unresponsive resolver. Skip these by exporting or passing `SKIP_NETWORK_TEST`, e.g.

```
SKIP_NETWORK_TEST=true make tests
```

### manual test execution

Have [bats](https://github.com/sstephenson/bats) installed?
Manually trigger tests from the [tests/bats](bats/) directory -- clearing the temp directory beforehand.

```
rm -rf tests/bats/tmp && bats tests/bats/
```

## test development

TBD - for now use existing bats/ files as reference. Numerically
prefix test filenames to maintain execution order.

### fixtures

Use fixtures to mock complicated/larger expected output. Store fixtures in
[tests/fixtures](fixtures/)

Test [helpers](bats/helpers.bash) provide `fixture/cat`
and `fixture/cp` for working with fixutes.


#### example fixture/cat

compare the application's help output to our fixtures.

```
diff $DEX_HOME/sources.list <(fixture/cat sources.list)
```

#### example fixture/cp

copy our image fixtures to TMPDIR/images
```
fixture/cp sources.list $DEX_HOME/sources.list
```
