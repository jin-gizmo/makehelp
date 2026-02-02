SHELL:=/bin/bash

include help.mk

REPO_URL=https://github.com/jin-gizmo/makehelp

#+ **Welcome to $(APP) (v$(VERSION))**

#- Go to $(REPO_URL) for more information.

APP=MakeHelp
VERSION:=$(shell cat VERSION)

.PHONY: dist test test-all image-all clean
.DELETE_ON_ERROR:

SRC=help.mk help.awk make.vim
DIST=$(foreach f,$(SRC),dist/$f)

SAMPLES=$(wildcard doc/samples/*.mk)
SCREENSHOTS=$(patsubst doc/samples/%.mk,doc/img/sample-%.png,$(SAMPLES))

TESTENVS:=$(patsubst etc/test-%.Dockerfile,%,$(wildcard etc/*.Dockerfile))

# ------------------------------------------------------------------------------
## Diff program to use for test failures.
## Automatically reverts to **diff** as a last resort.
diff=difft --skip-unchanged --exit-code

draft=false

#:vcat Local system (read-only)
##
override OS:=$(shell \
	if [ -f /etc/os-release ]; then . /etc/os-release && echo "$$NAME $$VERSION_ID" ; \
	elif [ -f /etc/alpine-release ]; then echo "Alpine $$(cat /etc/alpine-release)" ; \
	else uname -sr ; \
	fi)

LEFT=(
##
override AWK_VERSION:=$(shell \
	set -o pipefail ; \
	awk --version 2>/dev/null | sed -e 's/ *[$(LEFT),].*//;q' ; \
	[ $$? -ne 0 ] && awk 2>&1 | sed -e 's/ *[$(LEFT),].*//;q' ; \
)

##
override MAKE_VERSION:=$(MAKE_VERSION)

# ------------------------------------------------------------------------------
#:cat Build targets

dist/%:	% VERSION
	@mkdir -p dist
	sed -e 's/!VERSION!/$(VERSION)/' $< > $@

## Make the distribution versions of the $(APP) components.
dist:	$(DIST)

## Create a github release. Set *draft* to either `true` or `false`.
#:opt draft
release:
	@if gh release view "v$(VERSION)" > /dev/null 2>&1 ; \
	then \
		echo "Updating existing release for tag v$(VERSION)" ; \
		gh release upload --clobber "v$(VERSION)" $(SRC) ; \
		gh release edit \
			--draft="$(draft)" \
			--verify-tag=false \
			--title "Version $(VERSION)" \
			--notes "$(REPO_URL)/tree/master?tab=readme-ov-file#release-notes" \
			"v$(VERSION)" ; \
	else \
		echo "Creating new release for tag v$(VERSION)" ; \
		gh release create \
			--draft="$(draft)" \
			--fail-on-no-commits \
			--verify-tag=false \
			--title "Version $(VERSION)" \
			--notes "$(REPO_URL)/tree/master?tab=readme-ov-file#release-notes" \
			"v$(VERSION)" \
			$(SRC) ; \
	fi
	@gh release view "v$(VERSION)"

# ------------------------------------------------------------------------------
#:cat Test Targets
_TE:=$(foreach env,$(TESTENVS), `$(env)`)

## Run tests in a docker container for the target environment.
## `%` must be one of $(_TE).
test.%:
	@if [ ! -f "etc/test-$*.Dockerfile" ] ; \
	then echo "Unknown test environment: $*" && exit 1 ; \
	else true ; \
	fi
	@docker run -t --rm -v "$$(pwd):/makehelp" "makehelp-test:$*" make test $(MAKEFLAGS)

## Build a docker image for running $(APP) tests for the targer environment.
## `%` must be one of $(_TE).
image.%:
	@mkdir -p dist/empty
	docker buildx build --pull -f "etc/test-$*.Dockerfile" -t "makehelp-test:$*" dist/empty

## Build all available test images.
image-all: $(foreach env,$(TESTENVS),image.$(env))

## Run the tests on the local machine.
#:opt diff
test:
	@echo -e "\033[34mRunning tests for $(OS) / AWK=$(AWK_VERSION) / make=$(MAKE_VERSION) ...\033[0m"
	@( \
		diff="$(diff)" ; \
		$$diff --help > /dev/null 2>&1 ; \
		[ $$? -eq 127 ] && diff=diff ; \
		for f in test/*.mk ; \
		do \
			make --no-print-directory -f "$$f" HELP_WIDTH=80 HELP_THEME=basic \
				| $$diff - $${f%.mk}.out ; \
			if [ $$? -eq 0 ] ; \
			then \
				echo -e "\033[32m$$f - OK\033[0m" ; \
			else \
				echo -e "\033[31m$$f - Failed\033[0m" ; \
				exit 1 ; \
			fi ; \
		done \
	)
	@echo


## Build the reference output for a given test makefile `%.mk`.
## Usage is `make test/abc.out`.
%.out:	%.mk
	make -f "$<" HELP_WIDTH=80 HELP_THEME=basic > "$@"

## Run tests on all available test environments.
test-all: test $(foreach env,$(TESTENVS),test.$(env))

# ------------------------------------------------------------------------------
#:cat Auxiliary targets

HELP_CATEGORY=Auxiliary targets

## Delete built artefacts.
clean:
	$(RM) -r dist

## Regenerate the screenshots used in the documentation (macOS only).
## Requires the Kitty terminal app and the ImageMagick CLI (magick).
## The *make screenshots* itself cannot be run from Kitty and Kitty cannot be
## open when the process starts.
screenshots: $(SCREENSHOTS)

doc/img/sample-%.png: doc/samples/%.mk
	etc/cli-cmd-snap -o "$@" -c80 -r70 -f13 -- make -f "$<" HELP_THEME=dark
