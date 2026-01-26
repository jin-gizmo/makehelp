include help.mk

#:cat You will not see my-target in this category

ifeq ($(VAR),value)
my-target:
	@echo "Building $@ with $(VAR) = value"
else
#:cat You will see my-target in this category
## Build *my-target* when *VAR* != `value`.
my-target:
	@echo "Building $@ with $(VAR) != value"
endif
