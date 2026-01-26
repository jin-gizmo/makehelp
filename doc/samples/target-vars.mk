#+ **Demo makefile for MakeHelp.**
#+
#+ This example shows handling of global vs target-specific variables.

include help.mk

#:vcat Globals

## The value of *var1* here should be `global1`.
var1=global1
## The value of *var2* here should be `global2`.
var2=global2

## *var1* and *var2* have target specific overrides here. The *child1* var
## inherits it's value from the *child* dependency.
##
## *var1* should have a value of `local1` not `global1`.
##
## *var2* should have a value of `local2` not `global2`.
##
## *var3* should be empty, not `global3`.
#:req var1
#:opt var2=$(var2)

parent: var1 := $(shell echo local1)
parent: var2=local2
parent:	child
	@echo "var1=$(var1) var2=$(var2) var3=$(var3)"

## Child target.
#:req child1=adopted
child:
