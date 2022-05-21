#!/bin/bash
valgrind --tool=memcheck --leak-check=full --show-leak-kinds=definite --track-origins=yes \
  ./dist/sqlite3 :memory: 'select line from lines("a|b|c|d|e", "|");' '.exit 0'

valgrind --tool=memcheck --leak-check=full --show-leak-kinds=definite --track-origins=yes \
  ./dist/sqlite3 :memory: 'select line from lines_read("README.md");' '.exit 0'

valgrind --tool=memcheck --leak-check=full --show-leak-kinds=definite --track-origins=yes \
  ./dist/sqlite3 :memory: 'select line from lines_read("README.md") where rowid=4;' '.exit 0'

valgrind --tool=memcheck --leak-check=full --show-leak-kinds=definite --track-origins=yes \
  ./dist/sqlite3 :memory: 'select lines_version(), lines_debug()' '.exit 0'
