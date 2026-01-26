# Repeated targets

include help.mk

## Rep1 - first comment.
#:req a b
rep1: dep1

#:cat This should not appear because rep1 is already in Targets

## Rep1 - second comment.
#:opt a c
rep1: dep2
	@echo Hello

#:opt dep2
dep2:
