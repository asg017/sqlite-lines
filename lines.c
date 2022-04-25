#include "sqlite3ext.h"

SQLITE_EXTENSION_INIT1

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <glob.h>
#include <errno.h>


typedef struct lines_read_cursor lines_read_cursor;
struct lines_read_cursor {
  sqlite3_vtab_cursor base;  /* Base class - must be first */
  FILE *fp;
  size_t curLineLength;
  char* curLineContents;
  sqlite3_int64 iRowid;      /* The rowid */
};

/*
** The linesReadConnect() method is invoked to create a new
** lines_read_vtab that describes the lines_read virtual table.
**
** Think of this routine as the constructor for lines_read_vtab objects.
**
** All this routine needs to do is:
**
**    (1) Allocate the lines_read_vtab object and initialize all fields.
**
**    (2) Tell SQLite (via the sqlite3_declare_vtab() interface) what the
**        result set of queries against lines_read will look like.
*/
static int linesReadConnect(
  sqlite3 *db,
  void *pUnused,
  int argcUnused, const char *const*argvUnused,
  sqlite3_vtab **ppVtab,
  char **pzErrUnused
){
  sqlite3_vtab *pNew;
  int rc;

/* Column numbers */
#define LINES_READ_COLUMN_CONTENTS        0
#define LINES_READ_COLUMN_PATH            1

  (void)pUnused;
  (void)argcUnused;
  (void)argvUnused;
  (void)pzErrUnused;
  rc = sqlite3_declare_vtab(db,
     "CREATE TABLE x(contents text,"
     "path hidden)");
  if( rc==SQLITE_OK ){ 
    pNew = *ppVtab = sqlite3_malloc( sizeof(*pNew) );
    if( pNew==0 ) return SQLITE_NOMEM;
    memset(pNew, 0, sizeof(*pNew));
    sqlite3_vtab_config(db, SQLITE_VTAB_INNOCUOUS);
  }
  return rc;
}

/*
** This method is the destructor for lines_read_cursor objects.
*/
static int linesReadDisconnect(sqlite3_vtab *pVtab){
  sqlite3_free(pVtab);
  return SQLITE_OK;
}

/*
** Constructor for a new lines_read_cursor object.
*/
static int linesReadOpen(sqlite3_vtab *pUnused, sqlite3_vtab_cursor **ppCursor){
  lines_read_cursor *pCur;
  (void)pUnused;
  pCur = sqlite3_malloc( sizeof(*pCur) );
  if( pCur==0 ) return SQLITE_NOMEM;
  memset(pCur, 0, sizeof(*pCur));
  *ppCursor = &pCur->base;
  return SQLITE_OK;
}

/*
** Destructor for a lines_read_cursor.
*/
static int linesReadClose(sqlite3_vtab_cursor *cur){
  lines_read_cursor *pCur = (lines_read_cursor*)cur;
  fclose(pCur->fp);
  sqlite3_free(cur);
  return SQLITE_OK;
}


/*
** Advance a lines_read_cursor to its next row of output.
*/
static int linesReadNext(sqlite3_vtab_cursor *cur){
  lines_read_cursor *pCur = (lines_read_cursor*)cur;
  pCur->iRowid++;
  size_t len = 0;
  pCur->curLineLength = getline(&pCur->curLineContents, &len, pCur->fp);
  return SQLITE_OK;
}

/*
** Return TRUE if the cursor has been moved off of the last
** row of output.
*/
static int linesReadEof(sqlite3_vtab_cursor *cur){
  lines_read_cursor *pCur = (lines_read_cursor*)cur;
  return pCur->curLineLength == -1;
}

/*
** Return values of columns for the row at which the lines_read_cursor
** is currently pointing.
*/
static int linesReadColumn(
  sqlite3_vtab_cursor *cur,   /* The cursor */
  sqlite3_context *ctx,       /* First argument to sqlite3_result_...() */
  int i                       /* Which column to return */
){
  lines_read_cursor *pCur = (lines_read_cursor*)cur;
  sqlite3_int64 x = 0;
  switch( i ){
    case LINES_READ_COLUMN_CONTENTS: {
      sqlite3_result_text(ctx, pCur->curLineContents, pCur->curLineLength, SQLITE_TRANSIENT);
      break;
    }
  }
  return SQLITE_OK;
}

/*
** Return the rowid for the current row. In this implementation, the
** first row returned is assigned rowid value 1, and each subsequent
** row a value 1 more than that of the previous.
*/
static int linesReadRowid(sqlite3_vtab_cursor *cur, sqlite_int64 *pRowid){
  lines_read_cursor *pCur = (lines_read_cursor*)cur;
  *pRowid = pCur->iRowid;
  return SQLITE_OK;
}

