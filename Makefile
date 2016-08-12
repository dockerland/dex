#
# dex makefile
#
# Makefile reference vars :
#  https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html#Automatic-Variables
#

#
# common
#

CWD:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
NAMESPACE:=dex

PREFIX:=$(DESTDIR)/usr/local
BINDIR:=$(PREFIX)/bin

SCRATCH_PATH:=$(CWD)/.scratch
DOCKER_GID ?= $(shell getent group docker | cut -d: -f3)

TEST ?=
SKIP_NETWORK_TEST ?=

.PHONY: tests dex
all: dex

clean:
	rm -rf $(CWD)/bin/dex
	rm -rf $(SCRATCH_PATH)

clean-tests: clean
	for id in $$(docker images -q dockerbuild-dex-*) ; do docker rmi  $$id ; done

$(SCRATCH_PATH):
	mkdir -p $(SCRATCH_PATH)

$(SCRATCH_PATH)/dockerbuild-%: $(SCRATCH_PATH)
	echo "--- building Dockerfiles from $*/ ---"
	docker build --tag dockerbuild-$(NAMESPACE)-$* $*/
	touch $@


#
# app
#

dex:
	#
	# inline helpers into single shell-script
	#
	sed '/\@start/,/\@end/d' $(CWD)/dex.sh > $(CWD)/bin/dex
	find $(CWD)/lib.d/ -type f -name "*.sh" -exec cat {} >> $(CWD)/bin/dex +
	echo 'main "$$@"' >> $(CWD)/bin/dex
	chmod +x $(CWD)/bin/dex

install: dex

  # use mkdir vs. install -D/d (darwin portability)
	mkdir -p $(BINDIR)
	install bin/dex $(BINDIR)/dex

	# @TODO man page installation

uninstall:
	rm -rf  $(BINDIR)/dex

tests: $(SCRATCH_PATH)/dockerbuild-tests
	mkdir -p /tmp/dex-tests

	docker run -it --rm -u $$(id -u):$(DOCKER_GID) \
	  -v $(CWD)/:/dex/ \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v /tmp/dex-tests:/tmp/dex-tests \
	  -e SKIP_NETWORK_TEST=$(SKIP_NETWORK_TEST) \
	  dockerbuild-$(NAMESPACE)-tests bats tests/bats/$(TEST)
