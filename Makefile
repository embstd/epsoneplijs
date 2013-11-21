# Unix

CC=gcc
CFLAGS_EXTRA_DEFS=-DHAVE_KERNEL_USB_DEVICE -DHAVE_LIBUSB -D_SVID_SOURCE  -DHAVE_LIBIEEE1284 -DHAVE_NULLTRANS
CFLAGS= $(CFLAGS_EXTRA_DEFS) -g -O2 -Wall -ansi -pedantic -Wmissing-prototypes
LDPATH=-L./libusb/.libs -L./libieee1284/.libs 
LDLIBS=-lusb -lieee1284 
EXTRA_DEPS=libusb/.libs/libusb.a libieee1284/.libs/libieee1284.a 
EXTRA_BINS=  
EXTRA_OBJS=epl_utils_kusb.o epl_utils_libusb.o epl_utils_libieee1284.o epl_57interpret.o epl_59interpret.o epl_62interpret.o epl_utils_null.o
OBJ=.o
EXE=

# todo: this needs to be .dylib on OS X - write a test
SHARED_LDFLAGS=-shared
SHARED_OBJ=.so
#SHARED_LDFLAGS=-dylib
#SHARED_OBJ=.dylib

FE=-o 
IJS_EXEC_SERVER=ijs_exec_unix$(OBJ)
RM=rm -f
AR=ar
ARFLAGS=qc
RANLIB=ranlib

# Installation paths
prefix=/usr/local
exec_prefix=${prefix}
bindir=${exec_prefix}/bin
libdir=${exec_prefix}/lib
includedir=${prefix}/include

pkgincludedir=$(includedir)/ijs

INSTALL = /usr/bin/install -c

IJS_COMMON_OBJ=ijs$(OBJ)

all:	ijs_server_epsonepl$(EXE) $(EXTRA_BINS) 

LIB_OBJS=ijs$(OBJ) ijs_client$(OBJ) ijs_server$(OBJ) $(IJS_EXEC_SERVER)

EPL_BID_OBJS=epl_write$(OBJ) epl_bid_utils$(OBJ) epl_bid_replies$(OBJ) epl_status$(OBJ) epl_time$(OBJ)

EPL_OBJS=epl_job_header$(OBJ) epl_page_header$(OBJ) epl_page_footer$(OBJ) \
           epl_job_footer$(OBJ) epl_print_stripe$(OBJ) epl_poll$(OBJ) epl_compress$(OBJ) \
          $(EPL_BID_OBJS) $(EXTRA_OBJS)        

EPL_HEADERS=epl_bid.h  epl_compress.h  epl_config.h  epl_job.h  epl_time.h 

libijs.a:	$(LIB_OBJS)
	rm -f $@
	$(AR) $(ARFLAGS) $@ $^
	$(RANLIB) $@

# Note: this builds both the server and client into a single library. Logically, it
# makes sense to separate them, but they're small enough to make this probably
# not worthwhile.
libijs$(SHARED_OBJ):	$(LIB_OBJS)
	$(CC) $(SHARED_LDFLAGS) $^ -o $@

ijs_client_example$(EXE):	ijs_client_example$(OBJ) ijs_client$(OBJ) $(IJS_COMMON_OBJ) $(IJS_EXEC_SERVER)
	$(CC) $(CFLAGS) $(FE)ijs_client_example$(EXE) ijs_client_example$(OBJ) ijs_client$(OBJ) $(IJS_COMMON_OBJ) $(IJS_EXEC_SERVER) 

ijs_server_example$(EXE):	ijs_server_example$(OBJ) ijs_server$(OBJ) $(IJS_COMMON_OBJ)
	$(CC) $(CFLAGS) $(FE)ijs_server_example$(EXE) ijs_server_example$(OBJ) ijs_server$(OBJ) $(IJS_COMMON_OBJ)

ijs_server_epsonepl$(EXE): ijs_server_epsonepl$(OBJ) ijs_server$(OBJ) $(IJS_COMMON_OBJ) $(EPL_OBJS) $(EXTRA_DEPS) $(EPL_HEADERS)
	$(CC) $(CFLAGS) $(FE)ijs_server_epsonepl$(EXE) ijs_server_epsonepl$(OBJ) ijs_server$(OBJ) $(EPL_OBJS) $(IJS_COMMON_OBJ) $(LDPATH) $(LDLIBS)

testlibusb$(OBJ): libusb/tests/testlibusb.c
	$(CC) $(CFLAGS) -c -I./libusb -o testlibusb$(OBJ) libusb/tests/testlibusb.c

testlibusb$(EXE): testlibusb$(OBJ) libusb/.libs/libusb.a
	$(CC) $(CFLAGS) $(FE)testlibusb$(EXE) testlibusb$(OBJ) $(LDPATH) $(LDLIBS)

#test5700lusb doesn't need a .o.c target as the source is in the same directory.
test5700lusb$(EXE): test5700lusb$(OBJ) libusb/.libs/libusb.a
	$(CC) $(CFLAGS) $(FE)test5700lusb$(EXE) test5700lusb$(OBJ) $(LDPATH) $(LDLIBS)

# libusb.spec is a generated file that interfers with rpm building. Therefore removing as soon as possible 
libusb/.libs/libusb.a:
	(cd libusb ; ./autogen.sh ; ./configure --disable-shared --disable-build-docs; make)
	$(RM) libusb/libusb.spec


# libieee1284.spec is a generated file that interfers with rpm building. Therefore removing as soon as possible 
libieee1284/.libs/libieee1284.a:
	(cd libieee1284 ; ./autogen.sh ; ./configure --disable-shared ; make)
	$(RM) libieee1284/libieee1284.spec

common_clean:
	$(RM) *$(OBJ) ijs_client_example$(EXE) ijs_server_example$(EXE) ijs_server_epsonepl$(EXE) *.epl

clean: common_clean
	$(RM) *~ gmon.out core ijs_spec.log ijs_spec.tex ijs_spec.aux libijs.a libijs$(SHARED_OBJ) config.cache config.log config.status ijs-config testlibusb$(EXE) test5700lusb$(EXE) libieee1284/lib1284.spec 
	[ -d libusb ] && (cd libusb ; make clean) || true
	[ -d libieee1284 ] && (cd libieee1284 ; make clean) || true

install: all
	$(INSTALL) ijs_server_epsonepl$(EXE) -c $(bindir)/ijs_server_epsonepl$(EXE)

uninstall:
	$(RM) $(bindir)/ijs_server_epsonepl$(EXE)

ijs_spec.ps:	ijs_spec.sgml
	# We don't use db2pdf because it can't handle embedded .eps
	db2ps ijs_spec.sgml

ijs_spec.pdf:	ijs_spec.ps
	ps2pdf ijs_spec.ps
