#include "sqlite3ext.h"

#ifdef SQLITE_LINES_ENTRYPOINT
int SQLITE_LINES_ENTRYPOINT(
#else
int sqlite3_lines_init(
#endif
    sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi);