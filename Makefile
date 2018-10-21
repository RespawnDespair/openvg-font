ifdef RPISDK
CROSS_COMPILE ?= arm-linux-gnueabihf-
endif

CC = $(CROSS_COMPILE)gcc
CCOPTS = -std=gnu89 -Wall -Wextra -Wconversion -Wdouble-promotion -Wshadow -Wno-sign-conversion

ifdef DEBUG
CCOPTS += -O0 -g
else
CCOPTS += -O2
endif

INCLUDEFLAGS=-I$(RPISDK)/opt/vc/include -I$(RPISDK)/opt/vc/include/interface/vmcs_host/linux -I$(RPISDK)/opt/vc/include/interface/vcos/pthreads -fPIC
LIBFLAGS=-L$(RPISDK)/opt/vc/lib -lEGL -lGLESv2 -ljpeg -lpng -lfreetype -lfontconfig -lz
FONTLIB=/usr/share/fonts/truetype/dejavu
FONTFILES=DejaVuSans.inc DejaVuSansMono.inc

all:	font2openvg fonts library

libshapes.o:	libshapes.c shapes.h fontinfo.h fontsystem.h fonts
	$(CC) $(CCOPTS) $(INCLUDEFLAGS) -c libshapes.c

fontsystem.o:	fontsystem.c fontinfo.h fontsystem.h
	$(CC) $(CCOPTS) $(INCLUDEFLAGS) -I/usr/include/freetype2 -c fontsystem.c

gopenvg:	openvg.go
	go install .

oglinit.o:	oglinit.c
	$(CC) $(CCOPTS) $(INCLUDEFLAGS) -c oglinit.c

font2openvg:	fontutil/font2openvg.cpp
	g++ -I/usr/include/freetype2 fontutil/font2openvg.cpp -o font2openvg -lfreetype

fonts:	$(FONTFILES)

DejaVuSans.inc: font2openvg $(FONTLIB)/DejaVuSans.ttf
	./font2openvg $(FONTLIB)/DejaVuSans.ttf DejaVuSans.inc DejaVuSans

DejaVuSansMono.inc: font2openvg $(FONTLIB)/DejaVuSansMono.ttf
	./font2openvg $(FONTLIB)/DejaVuSansMono.ttf DejaVuSansMono.inc DejaVuSansMono

clean:
	rm -f *.o *.inc *.so font2openvg *.c~ *.h~
	indent -linux -c 60 -brf -l 132  libshapes.c oglinit.c fontsystem.c shapes.h fontinfo.h

library: oglinit.o libshapes.o fontsystem.o
	$(CC) $(LIBFLAGS) -shared -o libshapes.so -Wl,-soname,libshapes.so.2.0.0 oglinit.o libshapes.o fontsystem.o

install:
	install -m 755 -p font2openvg /usr/bin/
	install -m 755 -p libshapes.so /usr/lib/libshapes.so.2.0.0
	strip --strip-unneeded /usr/lib/libshapes.so.2.0.0
	ln -f -s /usr/lib/libshapes.so.2.0.0 /usr/lib/libshapes.so
	ldconfig
	install -m 644 -p shapes.h /usr/include/
	install -m 644 -p fontinfo.h /usr/include/

uninstall:
	rm -f /usr/bin/font2openvg
	rm -f /usr/lib/libshapes.so.2.0.0 /usr/lib/libshapes.so
	rm -f /usr/include/shapes.h /usr/include/fontinfo.h
