# Multiple targets in the one declaration but with individual help.

include help.mk

## Build target *a*.
a:

## Build target *b*.
b:

## Build target *c*.
c:

a b c:
	@echo Build $@
