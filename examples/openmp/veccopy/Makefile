#-----------------------------------------------------------------------
#
#  Makefile: Cuda clang demo Makefile for both amdgcn and nvptx targets.
#            amdgcn targets begin with gfx. nvptx targets begin with sm_
#
#  Run "make help" to see how to use this Makefile

TESTNAME = veccopy 
TESTSRC  = veccopy.c

ifeq ($(HCC2),)
  HCC2 = /opt/rocm/hcc2
endif
ifeq ($(LIBAMDGCN),)
  LIBAMDGCN = /opt/rocm/libamdgcn
endif
ifeq ($(OMPRT),)
  OMPRT = $(HCC2)
endif
ifeq ($(ATMI),)
  ATMI = $(HCC2)
endif

ifeq ($(CUDA),)
  CUDA = /usr/local/cuda
endif

ifeq ($(OFFLOAD_DEBUG),1)
  $(info    DEBUG Mode ON)
  DEBUG   = -debug
  SET_DEVICE_DEBUG = DEVICE_DEBUG=1
endif

ifeq ($(VERBOSE),1)
  $(info    Compilation VERBOSE Mode ON)
  VERBOSE = -v
endif

OMPRT_INC    = $(OMPRT)/include
OMPRT_LIB    = $(OMPRT)/lib$(DEBUG)
OMPRT_LIB_BC = $(OMPRT)/lib$(DEBUG)/libdevice

ATMI_LIB     = $(ATMI)/lib$(DEBUG)
ATMI_LIB_BC  = $(ATMI)/lib$(DEBUG)/libdevice

CC           = $(HCC2)/bin/clang

UNAMEP=$(shell uname -p)

ifeq ($(HOST_TARGET),)
  HOST_TARGET = $(UNAMEP)-pc-linux-gnu
endif

ifeq ($(DEVICE_ARCH),)
  DEVICE_ARCH = $(shell $(HCC2)/bin/mygpu)
endif

ifeq ($(findstring gfx,$(DEVICE_ARCH)),)
  DEVICE_TARGET = nvptx64-nvidia-cuda
else
  DEVICE_TARGET = amdgcn-amd-amdhsa
endif

CFLAGS = -O3 -target $(HOST_TARGET) -fopenmp -fopenmp-targets=$(DEVICE_TARGET) -Xopenmp-target=$(DEVICE_TARGET) -march=$(DEVICE_ARCH) -I$(OMPRT_INC) 
LFLAGS = -L$(OMPRT_LIB) -L$(OMPRT_LIB_BC)

ifeq ($(findstring amdgcn,$(DEVICE_TARGET)),)

  CFLAGS += -I$(CUDA)/include 
  LFLAGS += -L$(CUDA)/targets/$(UNAMEP)-linux/lib -lcudart
  CCENV  = env LIBRARY_PATH=$(OMPRT_LIB_BC):$(OMPRT_LIB):$(CUDA)/targets/$(UNAMEP)-linux/lib:$(LIBRARY_PATH) PATH=$(HCC2)/bin:$(PATH)
  RUNENV = env LD_LIBRARY_PATH=$(OMPRT_LIB):$(CUDA)/targets/$(UNAMEP)-linux/lib:$(LD_LIBRARY_PATH) $(SET_DEVICE_DEBUG)

else

  CCENV  = env LIBRARY_PATH=$(OMPRT_LIB_BC):$(OMPRT_LIB):$(ATMI_LIB_BC):$(ATMI_LIB):$(LIBAMDGCN)/$(DEVICE_ARCH)/lib:$(LIBRARY_PATH) PATH=$(HCC2)/bin:$(PATH)
  RUNENV = env LD_LIBRARY_PATH=$(OMPRT_LIB):$(ATMI_LIB):$(LD_LIBRARY_PATH) $(SET_DEVICE_DEBUG)

endif

CFLAGS += $(EXTRA_CFLAGS)

# ----- Demo compile and link in one step, no object code saved
$(TESTNAME): $(TESTSRC)
	$(CCENV)  $(CC) $(CFLAGS) $(LFLAGS) $^ -o $@

run: $(TESTNAME)
	$(RUNENV) ./$(TESTNAME) 2>&1 | tee $@.log

#  ----   Demo compile and link in two steps, object saved
.o: $(TESTSRC)
	$(CCENV)  $(CC) -c $(CFLAGS) $^

obin:	.o
	$(CCENV)  $(CC) $(CFLAGS) $(LFLAGS) $(addsuffix .o, $(basename $(TESTSRC))) -o obin

run_obin: obin
	$(RUNENV) ./obin 2>&1 | tee $@.log

#  ----   Demo compile to intermediates LLVMIR or assembly
.ll: $(TESTSRC)
	$(CCENV)  $(CC) -c -S -emit-llvm $(CFLAGS) $^

.s: $(TESTSRC)
	$(CCENV)  $(CC) -c -S $(CFLAGS) $^

help:
	@echo
	@echo "Source[s]:		$(TESTSRC)"
	@echo "Application binary:    	$(TESTNAME)"
	@echo "Offload target		$(DEVICE_TARGET)"
	@echo "CUDA installation 	$(CUDA)"
	@echo "HCC2 compiler: 		$(CC)"
	@echo "Compile flags:		$(CFLAGS)"
	@echo "Link flags:		$(LFLAGS)"
	@echo
	@echo "This Makefile supports these demos using these extra flags"
	@echo
	@echo " make .ll		// compile steps only       : -c -S -emit-llvm "
	@echo " make .s		// compile & backend steps  : -c -S "
	@echo " make .o		// compile, be, & assemble  : -c  "
	@echo " make obin         	// Link pass only           : "
	@echo " make run_obin     	// Execute obin "
	@echo
	@echo " make			// Build $(TESTNAME), all steps "
	@echo " make run		// Execute $(TESTNAME) "
	@echo
	@echo " make clean"
	@echo " make clean_log"
	@echo " make help"
	@echo
	@echo "Environment variables to control compile & execution:"
	@echo "  DEVICE_TARGET=<target>  offload target, default=amdgcn--cuda"
	@echo "  DEVICE_ARCH=<arch>      offload sub-target, default=gfx803"
	@echo "  CUDA=<dir>              CUDA install dir, default=/usr/local/cuda"
	@echo "  HCC2=<dir>              HCC2 install dir, default=/opt/rocm/hcc2"
	@echo "  LIBAMDGCN=<dir>         device libs, default=/opt/rocm/libamdgcn"
	@echo
	@echo "Auxiliary Environment variables to control compile & execution:"
	@echo "  EXTRA_CFLAGS=<args>   compilation extra arguments"
	@echo "  OFFLOAD_DEBUG=n       if n=1, compile and run in Debug mode"
	@echo "  VERBOSE=n             if n=1, add verbose output"
	@echo "  UNAMEP=<arch>         host arch, default=x86_64"
	@echo "  HOST_TARGET=<target>  host target, default=x86_64-pc-linux-gnu"
	@echo "  ATMI=<dir>            ATMI install dir, default=$(HCC2)"
	@echo "  OMPRT=<dir>           OMPRT install dir, default=$(HCC2)"
	@echo

# Cleanup anything this makefile can create
clean:
	rm -f $(TESTNAME) obin *.ll *.s *.o *.log

clean_log:
	rm -f *.log
