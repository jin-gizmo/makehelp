
# This one has a very long list of args for one target.

include help.mk

## Target deployment environment: `dev` or `prod`.
env=

## Platform architecture for build: `arm64` or `x86_64`.
arch:=$(shell echo arm64)

## Release tag.
tag=

restart=no

## Build some stuff.
build:
	@echo Building for $(arch) ...

## Deploy some stuff.
#:req one two three four five size seven eight nine ten eleven twelve thirteen fourteen=14
#:opt fifteen=15 sixteen=16 seventeen eighteen nineteen twenty
deploy:	preflight build
	@echo Deploying to $(env) with restart=$(restart) ...

preflight:
	@echo Check everything is in order for deployment

## Delete build artefacts locally.
clean:
	@echo Cleaning build artefacts ...
