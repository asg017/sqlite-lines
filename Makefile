COMMIT=$(shell git rev-parse HEAD)
VERSION=v0.0.0
DATE=$(shell date +'%FT%TZ%z')

dist/lines.dylib: lines.c
	gcc -Isqlite \
	-fPIC -shared \
	-DSQLITE_LINES_DATE="\"$(DATE)\"" \
	$< -o $@

dist/lines.o: lines.c
	gcc -Isqlite \
	-c \
	-DSQLITE_LINES_DATE="\"$(DATE)\"" \
	$< -o $@

dist/cli: cli.c dist/lines.o
	gcc -Isqlite \
	sqlite/.libs/sqlite3.o dist/lines.o \
	$< -o $@

sqlite3-extra.c: sqlite/sqlite3.c lines.c core_init.c
	cp sqlite/sqlite3.c $@
	cat lines.c >> $@
	cat core_init.c >> $@

dist/sqlite3: sqlite3-extra.c
	gcc -DSQLITE_LINES_DATE=\"x\"  \
	-DSQLITE_EXTRA_INIT=core_init \
	sqlite3-extra.c sqlite/shell.c -o $@

mac: dist/lines.dylib

test: dist/lines.dylib
	python3 test.py

test-watch:
	watchexec -w lines.c -w test.py --clear make test

.PHONY: test test-watch mac

x:
	wget -O sqlite.tar.gz https://sqlite.org/2022/sqlite-autoconf-3380000.tar.gz
	tar xf sqlite.tar.gz
	rm sqlite.tar.gz
	mv sqlite-autoconf-3380000 sqlite

	cd sqlite

	./configure --enable-readline

	make	