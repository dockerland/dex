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
# app targets
.PHONY: dex tests install uninstall

RELEASE_TAG ?= $(shell git rev-parse --abbrev-ref HEAD)
RELEASE_SHA ?= $(shell git rev-parse --short HEAD)

DOCKER_GROUP ?= docker
DOCKER_GID ?= $(shell if type getent &>/dev/null; then getent group $(DOCKER_GROUP) | cut -d: -f3 ; elif type dscl &>/dev/null; then dscl . -read /Groups/$(DOCKER_GROUP) PrimaryGroupID 2>/dev/null | awk '{ print $2 }' ; else python -c "import grp; print(grp.getgrnam(\"$(DOCKER_GROUP)\").gr_gid)" 2>/dev/null ; fi)

TEST ?=
SKIP_NETWORK_TEST ?=

dex:
	$(info building dex...)
	@( \
	  sed \
	    -e '/\@start/,/\@end/d' \
		  -e 's/@DEX_VERSION@/$(RELEASE_TAG)/' \
		  -e 's/@DEX_BUILD@/$(shell echo "$(RELEASE_SHA)" | cut -c1-7)/' \
		  $(CWD)/dex.sh > $(CWD)/bin/dex ; \
	  find $(CWD)/lib.d/ -type f -name "*.sh" -exec cat {} >> $(CWD)/bin/dex + ; \
	  echo 'main "$$@"' >> $(CWD)/bin/dex ; \
	  chmod +x $(CWD)/bin/dex ; \
	)
	$(info * built $(CWD)/bin/dex)

install: dex

  # use mkdir vs. install -D/d (macos portability)
	mkdir -p $(BINDIR)
	install bin/dex $(BINDIR)/dex

	# @TODO man page installation

uninstall:
	rm -rf  $(BINDIR)/dex

tests: $(SCRATCH_PATH)/dockerbuild-tests
	rm -rf /tmp/dex-tests
	mkdir -p /tmp/dex-tests
	docker run -it --rm -u $$(id -u):$(DOCKER_GID) \
	  --device=/dev/tty0 --device=/dev/console \
	  -v $(CWD)/:/dex/ \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v /tmp/dex-tests:/tmp/dex-tests \
	  -e SKIP_NETWORK_TEST=$(SKIP_NETWORK_TEST) \
		-e IN_TEST_CONTAINER=true \
	  dockerbuild-$(NAMESPACE)-tests bats tests/bats/$(TEST)

#
# release helpers
.PHONY: release prerelease _mkrelease

RELEASE_VERSION ?=

GH_TOKEN ?=
GH_URL ?= https://api.github.com
GH_UPLOAD_URL ?= https://uploads.github.com
GH_PROJECT:=dockerland/dex

REMOTE_GH:=origin
REMOTE_LOCAL:=local

prerelease: BRANCH = prerelease
prerelease: MERGE_BRANCH = master
prerelease: PRERELEASE = true
prerelease: _mkrelease

release: BRANCH = release
release: MERGE_BRANCH = master
release: PRERELEASE = false
release: _mkrelease

_mkrelease: RELEASE_SHA = $(shell git rev-parse $(MERGE_BRANCH))
_mkrelease: RELEASE_TAG = v$(RELEASE_VERSION)$(shell $(PRERELEASE) && echo '-pr')
_mkrelease: _release_check dex
	git push $(REMOTE_LOCAL) $(MERGE_BRANCH):$(BRANCH)
	git push $(REMOTE_GH) $(BRANCH)
	$(eval CREATE_JSON=$(shell printf '{"tag_name": "%s","target_commitish": "%s","draft": false,"prerelease": %s}' $(RELEASE_TAG) $(RELEASE_SHA) $(PRERELEASE)))
	@( \
	  echo "  * attempting to create release $(RELEASE_TAG) ..." ; \
		id=$$(curl -sLH "Authorization: token $(GH_TOKEN)" $(GH_URL)/repos/$(GH_PROJECT)/releases/tags/$(RELEASE_TAG) | jq -Me .id) ; \
		[ $$id = "null" ] && id=$$(curl -sLH "Authorization: token $(GH_TOKEN)" -X POST --data '$(CREATE_JSON)' $(GH_URL)/repos/$(GH_PROJECT)/releases | jq -Me .id) ; \
		[ $$id = "null" ] && echo "  !! unable to create release -- perhaps it exists?" && exit 1 ; \
		echo "  * uploading $(CWD)/bin/dex to release $(RELEASE_TAG) ($$id) ..." ; \
    curl -sL -H "Authorization: token $(GH_TOKEN)" -H "Content-Type: text/x-shellscript" --data-binary @"$(CWD)/bin/dex" -X POST $(GH_UPLOAD_URL)/repos/$(GH_PROJECT)/releases/$$id/assets?name=dex.sh &>/dev/null ; \
	)

#
# sanity checks
.PHONY: _release_check _gh_check _wc_check

SKIP_WC_CHECK ?=

_release_check: _wc_check _git_check _gh_check
	@test ! -z "$(RELEASE_VERSION)" || ( \
	  echo "  * please provide RELEASE_VERSION - e.g. '1.0.0'" ; \
		echo "     'v' and '-pre' are automatically added" ; \
		false )

_git_check:
	$(info ensure release branches, local remote, and checkout $(MERGE_BRANCH)...)
	@git rev-parse --verify "$(BRANCH)" &>/dev/null || \
	  git branch --track $(BRANCH) $(MERGE_BRANCH)
	@git ls-remote --exit-code --heads $(REMOTE_LOCAL) &>/dev/null || \
	  git remote add $(REMOTE_LOCAL) $(shell git rev-parse --show-toplevel)
	@git checkout $(MERGE_BRANCH)

_gh_check:
	$(info checking communication with GitHub...)
	@type jq&>/dev/null || ( \
	  echo "  * jq (https://github.com/stedolan/jq) missing from your PATH." ; \
		false )
	@test ! -z "$(GH_TOKEN)" || ( \
	  echo "  * please provide GH_TOKEN - your GitHub personal access token" ; \
		false )
	$(eval CODE=$(shell curl -iso /dev/null -w "%{http_code}" -H "Authorization: token $(GH_TOKEN)" $(GH_URL)))
	@test "$(CODE)" = "200" || ( \
	  echo "  * request to GitHub failed to return 200 ($(CODE)). " ; \
		false )

ifdef SKIP_WC_CHECK
  _wc_check:
	  $(info skipping working copy check...)
else
  _wc_check:
		$(info checking for clean working copy...)
		@test -z "$$(git status -uno --porcelain)" || ( \
			echo "   * please stash or commit changes before continuing" ; \
			echo "     or set SKIP_WC_CHECK=true" ; false )
endif
