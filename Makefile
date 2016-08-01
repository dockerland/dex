#
# Makefile reference vars :
#  https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html#Automatic-Variables
#

CWD:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
SCRATCH_PATH:=$(CWD)/.scratch
NAMESPACE=dex

.PHONY: tests

all:

clean:
	rm -rf $(SCRATCH_PATH)
	for id in $$(docker images -q dockerbuild-dex-*) ; do docker rmi  $$id ; done

scratch:
	mkdir -p $(SCRATCH_PATH)

tests: $(SCRATCH_PATH)/dockerbuild-tests
	docker run -it --rm -v $(CWD)/tests:/tests dockerbuild-$(NAMESPACE)-tests

$(SCRATCH_PATH)/dockerbuild-%: scratch
	echo "--- building Dockerfiles from $*/ ---"
	docker build --tag dockerbuild-$(NAMESPACE)-$* $*/
	touch $@
