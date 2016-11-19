#
# dex makefile
#
# Makefile reference vars :
#  https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html#Automatic-Variables
#

#
# common targets
#

CWD:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
NAMESPACE:=dex
prefix = $(DESTDIR)/usr/local
bindir = $(prefix)/bin

.PHONY: all clean clean-tests install uninstall dockerbuild-%
all: $(NAMESPACE)

clean:
	rm -rf bin/$(NAMESPACE)

clean-dockerbuilds: clean
	for id in $$(docker images -q makefile-$(NAMESPACE)-*) ; do docker rmi  $$id ; done

dockerbuild-%:
	echo "--- building Dockerfiles from $*/ ---"
	docker build \
	  --build-arg NAMESPACE=$(NAMESPACE) \
		--tag makefile-$(NAMESPACE)-$* \
		  $*/

install: $(NAMESPACE)
	$(info * installing $(bindir)/$(NAMESPACE))
  # use mkdir vs. install -D/d (macos portability)
	@mkdir -p $(bindir)
	@install bin/$(NAMESPACE) $(bindir)/$(NAMESPACE)

uninstall:
	rm -rf  $(bindir)/$(NAMESPACE)

#
# app targets
#

RELEASE_TAG ?= $(shell git rev-parse --abbrev-ref HEAD)
RELEASE_SHA ?= $(shell git rev-parse --short HEAD)

DOCKER_SOCKET ?= /var/run/docker.sock
DOCKER_GROUP_ID ?= $(shell ls -ln $(DOCKER_SOCKET) | awk '{print $$4}')

# for docker-for-mac, we also add group-id of 50 ("authedusers") as moby seems to auto bind-mount /var/run/docker.sock w/ this ownership
# @TODO investigate and remove this docker-for-mac kludge
DOCKER_FOR_MAC_WORKAROUND := $(shell if [[ "$$OSTYPE" == darwin* ]] || [[ "$$OSTYPE" == macos* ]]; then echo "--group-add=50" ; fi)

TEST ?=
SKIP_NETWORK_TEST ?=

.PHONY: $(NAMESPACE) tests
$(NAMESPACE):
	$(info * building bin/$(NAMESPACE) ...)
	@( \
	  mkdir -p $(CWD)/bin ; \
	  sed \
	    -e '/\@start/,/\@end/d' \
		  -e 's|@VERSION@|$(RELEASE_TAG)|' \
		  -e 's|@BUILD@|$(shell echo "$(RELEASE_SHA)" | cut -c1-7)|' \
		  $(CWD)/dex.sh > $(CWD)/bin/$(NAMESPACE) ; \
	  find $(CWD)/lib.d/ -type f -name "*.sh" -exec cat {} >> $(CWD)/bin/$(NAMESPACE) + ; \
	  echo 'main "$$@"' >> $(CWD)/bin/$(NAMESPACE) ; \
	  chmod +x $(CWD)/bin/$(NAMESPACE) ; \
	)

tests: dockerbuild-tests
	@rm -rf $(CWD)/tests/bats/tmp
	docker run -it --rm -u $$(id -u):$$(id -g) $(DOCKER_FOR_MAC_WORKAROUND) \
    --group-add=$(DOCKER_GROUP_ID) \
    --device=/dev/tty0 --device=/dev/console \
		-v $(CWD)/:/$(CWD) \
		-v $(DOCKER_SOCKET):/var/run/docker.sock \
    -e SKIP_NETWORK_TEST=$(SKIP_NETWORK_TEST) \
		--workdir $(CWD) \
	    makefile-$(NAMESPACE)-tests bats tests/bats/$(TEST)
	rm -rf $(CWD)/tests/bats/tmp

#
# release targets
#

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
_mkrelease: _release_check $(NAMESPACE)
	[[ "$$PATH" == *badevops/bin* ]] && docker-machine scp $(CWD)/bin/$(NAMESPACE) node-c:/docker-volumes/files.badevops.com/get.blueacorn.net/$(NAMESPACE)-$(MAKECMDGOALS)
	
	git push $(REMOTE_LOCAL) $(MERGE_BRANCH):$(BRANCH)
	git push $(REMOTE_GH) $(BRANCH)
	$(eval CREATE_JSON=$(shell printf '{"tag_name": "%s","target_commitish": "%s","draft": false,"prerelease": %s}' $(RELEASE_TAG) $(RELEASE_SHA) $(PRERELEASE)))
	@( \
	  echo "  * attempting to create release $(RELEASE_TAG) ..." ; \
		id=$$(curl -sLH "Authorization: token $(GH_TOKEN)" $(GH_URL)/repos/$(GH_PROJECT)/releases/tags/$(RELEASE_TAG) | jq -Me .id) ; \
		[ $$id = "null" ] && id=$$(curl -sLH "Authorization: token $(GH_TOKEN)" -X POST --data '$(CREATE_JSON)' $(GH_URL)/repos/$(GH_PROJECT)/releases | jq -Me .id) ; \
		[ $$id = "null" ] && echo "  !! unable to create release -- perhaps it exists?" && exit 1 ; \
		echo "  * uploading $(CWD)/bin/$(NAMESPACE) to release $(RELEASE_TAG) ($$id) ..." ; \
    curl -sL -H "Authorization: token $(GH_TOKEN)" -H "Content-Type: text/x-shellscript" --data-binary @"$(CWD)/bin/$(NAMESPACE)" -X POST $(GH_UPLOAD_URL)/repos/$(GH_PROJECT)/releases/$$id/assets?name=$(NAMESPACE).sh &>/dev/null ; \
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
