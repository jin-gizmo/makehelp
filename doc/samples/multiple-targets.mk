include help.mk

## Check spelling.
spell:
## Build the documentation and preview locally.
preview:
## Build and publish the documentation.
publish:

spell preview publish:
	$(MAKE) -C doc $(MAKECMDGOALS)
