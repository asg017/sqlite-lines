COMMIT=$(shell git rev-parse HEAD)
VERSION=$(shell cat VERSION)
DATE=$(shell date +'%FT%TZ%z')

LOADABLE_CFLAGS=-fPIC -shared

ifeq ($(shell uname -s),Darwin)
CONFIG_DARWIN=y
else
CONFIG_LINUX=y
endif

ifdef CONFIG_DARWIN
LOADABLE_EXTENSION=dylib
endif

ifdef CONFIG_LINUX
LOADABLE_EXTENSION=so
endif

DEFINE_SQLITE_LINES_DATE=-DSQLITE_LINES_DATE="\"$(DATE)\""
DEFINE_SQLITE_LINES_VERSION=-DSQLITE_LINES_VERSION="\"$(VERSION)\""
DEFINE_SQLITE_LINES_SOURCE=-DSQLITE_LINES_SOURCE="\"$(COMMIT)\""
DEFINE_SQLITE_LINES=$(DEFINE_SQLITE_LINES_DATE) $(DEFINE_SQLITE_LINES_VERSION) $(DEFINE_SQLITE_LINES_SOURCE)

TARGET_OBJ=dist/lines.o
TARGET_CLI=dist/sqlite-lines
TARGET_LOADABLE=dist/lines0.$(LOADABLE_EXTENSION)
TARGET_LOADABLE_NOFS=dist/lines_nofs0.$(LOADABLE_EXTENSION)
TARGET_SQLITE3=dist/sqlite3
TARGET_PACKAGE=dist/package.zip
TARGET_SQLJS_JS=dist/sqljs.js
TARGET_SQLJS_WASM=dist/sqljs.wasm
TARGET_SQLJS=$(TARGET_SQLJS_JS) $(TARGET_SQLJS_WASM)

all: $(TARGET_PACKAGE) $(TARGET_SQLJS)

clean:
	rm dist/*

loadable: $(TARGET_LOADABLE) $(TARGET_LOADABLE_NOFS)
cli: $(TARGET_CLI)
sqlite3: $(TARGET_SQLITE3)
sqljs: $(TARGET_SQLJS)

$(TARGET_PACKAGE): $(TARGET_LOADABLE) $(TARGET_LOADABLE_NOFS) $(TARGET_OBJ) lines.h lines.c $(TARGET_SQLITE3) $(TARGET_CLI)
	zip --junk-paths $@ $(TARGET_LOADABLE) $(TARGET_LOADABLE_NOFS) $(TARGET_OBJ) lines.h lines.c $(TARGET_SQLITE3) $(TARGET_CLI)

$(TARGET_LOADABLE): lines.c
	gcc -Isqlite \
	$(LOADABLE_CFLAGS) \
	$(DEFINE_SQLITE_LINES) \
	$< -o $@

$(TARGET_LOADABLE_NOFS): lines.c
	gcc -Isqlite \
	$(LOADABLE_CFLAGS) \
	$(DEFINE_SQLITE_LINES) -DSQLITE_LINES_DISABLE_FILESYSTEM \
	$< -o $@

$(TARGET_CLI): cli.c lines.c
	gcc -O3 \
	 $(DEFINE_SQLITE_LINES) \
	-DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
	-Isqlite \
	sqlite/sqlite3.c \
	cli.c lines.c -o $@

$(TARGET_SQLITE3): dist/sqlite3-extra.c sqlite/shell.c lines.c
	gcc \
	$(DEFINE_SQLITE_LINES) \
	-DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
	-DSQLITE_EXTRA_INIT=core_init \
	-I./ -I./sqlite dist/sqlite3-extra.c sqlite/shell.c lines.c -o $@

$(TARGET_OBJ): lines.c lines.h
	gcc -Isqlite \
	-c \
	$(DEFINE_SQLITE_LINES) \
	$< -o $@

dist/sqlite3-extra.c: sqlite/sqlite3.c core_init.c
	cat sqlite/sqlite3.c core_init.c > $@

test_files/big.txt:
	seq 1 1000000 > $@

test_files/big-line-line.txt:
	dd if=/dev/zero of=$@ bs=1000000 count=1001

test_files: test_files/big.txt test_files/big-line-line.txt

test: 
	make test-cli
	make test-loadable
	make test-sqlite3

test-cli: $(TARGET_CLI)
	python3 tests/test-cli.py

test-sqlite3: $(TARGET_SQLITE3)
	python3 tests/test-sqlite3.py

test-loadable: $(TARGET_LOADABLE)
	python3 tests/test-loadable.py

test-sqljs: $(TARGET_SQLJS)
	python3 -m http.server & open http://localhost:8000/tests/test-sqljs.html

test-watch:
	watchexec -w lines.c -w tests/ -w tests/ --clear make test

test-loadable-watch: $(TARGET_LOADABLE)
	watchexec -w lines.c -w $(TARGET_LOADABLE) -w tests/test-loadable.py --clear -- make test-loadable

test-cli-watch: $(TARGET_CLI) tests/test-cli.py
	watchexec -w cli.c -w dist/sqlite-lines -w tests/test-cli.py --clear -- make test-cli

test-sqlite3-watch: $(TARAGET_SQLITE3)
	watchexec -w $(TARAGET_SQLITE3) -w tests/test-sqlite3.py --clear -- make test-sqlite3

.PHONY: all clean \
	test test-watch test-loadable-watch test-cli-watch test-sqlite3-watch \
	test-loadable test-cli test-sqlite3 test-sqljs \
	test_files \
	loadable cli sqlite3 sqljs

# The below is mostly borrowed from https://github.com/sql-js/sql.js/blob/master/Makefile

# WASM has no (easy) filesystem for the demo, so disable lines_read
SQLJS_CFLAGS = \
	-O2 \
	-DSQLITE_OMIT_LOAD_EXTENSION \
	-DSQLITE_DISABLE_LFS \
	-DSQLITE_ENABLE_JSON1 \
	-DSQLITE_THREADSAFE=0 \
	-DSQLITE_ENABLE_NORMALIZE \
	$(DEFINE_SQLITE_LINES) -DSQLITE_LINES_DISABLE_FILESYSTEM \
	-DSQLITE_EXTRA_INIT=core_init

SQLJS_EMFLAGS = \
	--memory-init-file 0 \
	-s RESERVED_FUNCTION_POINTERS=64 \
	-s ALLOW_TABLE_GROWTH=1 \
	-s EXPORTED_FUNCTIONS=@wasm/exported_functions.json \
	-s EXPORTED_RUNTIME_METHODS=@wasm/exported_runtime_methods.json \
	-s SINGLE_FILE=0 \
	-s NODEJS_CATCH_EXIT=0 \
	-s NODEJS_CATCH_REJECTION=0 \
	-s LLD_REPORT_UNDEFINED

SQLJS_EMFLAGS_WASM = \
	-s WASM=1 \
	-s ALLOW_MEMORY_GROWTH=1

SQLJS_EMFLAGS_OPTIMIZED= \
	-s INLINING_LIMIT=50 \
	-O3 \
	-flto \
	--closure 1

SQLJS_EMFLAGS_DEBUG = \
	-s INLINING_LIMIT=10 \
	-s ASSERTIONS=1 \
	-O1

$(TARGET_SQLJS): $(shell find wasm/ -type f) lines.c dist/sqlite3-extra.c
	emcc $(SQLJS_CFLAGS) $(SQLJS_EMFLAGS) $(SQLJS_EMFLAGS_DEBUG) $(SQLJS_EMFLAGS_WASM) \
		-I./sqlite -I./ lines.c dist/sqlite3-extra.c \
		--pre-js wasm/api.js \
		-o $(TARGET_SQLJS_JS)
	mv $(TARGET_SQLJS_JS) tmp.js
	cat wasm/shell-pre.js tmp.js wasm/shell-post.js > $(TARGET_SQLJS_JS)
	rm tmp.js
