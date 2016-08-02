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
SCRATCH_PATH:=$(CWD)/.scratch
NAMESPACE=dex

PREFIX:=$(DESTDIR)/usr/local
BINDIR:=$(PREFIX)/bin

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
	cat $(CWD)/lib.d/*.sh >> $(CWD)/bin/dex
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
	docker run -it --rm -v $(CWD)/:/dex/ -u $$(id -u):$$(id -g) \
	  dockerbuild-$(NAMESPACE)-tests
