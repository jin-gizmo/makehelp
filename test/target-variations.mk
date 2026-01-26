include help.mk

var:=value
## A list of targets
tgtlist=t1 t2
blade=vorpal
foe=Jabberwock

## This one is `target`.
target:
	echo Target is $@

## This one is `target1`.
target1:

## This one is $(tgtlist).
$(tgtlist):

## This one is an `archive-member`.
(archive-member):

## This one is `$\(var\)` --> `$(var)`
#:req foe
$(var):


## This one has a space after the name.
space-after :

## This one has targets a, b and c.
a b c:	target
	echo This is $@

## Beware the Jabberwock, my son! \
   The jaws that bite, the claws that catch! \
   Beware the Jubjub bird, and shun \
   The frumious Bandersnatch!
#:opt blade
beamish \
	\
	boy: \
		$(var) \
		YY \
		twas \
		brillig \
		and \
		the \
		slithy \
		toves \
		did \
		gyre \
		and \
		gimble \
		in \
		the \
		wabe \
		all \
		mimsy \
		were \
		the \
		borogroves \
		and \
		the \
		mome \
		raths \
		outgrabe

