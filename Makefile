CLANG ?= clang
CFLAGS ?=
OS ?=

CFLAGS += -Os -g3 -Wall -Wextra -Wno-unused-parameter
ifneq ($(OS),Windows_NT) 
	# NOTE: clang on windows does not support fPIC
	CFLAGS += -fPIC
endif

INCLUDES += -Isrc/

INSTALL ?= install
PREFIX ?= /usr/local
LIBDIR = $(PREFIX)/lib
INCLUDEDIR = $(PREFIX)/include

all: src/libllhttp.a src/libllhttp.so

clean:
	rm -rf release/
	rm -rf src/

src/libllhttp.so: src/c/llhttp.o src/native/api.o \
		src/native/http.o
	$(CLANG) -shared $^ -o $@

src/libllhttp.a: src/c/llhttp.o src/native/api.o \
		src/native/http.o
	$(AR) rcs $@ src/c/llhttp.o src/native/api.o src/native/http.o

src/c/llhttp.o: src/c/llhttp.c
	$(CLANG) $(CFLAGS) $(INCLUDES) -c $< -o $@

src/native/%.o: ts-src/native/%.c src/llhttp.h ts-src/native/api.h \
		src/native
	$(CLANG) $(CFLAGS) $(INCLUDES) -c $< -o $@

src/llhttp.h: generate
src/c/llhttp.c: generate

src/native:
	mkdir -p src/native

release: generate
	mkdir -p release/src
	mkdir -p release/include
	cp -rf src/llhttp.h release/include/
	cp -rf src/c/llhttp.c release/src/
	cp -rf ts-src/native/*.c release/src/
	cp -rf ts-src/llhttp.gyp release/
	cp -rf ts-src/common.gypi release/
	cp -rf README.md release/
	cp -rf LICENSE-MIT release/

postversion: release
	git push
	git checkout release --
	cp -rf release/* ./
	rm -rf release
	git add include ts-src *.gyp *.gypi README.md LICENSE-MIT
	git commit -a -m "release: $(TAG)"
	git tag "release/v$(TAG)"
	git push && git push --tags
	git checkout master

generate:
	npx ts-node bin/generate.ts

install: src/libllhttp.a src/libllhttp.so
	$(INSTALL) src/llhttp.h $(DESTDIR)$(INCLUDEDIR)/llhttp.h
	$(INSTALL) src/libllhttp.a $(DESTDIR)$(LIBDIR)/libllhttp.a
	$(INSTALL) src/libllhttp.so $(DESTDIR)$(LIBDIR)/libllhttp.so

.PHONY: all generate clean release
