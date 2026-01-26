
include help.mk

#+ The value of *var1* here is `$(var1)`. It should be `global1`.
#:vcat Globals

## This is the global version of *var1*.
var1=global1

## This is the global version of *var2*.
var2=global2

## This is the global version of *var3*.
var3=global3

parent: var1 := $(shell echo local1)

parent: var2=local2

parent: var3:=

## *var1* should have a value of `local1` not `global1`. Perceived value is `$(var1)`.
##
## *var2* should have a value of `local2` not `global2`. Perceived value is `$(var2)`.
##
## *var3* should be empty, not `global3`.
#:req var1
#:opt var2=$(var2)
#:opt var3

parent:	child
	@echo "var1=$(var1) var2=$(var2) var3=$(var3)"

## Child target.
#:req child1=adopted
child:


