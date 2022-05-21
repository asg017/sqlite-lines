#ifdef SQLITE_LINES_DISABLE_FILESYSTEM
int sqlite3_linesnofs_init(
#else
int sqlite3_lines_init(
#endif
  sqlite3 *db, 
  char **pzErrMsg, 
  const sqlite3_api_routines *pApi
);