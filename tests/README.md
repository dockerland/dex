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
Manually trigger tests from the [tests/bats](tests/bats) directory.

```
cd /path/to/project/tests/bats
bats .
```

## test development

TBD - for now use existing bats/ files as reference. Numerically
prefix test filenames to maintain execution order.

### fixtures

Use fixtures to mock complicated/larger expected output. Store fixtures in
[tests/fixtures](tests/fixtures).

Test [helpers](tests/bats/helpers.bash) provide `cat_fixture` and
`cp_fixture` for working with fixutes.


#### example cat_fixture

compare the application's help output to our fixtures.

```
diff <(cat_fixture help.txt) <($APP --help)
```

##### example updating help fixture(s)

```
cd /path/to/project
./app.sh --help > tests/fixtures/help.txt
./app.sh help vars > tests/fixtures/help-vars.txt
# &c...
```

#### example cp_fixture

copy our image fixtures to TMPDIR/images
```
cp_fixture images/ $TMPDIR/images
```