/*
** This method is called to "rewind" the lines_read_cursor object back
** to the first row of output.  This method is always called at least
** once prior to any call to xColumn() or xRowid() or xEof().
**
** This routine should initialize the cursor and position it so that it
** is pointing at the first row, or pointing off the end of the table
** (so that xEof() will return true) if the table is empty.
*/
static int linesReadFilter(
  sqlite3_vtab_cursor *pVtabCursor, 
  int idxNum, const char *idxStrUnused,
  int argc, sqlite3_value **argv
){
  lines_read_cursor *pCur = (lines_read_cursor *)pVtabCursor;
  const char * path = (const char * ) sqlite3_value_text(argv[0]);
  if(pCur->fp != NULL) {
    fclose(pCur->fp);
  }
  int errnum;
  pCur->fp = fopen(path, "r");
  if (pCur->fp == NULL) {
    int errnum;
    errnum = errno;
    fprintf(stderr, "Error opening file at %s: %s\n", path, strerror( errnum ));
    return SQLITE_ERROR;
  }
  size_t len = 0;
  pCur->curLineLength = getline(&pCur->curLineContents, &len, pCur->fp);
  pCur->iRowid = 0;
  //pCur->curLineLength = 0;  
  //pCur->curLineContents = 0;    
  return SQLITE_OK;
}

/*
** SQLite will invoke this method one or more times while planning a query
** that uses the lines_read virtual table.  This routine needs to create
** a query plan for each invocation and compute an estimated cost for that
** plan.
*/
static int linesReadBestIndex(
  sqlite3_vtab *pVTab,
  sqlite3_index_info *pIdxInfo
){
  int hasPath = 0;
  for(int i=0; i<pIdxInfo->nConstraint; i++){
    const struct sqlite3_index_constraint *pCons = &pIdxInfo->aConstraint[i];
    //printf("i=%d iColumn=%d, op=%d, usable=%d\n", i, pCons->iColumn, pCons->op, pCons->usable);
    switch(pCons->iColumn) {
      case LINES_READ_COLUMN_PATH: {
        if(!pCons->usable) return SQLITE_CONSTRAINT;
        hasPath = 1;
        pIdxInfo->aConstraintUsage[i].argvIndex = 1;
        pIdxInfo->aConstraintUsage[i].omit = 1;
        break;
      }
    }
  }
  if(!hasPath) {
    pVTab->zErrMsg = sqlite3_mprintf("path argument is required");
    return SQLITE_ERROR;
  }
  pIdxInfo->idxNum = 1;
  pIdxInfo->estimatedCost = (double)100000;
  pIdxInfo->estimatedRows = 100000;

  return SQLITE_OK;
}

/*
** This following structure defines all the methods for the 
** lines_read virtual table.
*/
static sqlite3_module linesReadModule = {
  0,                         /* iVersion */
  0,                         /* xCreate */
  linesReadConnect,             /* xConnect */
  linesReadBestIndex,           /* xBestIndex */
  linesReadDisconnect,          /* xDisconnect */
  0,                         /* xDestroy */
  linesReadOpen,                /* xOpen - open a cursor */
  linesReadClose,               /* xClose - close a cursor */
  linesReadFilter,              /* xFilter - configure scan constraints */
  linesReadNext,                /* xNext - advance a cursor */
  linesReadEof,                 /* xEof - check for end of scan */
  linesReadColumn,              /* xColumn - read data */
  linesReadRowid,               /* xRowid - read data */
  0,                         /* xUpdate */
  0,                         /* xBegin */
  0,                         /* xSync */
  0,                         /* xCommit */
  0,                         /* xRollback */
  0,                         /* xFindMethod */
  0,                         /* xRename */
  0,                         /* xSavepoint */
  0,                         /* xRelease */
  0,                         /* xRollbackTo */
  0                          /* xShadowName */
};

typedef struct lines_glob_cursor lines_glob_cursor;
struct lines_glob_cursor {
  sqlite3_vtab_cursor base;  /* Base class - must be first */
  glob_t *glob;
  size_t curPathI;
  FILE *fp;
  size_t curLineLength;
  char* curLineContents;
  sqlite3_int64 iRowid;      /* The rowid */
};

