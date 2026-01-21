include help.mk

# Draw horizontal rules to separate prologue / epilogue from the main help body.
HELP_HR=yes
# Assign the "help" target to this category.
HELP_CATEGORY=Miscellaneous targets

#+ **Demo makefile for MakeHelp**.
#+
#+ Go to https://github.com/jin-gizmo/makehelp for more information.

#- *You are standing at the end of a road before a small brick building. Around*
#- *you is a forest. A small stream flows out of the building and down a gully.*
#-
#- (If you know, you know. If you don't, you've missed something that AI will
#- never give you.)

# ------------------------------------------------------------------------------
## Target deployment environment. Must be one of `dev` or `prod`.
env=

## Release tag.
tag=

## Platform architecture for build: `arm64` or `x86_64`.
arch:=$(shell arch)

restart=no

#@cat Primary targets

## Build some stuff.
#@opt arch tag
build:
	@echo Building for $(arch) ...

## Deploy some stuff. The *env* variable specifies the target environment.
## If *restart* is set to `yes` the system will be restarted after deployment.
#@req env tag
#@opt restart
deploy:	preflight build
	@echo Deploying to $(env) with restart=$(restart) ...

preflight:
	@echo Check everything is in order for deployment

#@cat Miscellaneous targets

## Delete build artefacts locally.
clean:
	@echo Cleaning build artefacts ...
