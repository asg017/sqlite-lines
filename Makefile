COMMIT=$(shell git rev-parse HEAD)
VERSION=v0.0.0
DATE=$(shell date +'%FT%TZ%z')

ifeq ($(shell uname -s),Darwin)
CONFIG_DARWIN=y
else ifeq ($(OS),Windows_NT)
CONFIG_WINDOWS=y
else
CONFIG_LINUX=y
endif

ifdef CONFIG_DARWIN
LOADABLE_EXTENSION=dylib
endif

ifdef CONFIG_LINUX
LOADABLE_EXTENSION=so
endif


all: dist/package.zip

clean:
	rm dist/*

dist/sqlite3-extra.c: sqlite/sqlite3.c core_init.c
	cat sqlite/sqlite3.c core_init.c > $@

dist/lines.o: lines.c lines.h
	gcc -Isqlite \
	-c \
	-DSQLITE_LINES_DATE="\"$(DATE)\"" \
	$< -o $@

dist/sqlite-lines: cli.c dist/lines.o
	gcc -O3 \
	-DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
	-Isqlite \
	sqlite/sqlite3.c \
	cli.c dist/lines.o -o $@

dist/sqlite3: dist/sqlite3-extra.c sqlite/shell.c dist/lines.o
	gcc \
	 -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
	-DSQLITE_EXTRA_INIT=core_init \
	-I./ dist/sqlite3-extra.c sqlite/shell.c dist/lines.o -o $@

dist/lines0.$(LOADABLE_EXTENSION): lines.c
	gcc -Isqlite \
	-fPIC -shared \
	-DSQLITE_LINES_DATE="\"$(DATE)\"" \
	$< -o $@

dist/package.zip: dist/lines0.$(LOADABLE_EXTENSION) dist/lines.o lines.h dist/sqlite3 dist/sqlite-lines
	zip --junk-paths $@ dist/lines0.$(LOADABLE_EXTENSION)  dist/lines.o lines.h dist/sqlite3 dist/sqlite-lines


test-watch:
	watchexec -w lines.c -w tests/ -w tests/ --clear make test

test: 
	make test-cli
	make test-loadable
	make test-sqlite3

test-cli: dist/sqlite-lines
	python3 tests/test-cli.py

test-sqlite3: dist/sqlite3
	python3 tests/test-sqlite3.py

test-loadable: dist/lines0.$(LOADABLE_EXTENSION)
	python3 tests/test-loadable.py

test-watch-cli: dist/sqlite-lines tests/test-cli.py
	watchexec -w cli.c -w dist/sqlite-lines -w tests/test-cli.py --clear -- make test-cli

test-watch-sqlite3: dist/sqlite3
	watchexec -w dist/sqlite3 -w tests/test-sqlite3.py -- make test-sqlite3

test-watch-loadable: dist/lines0.$(LOADABLE_EXTENSION)
	watchexec -w dist/lines0.$(LOADABLE_EXTENSION) -w tests/test-loadable.py -- make test-loadable

.PHONY: all clean \
	test test-watch test-cli test-loadable test-sqlite3 

x:
	wget -O sqlite.tar.gz https://sqlite.org/2022/sqlite-autoconf-3380000.tar.gz
	tar xf sqlite.tar.gz
	rm sqlite.tar.gz
	mv sqlite-autoconf-3380000 sqlite

	cd sqlite

	./configure --enable-readline

	make	

CFLAGS = \
	-O2 \
	-DSQLITE_OMIT_LOAD_EXTENSION \
	-DSQLITE_DISABLE_LFS \
	-DSQLITE_ENABLE_FTS3 \
	-DSQLITE_ENABLE_FTS3_PARENTHESIS \
	-DSQLITE_ENABLE_JSON1 \
	-DSQLITE_THREADSAFE=0 \
	-DSQLITE_ENABLE_NORMALIZE \
	-DSQLITE_LINES_DATE="\"$(DATE)\"" \
	-DSQLITE_EXTRA_INIT=core_init

EMFLAGS = \
	--memory-init-file 0 \
	-s RESERVED_FUNCTION_POINTERS=64 \
	-s ALLOW_TABLE_GROWTH=1 \
	-s EXPORTED_FUNCTIONS=@wasm/exported_functions.json \
	-s EXPORTED_RUNTIME_METHODS=@wasm/exported_runtime_methods.json \
	-s SINGLE_FILE=0 \
	-s NODEJS_CATCH_EXIT=0 \
	-s NODEJS_CATCH_REJECTION=0 \
	-s LLD_REPORT_UNDEFINED


EMFLAGS_WASM = \
	-s WASM=1 \
	-s ALLOW_MEMORY_GROWTH=1

EMFLAGS_OPTIMIZED= \
	-s INLINING_LIMIT=50 \
	-O3 \
	-flto \
	--closure 1

EMFLAGS_DEBUG = \
	-s INLINING_LIMIT=10 \
	-s ASSERTIONS=1 \
	-O1

SQLJS_JS=dist/sqljs.js
SQLJS_WASM=dist/sqljs.wasm

$(SQLJS_JS) $(SQLJS_WASM): $(shell find wasm/ -type f) lines.c sqlite3-extra.c
	emcc $(CFLAGS) $(EMFLAGS) $(EMFLAGS_DEBUG) $(EMFLAGS_WASM) \
		-I./sqlite -I./ lines.c sqlite3-extra.c \
		--pre-js wasm/api.js \
		-o $(SQLJS_JS)
	mv $(SQLJS_JS) tmp.js
	cat wasm/shell-pre.js tmp.js wasm/shell-post.js > $(SQLJS_JS)
	rm tmp.js
