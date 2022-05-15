COMMIT=$(shell git rev-parse HEAD)
VERSION=v0.0.0
DATE=$(shell date +'%FT%TZ%z')

LOADABLE_CFLAGS=-fPIC -shared

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

ifdef CONFIG_WINDOWS
LOADABLE_EXTENSION=dll
LOADABLE_CFLAGS=-shared
endif

DEFINE_SQLITE_LINES_DATE=-DSQLITE_LINES_DATE="\"$(DATE)\""

TARGET_OBJ=dist/lines.o
TARGET_CLI=dist/sqlite-lines
TARGET_LOADABLE=dist/lines0.$(LOADABLE_EXTENSION)
TARAGET_SQLITE3=dist/sqlite3
TARGET_PACKAGE=dist/package.zip

all: dist/package.zip

clean:
	rm dist/*

dist/package.zip: $(TARGET_LOADABLE) $(TARGET_OBJ) lines.h $(TARAGET_SQLITE3) $(TARGET_CLI)
	zip --junk-paths $@ $(TARGET_LOADABLE)  $(TARGET_OBJ) lines.h $(TARAGET_SQLITE3) $(TARGET_CLI)

$(TARGET_LOADABLE): lines.c
	gcc -Isqlite \
	$(LOADABLE_CFLAGS) \
	$(DEFINE_SQLITE_LINES_DATE) \
	$< -o $@

$(TARGET_CLI): cli.c lines.c
	gcc -O3 \
	 $(DEFINE_SQLITE_LINES_DATE) \
	-DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
	-Isqlite \
	sqlite/sqlite3.c \
	cli.c lines.c -o $@

dist/sqlite3: dist/sqlite3-extra.c sqlite/shell.c lines.c
	gcc \
	$(DEFINE_SQLITE_LINES_DATE) \
	-DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
	-DSQLITE_EXTRA_INIT=core_init \
	-I./ -I./sqlite dist/sqlite3-extra.c sqlite/shell.c lines.c -o $@

$(TARGET_OBJ): lines.c lines.h
	gcc -Isqlite \
	-c \
	-DSQLITE_LINES_DATE="\"$(DATE)\"" \
	$< -o $@

dist/sqlite3-extra.c: sqlite/sqlite3.c core_init.c
	cat sqlite/sqlite3.c core_init.c > $@

test: 
	make test-cli
	make test-loadable
	make test-sqlite3

test-cli: $(TARGET_CLI)
	python3 tests/test-cli.py

test-sqlite3: $(TARAGET_SQLITE3)
	python3 tests/test-sqlite3.py

test-loadable: $(TARGET_LOADABLE)
	python3 tests/test-loadable.py

test-watch:
	watchexec -w lines.c -w tests/ -w tests/ --clear make test

test-watch-cli: $(TARGET_CLI) tests/test-cli.py
	watchexec -w cli.c -w dist/sqlite-lines -w tests/test-cli.py --clear -- make test-cli

test-watch-sqlite3: $(TARAGET_SQLITE3)
	watchexec -w $(TARAGET_SQLITE3) -w tests/test-sqlite3.py -- make test-sqlite3

test-watch-loadable: $(TARGET_LOADABLE)
	watchexec -w $(TARGET_LOADABLE) -w tests/test-loadable.py -- make test-loadable

.PHONY: all clean \
	test test-watch test-cli test-loadable test-sqlite3 

CFLAGS = \
	-O2 \
	-DSQLITE_OMIT_LOAD_EXTENSION \
	-DSQLITE_DISABLE_LFS \
	-DSQLITE_ENABLE_FTS3 \
	-DSQLITE_ENABLE_FTS3_PARENTHESIS \
	-DSQLITE_ENABLE_JSON1 \
	-DSQLITE_THREADSAFE=0 \
	-DSQLITE_ENABLE_NORMALIZE \
	$(DEFINE_SQLITE_LINES_DATE) \
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
