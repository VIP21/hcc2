include ../Makefile.defs

TESTNAME        = liba
TESTSRC_MAIN    = main.c
TESTSRC_AUX     = func_1v.o func_2v.o func_3v.o
TESTSRC_LIBA	= liba.a
TESTSRC_ALL     = $(TESTSRC_MAIN) $(TESTSRC_LIBA)
SCRIPT_INIT	= liba_init.sh

CLANG           = clang
OMP_BIN         = $(HCC2)/bin/$(CLANG)
CC              = $(OMP_BIN) $(VERBOSE)
EXTRA_CFLAGS    =
EXTRA_LDFLAGS	= -lm
EXTRA_OMP_FLAGS =

include ../Makefile.rules