/*
** The linesGlobConnect() method is invoked to create a new
** lines_glob_vtab that describes the lines_glob virtual table.
**
** Think of this routine as the constructor for lines_glob_vtab objects.
**
** All this routine needs to do is:
**
**    (1) Allocate the lines_glob_vtab object and initialize all fields.
**
**    (2) Tell SQLite (via the sqlite3_declare_vtab() interface) what the
**        result set of queries against lines_glob will look like.
*/
static int linesGlobConnect(
  sqlite3 *db,
  void *pUnused,
  int argcUnused, const char *const*argvUnused,
  sqlite3_vtab **ppVtab,
  char **pzErrUnused
){
  sqlite3_vtab *pNew;
  int rc;

/* Column numbers */
#define LINES_GLOB_COLUMN_PATH            0
#define LINES_GLOB_COLUMN_CONTENTS        1
#define LINES_GLOB_COLUMN_PATTERN         2

  (void)pUnused;
  (void)argcUnused;
  (void)argvUnused;
  (void)pzErrUnused;
  rc = sqlite3_declare_vtab(db,
     "CREATE TABLE x(path text, contents text,"
     "pattern hidden)");
  if( rc==SQLITE_OK ){ 
    pNew = *ppVtab = sqlite3_malloc( sizeof(*pNew) );
    if( pNew==0 ) return SQLITE_NOMEM;
    memset(pNew, 0, sizeof(*pNew));
    sqlite3_vtab_config(db, SQLITE_VTAB_INNOCUOUS);
  }
  return rc;
}

/*
** This method is the destructor for lines_glob_cursor objects.
*/
static int linesGlobDisconnect(sqlite3_vtab *pVtab){
  sqlite3_free(pVtab);
  return SQLITE_OK;
}

/*
** Constructor for a new lines_glob_cursor object.
*/
static int linesGlobOpen(sqlite3_vtab *pUnused, sqlite3_vtab_cursor **ppCursor){
  lines_glob_cursor *pCur;
  (void)pUnused;
  pCur = sqlite3_malloc( sizeof(*pCur) );
  if( pCur==0 ) return SQLITE_NOMEM;
  memset(pCur, 0, sizeof(*pCur));
  *ppCursor = &pCur->base;
  return SQLITE_OK;
}

/*
** Destructor for a lines_glob_cursor.
*/
static int linesGlobClose(sqlite3_vtab_cursor *cur){
  lines_glob_cursor *pCur = (lines_glob_cursor*)cur;
  if(pCur->fp)
    fclose(pCur->fp);
  globfree(pCur->glob);
  sqlite3_free(cur);
  return SQLITE_OK;
}


/*
** Advance a lines_glob_cursor to its next row of output.
*/
static int linesGlobNext(sqlite3_vtab_cursor *cur){
  lines_glob_cursor *pCur = (lines_glob_cursor*)cur;
  printf("start next\n");
  pCur->iRowid++;

  if (pCur->fp == NULL) {
    return SQLITE_ERROR;
  }
  size_t len = 0;
  pCur->curLineLength = getline(&pCur->curLineContents, &len, pCur->fp);
  if(pCur->curLineLength==-1) {
    printf("iffy\n");
    pCur->curPathI++;
    if(pCur->curPathI < pCur->glob->gl_pathc)
      pCur->fp = fopen(pCur->glob->gl_pathv[pCur->curPathI], "r");
  }
  printf("end next\n");
  return SQLITE_OK;
}

/*
** Return TRUE if the cursor has been moved off of the last
** row of output.
*/
static int linesGlobEof(sqlite3_vtab_cursor *cur){
  lines_glob_cursor *pCur = (lines_glob_cursor*)cur;
  printf("%d vs %d\n", pCur->curPathI, pCur->glob->gl_pathc);
  return pCur->curPathI == pCur->glob->gl_pathc;
}

/*
** Return values of columns for the row at which the lines_glob_cursor
** is currently pointing.
*/
static int linesGlobColumn(
  sqlite3_vtab_cursor *cur,   /* The cursor */
  sqlite3_context *ctx,       /* First argument to sqlite3_result_...() */
  int i                       /* Which column to return */
){
  lines_glob_cursor *pCur = (lines_glob_cursor*)cur;
  sqlite3_int64 x = 0;
  switch( i ){
    case LINES_GLOB_COLUMN_PATH: {
      sqlite3_result_text(ctx, pCur->glob->gl_pathv[pCur->curPathI], -1, SQLITE_TRANSIENT);
      break;
    }
    case LINES_GLOB_COLUMN_CONTENTS: {
      sqlite3_result_text(ctx, pCur->curLineContents, pCur->curLineLength, SQLITE_TRANSIENT);
      break;
    }
  }
  return SQLITE_OK;
}

/*
** Return the rowid for the current row. In this implementation, the
** first row returned is assigned rowid value 1, and each subsequent
** row a value 1 more than that of the previous.
*/
static int linesGlobRowid(sqlite3_vtab_cursor *cur, sqlite_int64 *pRowid){
  lines_glob_cursor *pCur = (lines_glob_cursor*)cur;
  *pRowid = pCur->iRowid;
  return SQLITE_OK;
}

