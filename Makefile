COMMIT=$(shell git rev-parse HEAD)
VERSION=v0.0.0
DATE=$(shell date +'%FT%TZ%z')

dist/lines.dylib: lines.c
	gcc -Isqlite \
	-fPIC -shared \
	-DSQLITE_LINES_DATE="\"$(DATE)\"" \
	$< -o $@

mac: dist/lines.dylib

test: dist/lines.dylib
	python3 test.py

test-watch:
	watchexec -w xls.c -w test.py --clear make test

.PHONY: test mac

x:
	wget -O sqlite.tar.gz https://sqlite.org/2022/sqlite-autoconf-3380000.tar.gz
	tar xf sqlite.tar.gz
	rm sqlite.tar.gz
	mv sqlite-autoconf-3380000 sqlite

	cd sqlite

	./configure --enable-readline

	make	