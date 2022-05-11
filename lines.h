#ifndef __LINES_
#define __LINES_

int sqlite3_lines_init(
  sqlite3 *db, 
  char **pzErrMsg, 
  const sqlite3_api_routines *pApi
);
#endif /* __LINES__ */