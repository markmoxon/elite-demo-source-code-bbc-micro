BEEBASM?=beebasm
PYTHON?=python

# A make command with no arguments will build the source disc variant with
# encrypted binaries, checksums enabled, the standard commander and crc32
# verification of the game binaries
#
# Optional arguments for the make command are:
#
#   verify=no           Disable crc32 verification of the game binaries
#
# So, for example:
#
#   make variant=text-sources commander=max encrypt=no verify=no
#
# will build an unencrypted text sources variant with a maxed-out commander
# and no crc32 verification
#
# The following variables are written into elite-build-options.asm depending on
# the above arguments, so they can be passed to BeebAsm:
#
# _VERSION
#   1 = BBC Micro demo
#
# _VARIANT
#   1 = Demo disc
#
# _MAX_COMMANDER
#   FALSE = Standard commander
#
# _REMOVE_CHECKSUMS
#   FALSE = Enable checksum routines
#
# _MATCH_ORIGINAL_BINARIES
#   TRUE  = Match binaries to released version (i.e. fill workspaces with noise)
#
# _DISC
#   TRUE  = Build for loading from disc
#
# _PROT
#   FALSE = Do not apply block-level tape protection
#
# The encrypt and verify arguments are passed to the elite-checksum.py and
# crc32.py scripts, rather than BeebAsm

max-commander=FALSE

unencrypt=
remove-checksums=FALSE
match-original-binaries=TRUE
protect-tape=-p
prot=TRUE
tape-or-disc=
build-for-disc=TRUE
protect-tape=
prot=FALSE

variant-number=1
suffix=-demonstration-disc-flicker-free
folder=demo

.PHONY:all
all:
	echo _VERSION=0 > 1-source-files/main-sources/elite-build-options.asm
	echo _VARIANT=$(variant-number) >> 1-source-files/main-sources/elite-build-options.asm
	echo _REMOVE_CHECKSUMS=$(remove-checksums) >> 1-source-files/main-sources/elite-build-options.asm
	echo _MAX_COMMANDER=$(max-commander) >> 1-source-files/main-sources/elite-build-options.asm
	echo _DISC=$(build-for-disc) >> 1-source-files/main-sources/elite-build-options.asm
	echo _PROT=$(prot) >> 1-source-files/main-sources/elite-build-options.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-source.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-bcfs.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	$(PYTHON) 2-build-files/elite-checksum.py $(unencrypt) $(tape-or-disc) $(protect-tape)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm -do 5-compiled-game-discs/elite$(suffix).ssd -opt 3 -title "E L I T E"
ifneq ($(verify), no)
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries/$(folder) 3-assembled-output
endif

.PHONY:b2
b2:
	curl -G "http://localhost:48075/reset/b2"
	curl -H "Content-Type:application/binary" --upload-file "5-compiled-game-discs/elite$(suffix).ssd" "http://localhost:48075/run/b2?name=elite-demo$(suffix).ssd"