/*
** This method is called to "rewind" the lines_glob_cursor object back
** to the first row of output.  This method is always called at least
** once prior to any call to xColumn() or xRowid() or xEof().
**
** This routine should initialize the cursor and position it so that it
** is pointing at the first row, or pointing off the end of the table
** (so that xEof() will return true) if the table is empty.
*/
static int linesGlobFilter(
  sqlite3_vtab_cursor *pVtabCursor, 
  int idxNum, const char *idxStrUnused,
  int argc, sqlite3_value **argv
){
  lines_glob_cursor *pCur = (lines_glob_cursor *)pVtabCursor;
  const char * pattern = (const char * ) sqlite3_value_text(argv[0]);

  char **found;
  glob_t gstruct;
  int r;
  
  r = glob(pattern, GLOB_ERR , NULL, &gstruct);
  /* check for errors */
  if( r!=0 ){
    if( r==GLOB_NOMATCH )
        fprintf(stderr,"No matches\n");
    else
        fprintf(stderr,"Some kinda glob error\n");
    return SQLITE_ERROR;
  }

  pCur->glob = &gstruct;

  pCur->curPathI = 0;
  pCur->fp = fopen(pCur->glob->gl_pathv[pCur->curPathI], "r");

  if (pCur->fp == NULL) {
    return SQLITE_ERROR;
  }
  size_t len = 0;
  pCur->curLineLength = getline(&pCur->curLineContents, &len, pCur->fp);
  return SQLITE_OK;
}

/*
** SQLite will invoke this method one or more times while planning a query
** that uses the lines_glob virtual table.  This routine needs to create
** a query plan for each invocation and compute an estimated cost for that
** plan.
*/
static int linesGlobBestIndex(
  sqlite3_vtab *pVTab,
  sqlite3_index_info *pIdxInfo
){
  int hasPattern = 0;
  for(int i=0; i<pIdxInfo->nConstraint; i++){
    const struct sqlite3_index_constraint *pCons = &pIdxInfo->aConstraint[i];
    //printf("i=%d iColumn=%d, op=%d, usable=%d\n", i, pCons->iColumn, pCons->op, pCons->usable);
    switch(pCons->iColumn) {
      case LINES_GLOB_COLUMN_PATTERN: {
        if(!pCons->usable) return SQLITE_CONSTRAINT;
        hasPattern = 1;
        pIdxInfo->aConstraintUsage[i].argvIndex = 1;
        pIdxInfo->aConstraintUsage[i].omit = 1;
        break;
      }
    }
  }
  if(!hasPattern) {
    pVTab->zErrMsg = sqlite3_mprintf("pattern argument is required");
    return SQLITE_ERROR;
  }
  pIdxInfo->idxNum = 1;
  pIdxInfo->estimatedCost = (double)100000;
  pIdxInfo->estimatedRows = 100000;

  return SQLITE_OK;
}

/*
** This following structure defines all the methods for the 
** lines_glob virtual table.
*/
static sqlite3_module linesGlobModule = {
  0,                         /* iVersion */
  0,                         /* xCreate */
  linesGlobConnect,             /* xConnect */
  linesGlobBestIndex,           /* xBestIndex */
  linesGlobDisconnect,          /* xDisconnect */
  0,                         /* xDestroy */
  linesGlobOpen,                /* xOpen - open a cursor */
  linesGlobClose,               /* xClose - close a cursor */
  linesGlobFilter,              /* xFilter - configure scan constraints */
  linesGlobNext,                /* xNext - advance a cursor */
  linesGlobEof,                 /* xEof - check for end of scan */
  linesGlobColumn,              /* xColumn - read data */
  linesGlobRowid,               /* xRowid - read data */
  0,                         /* xUpdate */
  0,                         /* xBegin */
  0,                         /* xSync */
  0,                         /* xCommit */
  0,                         /* xRollback */
  0,                         /* xFindMethod */
  0,                         /* xRename */
  0,                         /* xSavepoint */
  0,                         /* xRelease */
  0,                         /* xRollbackTo */
  0                          /* xShadowName */
};




#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_lines_init(
  sqlite3 *db, 
  char **pzErrMsg, 
  const sqlite3_api_routines *pApi
){
  int rc = SQLITE_OK;
  SQLITE_EXTENSION_INIT2(pApi);
  (void)pzErrMsg;  /* Unused parameter */
  if(rc == SQLITE_OK) rc = sqlite3_create_module(db, "lines_read", &linesReadModule, 0);
  if(rc == SQLITE_OK) rc = sqlite3_create_module(db, "lines_glob", &linesGlobModule, 0);
  return rc;
}
