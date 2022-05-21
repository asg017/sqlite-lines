/*
  This file is appended to the end of a sqlite3.c amalgammation 
  file to include sqlite3_lines functions/tables statically in 
  a build. This is used for the demo CLI and WASM implementations.
*/
#include "lines.h"
int core_init(const char* dummy) {
  return sqlite3_auto_extension((void*)
    #ifdef SQLITE_LINES_DISABLE_FILESYSTEM
    sqlite3_linesnofs_init
    #else
    sqlite3_lines_init
    #endif
  );
}