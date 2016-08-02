#
# dex
# @author: Brice Burgess @briceburg
#
# Makefile reference vars :
#  https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html#Automatic-Variables
#

#
# common
#

CWD:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
SCRATCH_PATH:=$(CWD)/.scratch
NAMESPACE=dex

.PHONY: tests

all:

clean:
	rm -rf $(SCRATCH_PATH)
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

tests: $(SCRATCH_PATH)/dockerbuild-tests
	docker run -it --rm -v $(CWD)/tests/bats:/tests \
	  -u $$(id -u):$$(id -g) dockerbuild-$(NAMESPACE)-tests
