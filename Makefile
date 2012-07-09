##############################################################################
# GNU Makefile for the primesieve console application (read doc/INSTALL)
# and the primesieve C++ library (read doc/LIBPRIMESIEVE)
#
# Author:          Kim Walisch
# Contact:         kim.walisch@gmail.com
# Created:         10 July 2010
# Last modified:   09 July 2012
#
# Project home:    http://primesieve.googlecode.com
##############################################################################

TARGET = primesieve
SOEDIR = src/soe
CONDIR = src/console
BINDIR = bin
LIBDIR = lib

BIN_OBJECTS = $(BINDIR)/WheelFactorization.o \
  $(BINDIR)/PreSieve.o \
  $(BINDIR)/EratSmall.o \
  $(BINDIR)/EratMedium.o \
  $(BINDIR)/EratBig.o \
  $(BINDIR)/SieveOfEratosthenes.o \
  $(BINDIR)/PrimeNumberFinder.o \
  $(BINDIR)/PrimeSieve.o \
  $(BINDIR)/ParallelPrimeSieve.o \
  $(BINDIR)/test.o \
  $(BINDIR)/main.o

LIB_OBJECTS = $(LIBDIR)/WheelFactorization.o \
  $(LIBDIR)/PreSieve.o \
  $(LIBDIR)/EratSmall.o \
  $(LIBDIR)/EratMedium.o \
  $(LIBDIR)/EratBig.o \
  $(LIBDIR)/SieveOfEratosthenes.o \
  $(LIBDIR)/PrimeNumberFinder.o \
  $(LIBDIR)/PrimeSieve.o \
  $(LIBDIR)/ParallelPrimeSieve.o

#-----------------------------------------------------------------------------
# set the compiler, use g++ if available
#-----------------------------------------------------------------------------

ifneq ($(shell command -v g++ 2> /dev/null),)
  CXX = g++
  CXXFLAGS = -Wall -O2
else
  CXXFLAGS = -O2
endif

#-----------------------------------------------------------------------------
# primesieve requires OpenMP 3.0 (2008) or later
# which is supported by GCC 4.4 or later
#-----------------------------------------------------------------------------

ifneq ($(shell $(CXX) --version 2>&1 | head -1 | grep -iE 'GCC|G\+\+'),)
  GCC_MAJOR = $(shell $(CXX) -dumpversion 2>&1 | cut -d'.' -f1)
  GCC_MINOR = $(shell $(CXX) -dumpversion 2>&1 | cut -d'.' -f2)
  ifneq ($(shell if [ $$(($(GCC_MAJOR)*100+$(GCC_MINOR))) -ge 404 ]; \
      then echo GCC 4.4 or later; fi),)
    CXXFLAGS += -fopenmp
  endif
endif

#-----------------------------------------------------------------------------
# set the installation directory (read doc/LIBPRIMESIEVE)
#-----------------------------------------------------------------------------

ifneq ($(shell uname | grep -i linux),)
  PREFIX = /usr/local
else
  PREFIX = /usr
endif

#-----------------------------------------------------------------------------
# check if the user wants to build a shared library instead
# of a static one e.g. `make SHARED=yes`
#-----------------------------------------------------------------------------

ifeq ($(SHARED),)
  LIBPRIMESIEVE = lib$(TARGET).a
else
  ifneq ($(shell uname | grep -i darwin),)
    SOFLAG = -dynamiclib
    LIBPRIMESIEVE = lib$(TARGET).dylib
  else
    SOFLAG = -shared
    LIBPRIMESIEVE = lib$(TARGET).so
    FPIC = -fPIC
  endif
endif

#-----------------------------------------------------------------------------
# build the primesieve console application (read doc/INSTALL)
#-----------------------------------------------------------------------------

.PHONY: bin dir_bin

BIN_CXXFLAGS = $(CXXFLAGS)
ifneq ($(L1_DCACHE_SIZE),)
  BIN_CXXFLAGS += -DL1_DCACHE_SIZE=$(L1_DCACHE_SIZE)
endif

bin: dir_bin $(BIN_OBJECTS)
	$(CXX) $(BIN_CXXFLAGS) -o $(BINDIR)/$(TARGET) $(BIN_OBJECTS)

$(BINDIR)/%.o: $(SOEDIR)/%.cpp
	$(CXX) $(BIN_CXXFLAGS) -o $@ -c $<

$(BINDIR)/%.o: $(CONDIR)/%.cpp
	$(CXX) $(BIN_CXXFLAGS) -o $@ -c $<

dir_bin:
	@mkdir -p $(BINDIR)

#-----------------------------------------------------------------------------
# build libprimesieve (read doc/LIBPRIMESIEVE)
#-----------------------------------------------------------------------------

.PHONY: lib dir_lib

LIB_CXXFLAGS = $(CXXFLAGS)
ifneq ($(FPIC),)
  LIB_CXXFLAGS += $(FPIC)
