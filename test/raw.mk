# Demo makefile for MakeHelp.

include help.mk

env=
arch:=$(shell arch)
restart=no

build:
	@echo Building for $(arch) ...

deploy:
	@echo Deploying to $(env) with restart=$(restart) ...

preflight:
	@echo Check everything is in order for deployment

clean:
	@echo Cleaning build artefacts ...
