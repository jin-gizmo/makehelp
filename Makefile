SHELL:=/bin/bash

include help.mk

REPO_URL=https://github.com/jin-gizmo/makehelp

HELP_HR=yes

#+ **Welcome to MakeHelp (v$(VERSION))**

#- Go to $(REPO_URL) for more information.

APP=MakeHelp
VERSION:=$(shell cat VERSION)

.PHONY: dist test
.DELETE_ON_ERROR:

SRC=help.mk help.awk
DIST=$(foreach f,$(SRC),dist/$f)

SAMPLES=$(wildcard doc/samples/*.mk)
IMAGES=$(patsubst doc/samples/%.mk,doc/img/sample-%.png,$(SAMPLES))

# DIFF=diff
DIFF=difft --skip-unchanged --exit-code


dist/%:	%
	@mkdir -p dist
	sed -e 's/!VERSION!/$(VERSION)/' $< > $@

doc/img/sample-%.png: doc/samples/%.mk
	etc/cli-cmd-snap -o "$@" -c80 -r70 -f14 -- make -f "$<"

## Make the distribution versions of the $(APP) components.
dist:	$(DIST)

## Delete built artefacts.
clean:
	$(RM) -r dist

## Run the tests.
test:
	@( \
	for f in test/*.mk ; \
	do \
		make -f "$$f" HELP_WIDTH=80 | $(DIFF) - $${f%.mk}.out ; \
		if [ $$? -eq 0 ] ; \
		then \
			echo "$$f - 0K" ; \
		else \
			echo "$$f - Failed" ; \
			exit 1 ; \
		fi ; \
	done \
	)

## Regenerate the screenshots used in the documentation. macOS only.
## Requires kitty and the ImageMagick CLI (magick).
screenshots: $(IMAGES)

draft=false
# @opt draft

## Create a github release. Set *draft* to either `true` or `false`.
release:
	@if gh release view "v$(VERSION)" > /dev/null 2>&1 ; \
	then \
		echo "Updating existing release for tag v$(VERSION)" ; \
		gh release upload --clobber "v$(VERSION)" $(SRC) ; \
		gh release edit \
			--draft="$(draft)" \
			--verify-tag=false \
			--title "Version $(VERSION)" \
			--notes "$(REPO_URL)/#release-notes" \
			"v$(VERSION)" ; \
	else \
		echo "Creating new release for tag v$(VERSION)" ; \
		gh release create \
			--draft="$(draft)" \
			--fail-on-no-commits \
			--verify-tag=false \
			--title "Version $(VERSION)" \
			--notes "$(REPO_URL)/#release-notes" \
			"v$(VERSION)" \
			$(SRC) ; \
	fi
	@gh release view "v$(VERSION)"
	