endif
ifneq ($(L1_DCACHE_SIZE),)
  LIB_CXXFLAGS += -DL1_DCACHE_SIZE=$(L1_DCACHE_SIZE)
endif

lib: dir_lib $(LIB_OBJECTS)
ifeq ($(SHARED),)
	ar rcs $(LIBDIR)/$(LIBPRIMESIEVE) $(LIB_OBJECTS)
else
	$(CXX) $(LIB_CXXFLAGS) $(SOFLAG) -o $(LIBDIR)/$(LIBPRIMESIEVE) $(LIB_OBJECTS)
endif

$(LIBDIR)/%.o: $(SOEDIR)/%.cpp
	$(CXX) $(LIB_CXXFLAGS) -o $@ -c $<

dir_lib:
	@mkdir -p $(LIBDIR)

#-----------------------------------------------------------------------------
# common targets (all, clean, install, uninstall)
#-----------------------------------------------------------------------------

.PHONY: all clean install uninstall

all: bin lib

clean:
ifneq ($(wildcard $(BINDIR)/$(TARGET)* $(BINDIR)/*.o),)
	rm -f $(BINDIR)/$(TARGET) $(BINDIR)/*.o
	@rm -f $(BINDIR)/$(TARGET).exe
endif
ifneq ($(wildcard $(LIBDIR)/lib$(TARGET).* $(LIBDIR)/*.o),)
	rm -f $(wildcard $(LIBDIR)/lib$(TARGET).*) $(LIBDIR)/*.o
endif

# needs root privileges (sudo make install)
install:
ifneq ($(wildcard $(BINDIR)/$(TARGET)*),)
	@mkdir -p $(PREFIX)/bin
	cp -f $(BINDIR)/$(TARGET) $(PREFIX)/bin
endif
ifneq ($(wildcard $(LIBDIR)/lib$(TARGET).*),)
	@mkdir -p $(PREFIX)/include/primesieve/soe
	@mkdir -p $(PREFIX)/lib
	cp -f src/soe/*PrimeSieve.h $(PREFIX)/include/primesieve/soe
	cp -f $(wildcard $(LIBDIR)/lib$(TARGET).*) $(PREFIX)/lib
  ifneq ($(wildcard $(LIBDIR)/lib$(TARGET).so),)
    ifneq ($(shell command -v ldconfig 2> /dev/null),)
		ldconfig $(PREFIX)/lib
    endif
  endif
endif

# needs root privileges (sudo make uninstall)
uninstall:
ifneq ($(wildcard $(PREFIX)/bin/$(TARGET)*),)
	rm -f $(PREFIX)/bin/$(TARGET)
	@rm -f $(PREFIX)/bin/$(TARGET).exe
endif
ifneq ($(wildcard $(PREFIX)/include/primesieve),)
	rm -rf $(PREFIX)/include/primesieve
endif
ifneq ($(wildcard $(PREFIX)/lib/lib$(TARGET).*),)
  ifneq ($(wildcard $(PREFIX)/lib/lib$(TARGET).so),)
	rm -f $(wildcard $(PREFIX)/lib/lib$(TARGET).so)
    ifneq ($(shell command -v ldconfig 2> /dev/null),)
		ldconfig $(PREFIX)/lib
    endif
  else
	rm -f $(wildcard $(PREFIX)/lib/lib$(TARGET).*)
  endif
endif

#-----------------------------------------------------------------------------
# `make check` runs various sieving tests to assure that the
# compiled primesieve binary produces correct results
#-----------------------------------------------------------------------------

.PHONY: check test

check test: bin
	$(BINDIR)/./$(TARGET) -test

#-----------------------------------------------------------------------------
# Makefile help menu
#-----------------------------------------------------------------------------

.PHONY: help

help:
	@echo ----------------------------------------------------
	@echo ---------------- Makefile help menu ----------------
	@echo ----------------------------------------------------
	@echo "make                                   Builds the primesieve console application using g++ (DEFAULT)"
	@echo "make CXX=compiler CXXFLAGS=\"options\"   Specify a custom C++ compiler"
	@echo "make L1_DCACHE_SIZE=KB                 Specify the CPU's L1 data cache size (read doc/INSTALL)"
	@echo "make check                             Tests the compiled primesieve binary"
	@echo "make clean                             Cleans the output directories (./bin, ./lib)"
	@echo "make lib                               Builds static libprimesieve.a to ./lib"
	@echo "make lib SHARED=yes                    Builds shared libprimesieve.(so|dylib) to ./lib"
	@echo "sudo make install                      Installs primesieve and libprimesieve (to /usr/local or /usr)"
	@echo "sudo make install PREFIX=path          Specify a custom installation path"
	@echo "sudo make uninstall                    Completely removes primesieve and libprimesieve"
	@echo "make help                              Prints this help menu"
