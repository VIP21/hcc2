#-----------------------------------------------------------------------
#
#  Makefile: Cuda clang demo Makefile for both amdgcn and nvptx targets.
#            amdgcn targets begin with gfx. nvptx targets begin with sm_
#
#  Run "make help" to see how to use this Makefile

TESTNAME = vectorAdd

ifeq ($(HCC2),)
  HCC2 = /opt/rocm/hcc2
endif
ifeq ($(LIBAMDGCN),)
  LIBAMDGCN = /opt/rocm/libamdgcn
endif
ifeq ($(CUDA),)
  CUDA = /usr/local/cuda
endif
ifeq ($(TARGET),)
  TARGET = sm_35
endif

INCS     = -I/usr/local/cuda/include -I/usr/local/cuda/samples/common/inc
CFLAGS   = -O3 --cuda-gpu-arch=$(TARGET)
CC       = $(HCC2)/bin/clang++

ifeq (,$(findstring gfx,$(TARGET)))
  LFLAGS = -L$(CUDA)/targets/x86_64-linux/lib -lcudart
  CCENV  = export LIBRARY_PATH=$(CUDA)/targets/x86_64-linux/lib:$(CUDA)/lib64;
else
  LFLAGS = -L/opt/rocm/hip/lib -lhip_hcc -L/opt/rocm/lib -lhc_am -L $(HCC2)/lib -lcugcn
  RUNENV = @export LD_LIBRARY_PATH=$(HCC2)/lib:/opt/rocm/hip/lib:/opt/rocm/lib;
endif

# ----- Demo compile and link in one step, no object code saved
$(TESTNAME): $(TESTNAME).cu
	$(CCENV) $(CC) $(CFLAGS) $(INCS) $(LFLAGS) $^ -o $@

run: $(TESTNAME)
	$(RUNENV) ./$(TESTNAME)

#  ----   Demo compile and link in two steps, object saved
$(TESTNAME).o: $(TESTNAME).cu
	$(CCENV)  $(CC)  -c $(CFLAGS) $(INCS) $^

obin:	$(TESTNAME).o
	$(CCENV)  $(CC) $(LFLAGS) $^ -o obin

run_obin: obin
	$(RUNENV) ./obin

#  ----   Demo compile to intermediates LLVMIR or assembly
$(TESTNAME).ll: $(TESTNAME).cu
	$(CCENV) $(CC)   -c -S -emit-llvm $(CFLAGS) $(INCS) $^

$(TESTNAME).s: $(TESTNAME).cu
	$(CCENV)  $(CC)  -c -S $(CFLAGS) $(INCS) $^

help:
	@echo
	@echo "Source: 		$(TESTNAME).cu"
	@echo "Application binary:    	$(TESTNAME)"
	@echo "Offload target		$(TARGET)"
	@echo "CUDA installation 	$(CUDA)"
	@echo "HCC2 compiler: 		$(CC)"
	@echo "Compile flags:		$(CFLAGS)"
	@echo "Includes:   $(INCS)"
	@echo "Link flags: $(LFLAGS)"
	@echo
	@echo "This Makefile supports these demos using these extra flags"
	@echo
	@echo " make $(TESTNAME).ll	// compile steps only       : -c -S -emit-llvm "
	@echo " make $(TESTNAME).s	// compile & backend steps  : -c -S "
	@echo " make $(TESTNAME).o	// compile, be, & assemble  : -c  "
	@echo " make obin         	// Link pass only           : "
	@echo " make run_obin     	// Execute obin "
	@echo
	@echo " make			// Build $(TESTNAME), all steps "
	@echo " make run		// Execute $(TESTNAME) "
	@echo
	@echo " make clean"
	@echo " make help"
	@echo
	@echo "Environment variables to control compile & execution:"
	@echo "  TARGET=<arch>  offload target, default=sm_35"
	@echo "  CUDA=<dir>  CUDA install dir, default=/usr/local/cuda"
	@echo "  HCC2=<dir>  HCC2 install dir, default=/opt/rocm/hcc2"
	@echo "  LIBAMDGCN=<dir>  device libs, default=/opt/rocm/libamdgcn"
	@echo

# Cleanup anything this makefile can create
clean:
	@[ -f ./$(TESTNAME) ] && rm ./$(TESTNAME) ; true
	@[ -f ./obin ] && rm ./obin ; true
	@[ -f ./$(TESTNAME).ll ] && rm *.ll ; true
	@[ -f ./$(TESTNAME).o ] && rm *.o ; true
	@[ -f ./$(TESTNAME).s ] && rm *.s ; true
