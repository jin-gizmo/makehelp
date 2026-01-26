# Double colon targets

include help.mk

## Dep1 depends on dep2.
## Dep1 - first comment.
#:req dep1-req1 dep1-req2
dep1:: dep2

## Dep1 - second comment.
#:opt dep1-opt1 dep1-opt3
dep1::
	@echo Hello

## Dep2 has no dependencies.
#:opt dep2-opt=some-val
dep2:

## Main depends on dep1.
main: dep1
