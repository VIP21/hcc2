HCC2_BIN=`make help | grep "LLVM Tool Chain:" | sed "s/LLVM Tool Chain:\s*//"`
TESTSRC_OBJ=`grep "^TESTSRC_AUX" Makefile | sed "s/TESTSRC_AUX\s*=\s*//"`
TESTSRC_LIBA=`grep "^TESTSRC_LIBA" Makefile | sed "s/TESTSRC_LIBA\s*=\s*//"`

make -f Makefile.init liba_init.o

echo $HCC2_BIN/llvm-ar r $TESTSRC_LIBA $TESTSRC_OBJ
$HCC2_BIN/llvm-ar r $TESTSRC_LIBA $TESTSRC_OBJ

echo $HCC2_BIN/llvm-ranlib $TESTSRC_LIBA
$HCC2_BIN/llvm-ranlib $TESTSRC_LIBA
