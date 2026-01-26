# Repeated targets but this time the category is decided by the second
# occurrence because it has associated doco.

include help.mk

#:cat This should not appear because first occurrence has no doco

#:req a b
rep1: dep1

#:cat This should appear

## Rep2 - The one and only comment.
#:opt a c
rep1: dep2
	@echo Hello

#:opt dep2
dep2:
