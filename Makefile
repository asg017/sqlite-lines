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

ifdef python
PYTHON=$(python)
else
PYTHON=python3
endif

ifdef IS_MACOS_ARM
RENAME_WHEELS_ARGS=--is-macos-arm
else
RENAME_WHEELS_ARGS=
endif

DEFINE_SQLITE_LINES_DATE=-DSQLITE_LINES_DATE="\"$(DATE)\""
DEFINE_SQLITE_LINES_VERSION=-DSQLITE_LINES_VERSION="\"v$(VERSION)\""
DEFINE_SQLITE_LINES_SOURCE=-DSQLITE_LINES_SOURCE="\"$(COMMIT)\""
DEFINE_SQLITE_LINES=$(DEFINE_SQLITE_LINES_DATE) $(DEFINE_SQLITE_LINES_VERSION) $(DEFINE_SQLITE_LINES_SOURCE)

prefix=dist

TARGET_OBJ=$(prefix)/lines.o
TARGET_CLI=$(prefix)/sqlite-lines
TARGET_LOADABLE=$(prefix)/lines0.$(LOADABLE_EXTENSION)
TARGET_WHEELS=$(prefix)/wheels
TARGET_SQLITE3_EXTRA_C=$(prefix)/sqlite3-extra.c
TARGET_SQLITE3=$(prefix)/sqlite3
TARGET_PACKAGE=$(prefix)/package.zip
TARGET_SQLJS_JS=$(prefix)/sqljs.js
TARGET_SQLJS_WASM=$(prefix)/sqljs.wasm
TARGET_SQLJS=$(TARGET_SQLJS_JS) $(TARGET_SQLJS_WASM)

INTERMEDIATE_PYPACKAGE_EXTENSION=python/sqlite_lines/sqlite_lines/lines0.$(LOADABLE_EXTENSION)

$(prefix):
	mkdir -p $(prefix)

$(TARGET_WHEELS): $(prefix)
	mkdir -p $(TARGET_WHEELS)

all: $(TARGET_PACKAGE) $(TARGET_SQLJS)

clean:
	rm dist/*

FORMAT_FILES=sqlite-lines.h sqlite-lines.c cli.c core_init.c
format: $(FORMAT_FILES)
	clang-format -i $(FORMAT_FILES)

loadable: $(TARGET_LOADABLE)
cli: $(TARGET_CLI)
sqlite3: $(TARGET_SQLITE3)
sqljs: $(TARGET_SQLJS)

$(TARGET_PACKAGE): $(prefix) $(TARGET_LOADABLE) $(TARGET_OBJ) sqlite-lines.h sqlite-lines.c $(TARGET_SQLITE3) $(TARGET_CLI)
	zip --junk-paths $(TARGET_PACKAGE) $(TARGET_LOADABLE) $(TARGET_OBJ) sqlite-lines.h sqlite-lines.c $(TARGET_SQLITE3) $(TARGET_CLI)

$(TARGET_LOADABLE): $(prefix) sqlite-lines.c
	gcc -Isqlite \
	$(LOADABLE_CFLAGS) \
	$(DEFINE_SQLITE_LINES) \
	sqlite-lines.c -o $@

$(TARGET_CLI): $(prefix) cli.c sqlite-lines.c $(TARGET_SQLITE3_EXTRA_C) sqlite/shell.c
	gcc -O3 \
	 $(DEFINE_SQLITE_LINES) \
	-DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
	-I./ -Isqlite \
	sqlite/sqlite3.c \
	cli.c sqlite-lines.c -o $@

$(TARGET_SQLITE3): $(prefix) $(TARGET_SQLITE3_EXTRA_C) sqlite/shell.c sqlite-lines.c
	gcc \
	$(DEFINE_SQLITE_LINES) \
	-DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
	-DSQLITE_EXTRA_INIT=core_init \
	-I./ -I./sqlite $(TARGET_SQLITE3_EXTRA_C) sqlite/shell.c sqlite-lines.c -o $@

$(TARGET_OBJ): $(prefix) sqlite-lines.c sqlite-lines.h
	gcc -Isqlite \
	-c \
	$(DEFINE_SQLITE_LINES) \
	sqlite-lines.c -o $@

$(TARGET_SQLITE3_EXTRA_C): sqlite/sqlite3.c core_init.c
	cat sqlite/sqlite3.c core_init.c > $@


python: $(TARGET_WHEELS) $(TARGET_LOADABLE) $(TARGET_WHEELS) scripts/rename-wheels.py $(shell find python/sqlite_lines -type f -name '*.py')
	cp $(TARGET_LOADABLE) $(INTERMEDIATE_PYPACKAGE_EXTENSION)
	rm $(TARGET_WHEELS)/sqlite_lines* || true
	pip3 wheel python/sqlite_lines/ -w $(TARGET_WHEELS)
	python3 scripts/rename-wheels.py $(TARGET_WHEELS) $(RENAME_WHEELS_ARGS)
	echo "✅ generated python wheel"

python-versions: python/version.py.tmpl
	VERSION=$(VERSION) envsubst < python/version.py.tmpl > python/sqlite_lines/sqlite_lines/version.py
	echo "✅ generated python/sqlite_lines/sqlite_lines/version.py"

	VERSION=$(VERSION) envsubst < python/version.py.tmpl > python/datasette_sqlite_lines/datasette_sqlite_lines/version.py
	echo "✅ generated python/datasette_sqlite_lines/datasette_sqlite_lines/version.py"

datasette: $(TARGET_WHEELS) $(shell find python/datasette_sqlite_lines -type f -name '*.py')
	rm $(TARGET_WHEELS)/datasette* || true
	pip3 wheel python/datasette_sqlite_lines/ --no-deps -w $(TARGET_WHEELS)

bindings/sqlite-utils/pyproject.toml: bindings/sqlite-utils/pyproject.toml.tmpl VERSION
	VERSION=$(VERSION) envsubst < $< > $@
	echo "✅ generated $@"

bindings/sqlite-utils/sqlite_utils_sqlite_lines/version.py: bindings/sqlite-utils/sqlite_utils_sqlite_lines/version.py.tmpl VERSION
	VERSION=$(VERSION) envsubst < $< > $@
	echo "✅ generated $@"

sqlite-utils: $(TARGET_WHEELS) bindings/sqlite-utils/pyproject.toml bindings/sqlite-utils/sqlite_utils_sqlite_lines/version.py
	python3 -m build bindings/sqlite-utils -w -o $(TARGET_WHEELS)

npm: VERSION npm/platform-package.README.md.tmpl npm/platform-package.package.json.tmpl npm/sqlite-lines/package.json.tmpl scripts/npm_generate_platform_packages.sh
	scripts/npm_generate_platform_packages.sh

deno: VERSION deno/deno.json.tmpl
	scripts/deno_generate_package.sh

bindings/ruby/lib/version.rb: bindings/ruby/lib/version.rb.tmpl VERSION
	VERSION=$(VERSION) envsubst < $< > $@

ruby: bindings/ruby/lib/version.rb

version:
	make python
	make python-versions
	make bindings/sqlite-utils/pyproject.toml bindings/sqlite-utils/sqlite_utils_sqlite_lines/version.py
	make npm
	make deno
	make ruby

test_files/big.txt:
	seq 1 1000000 > $@

test_files/big-line-line.txt:
	dd if=/dev/zero of=$@ bs=1000000 count=1001

test_files: test_files/big.txt test_files/big-line-line.txt

test:
	make test-loadable
	make test-python
	make test-npm
	make test-deno
	make test-cli
	make test-sqlite3

lint: SHELL:=/bin/bash
lint:
	diff -u <(cat $(FORMAT_FILES)) <(clang-format $(FORMAT_FILES))

test-loadable: $(TARGET_LOADABLE)
	$(PYTHON) tests/test-loadable.py

test-python:
	$(PYTHON) tests/test-python.py

test-npm:
	node npm/sqlite-lines/test.js

test-deno:
	deno task --config deno/deno.json test

test-cli: $(TARGET_CLI)
	python3 tests/test-cli.py

test-sqlite3: $(TARGET_SQLITE3)
	python3 tests/test-sqlite3.py

test-sqljs: $(TARGET_SQLJS)
	python3 -m http.server & open http://localhost:8000/tests/test-sqljs.lines

test-watch:
	watchexec -w sqlite-lines.c -w tests/ -w tests/ --clear make test

test-loadable-watch: $(TARGET_LOADABLE)
	watchexec -w sqlite-lines.c -w $(TARGET_LOADABLE) -w tests/test-loadable.py --clear -- make test-loadable

test-cli-watch: $(TARGET_CLI) tests/test-cli.py
	watchexec -w cli.c -w $(TARGET_CLI) -w tests/test-cli.py --clear -- make test-cli

test-sqlite3-watch: $(TARAGET_SQLITE3)
	watchexec -w $(TARAGET_SQLITE3) -w tests/test-sqlite3.py --clear -- make test-sqlite3

publish-release:
	./scripts/publish_release.sh

.PHONY: all clean format version publish-release \
	python python-versions datasette sqlite-utils npm deno ruby version \
	test test-watch test-loadable-watch test-cli-watch test-sqlite3-watch \
	test-format test-loadable test-cli test-sqlite3 test-sqljs test-python \
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
	-s INLINING_LIMIT=1 \
	-O3 \
	-flto \
	--closure 1

SQLJS_EMFLAGS_DEBUG = \
	-s INLINING_LIMIT=1 \
	-s ASSERTIONS=1 \
	-O1

$(TARGET_SQLJS): $(prefix) $(shell find wasm/ -type f) sqlite-lines.c $(TARGET_SQLITE3_EXTRA_C)
	emcc $(SQLJS_CFLAGS) $(SQLJS_EMFLAGS) $(SQLJS_EMFLAGS_DEBUG) $(SQLJS_EMFLAGS_WASM) \
		-I./sqlite -I./ sqlite-lines.c $(TARGET_SQLITE3_EXTRA_C) \
		--pre-js wasm/api.js \
		-o $(TARGET_SQLJS_JS)
	mv $(TARGET_SQLJS_JS) tmp.js
	cat wasm/shell-pre.js tmp.js wasm/shell-post.js > $(TARGET_SQLJS_JS)
	rm tmp.js
