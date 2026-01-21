
# This one has a very long list of args for one target.

include help.mk

## Target deployment environment: `dev` or `prod`.
env=

## Platform architecture for build: `arm64` or `x86_64`.
arch:=$(shell arch)

## Release tag.
tag=

restart=no

## Build some stuff.
build:
	@echo Building for $(arch) ...

## Deploy some stuff.
#@req one two three four five size seven eight nine ten eleven twelve thirteen fourteen
#@opt fifteen sixteen seventeen eighteen nineteen twenty
deploy:	preflight build
	@echo Deploying to $(env) with restart=$(restart) ...

preflight:
	@echo Check everything is in order for deployment

## Delete build artefacts locally.
clean:
	@echo Cleaning build artefacts ...
