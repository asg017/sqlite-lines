#include "sqlite3ext.h"

SQLITE_EXTENSION_INIT1

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>

static void linesVersionFunc(
  sqlite3_context *context,
  int argc,
  sqlite3_value **argv 
){ 
  sqlite3_result_text(context, "0.0.0", -1, SQLITE_STATIC);           
}

static void linesDebugFunc(
  sqlite3_context *context,
  int argc,
  sqlite3_value **arg
) {
  const char * debug = sqlite3_mprintf("Version: 0.0.0\nDate: %s", SQLITE_LINES_DATE);
  sqlite3_result_text(context, debug, (int) strlen(debug), SQLITE_TRANSIENT);
}

typedef struct lines_read_cursor lines_read_cursor;
struct lines_read_cursor {
  sqlite3_vtab_cursor base;  /* Base class - must be first */
  FILE *fp;
  size_t curLineLength;
  char* curLineContents;
  char delim;
  int idxNum;
  int rowid_eq_yielded;
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
#define LINES_READ_COLUMN_ROWID          -1
#define LINES_READ_COLUMN_CONTENTS        0
#define LINES_READ_COLUMN_PATH            1
#define LINES_READ_COLUMN_DELIM           2


#define LINES_READ_INDEX_FULL     1
#define LINES_READ_INDEX_ROWID_EQ 2

  (void)pUnused;
  (void)argcUnused;
  (void)argvUnused;
  (void)pzErrUnused;
  rc = sqlite3_declare_vtab(db,
     "CREATE TABLE x(contents text,"
     "path hidden, delim hidden)");
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
  pCur->curLineLength = getdelim(&pCur->curLineContents, &len, pCur->delim, pCur->fp);
  return SQLITE_OK;
}

/*
** Return TRUE if the cursor has been moved off of the last
** row of output.
*/
static int linesReadEof(sqlite3_vtab_cursor *cur){
  lines_read_cursor *pCur = (lines_read_cursor*)cur;
  if(pCur->idxNum==LINES_READ_INDEX_ROWID_EQ) {
    if(pCur->rowid_eq_yielded) return 1;
    pCur->rowid_eq_yielded = 1;
    return 0;
  }
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
      int trim = 0;
      if(pCur->curLineLength > 0 && pCur->curLineContents[pCur->curLineLength-1] == pCur->delim) {
        if(pCur->curLineLength > 1 && pCur->curLineContents[pCur->curLineLength-2] == '\r') trim = 2;
        else trim = 1;
      }

      sqlite3_result_text(ctx, pCur->curLineContents, pCur->curLineLength-trim, SQLITE_TRANSIENT);
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
  if(pCur->fp != NULL) {
    fclose(pCur->fp);
  }
  char delim = '\n';
  if(argc > 1) {
    const char * s = (const char * ) sqlite3_value_text(argv[1]);
    delim = s[0];
  }
  switch(sqlite3_value_type(argv[0])) {
    case SQLITE_TEXT: {
      const char * path = (const char * ) sqlite3_value_text(argv[0]);
  
      int errnum;
      pCur->fp = fopen(path, "r");
      if (pCur->fp == NULL) {
        int errnum;
        errnum = errno;
        fprintf(stderr, "Error opening file at %s: %s\n", path, strerror( errnum ));
        return SQLITE_ERROR;
      }
      break;
    }
    case SQLITE_BLOB: {
      int nByte = sqlite3_value_bytes(argv[0]);
      void *pData = (void *) sqlite3_value_blob(argv[0]);
      int errnum;
      pCur->fp = fmemopen(pData, nByte, "r");
      if (pCur->fp == NULL) {
        int errnum;
        errnum = errno;
        fprintf(stderr, "Error reading, size=%d: %s\n", nByte, strerror( errnum ));
        return SQLITE_ERROR;
      }
      break;
    }

  }
  size_t len = 0;
  pCur->curLineLength = getdelim(&pCur->curLineContents, &len, delim, pCur->fp);
  pCur->iRowid = 0;
  pCur->delim = delim;
  pCur->idxNum = idxNum;

  if(pCur->idxNum == LINES_READ_INDEX_ROWID_EQ) {
    pCur->rowid_eq_yielded = 0;
    int targetRowid = sqlite3_value_int64(argv[2]);
    //printf("rowid eq, argc=%d, targetRowid=%d, pCur->curLineLength=%d\n", argc, targetRowid, pCur->curLineLength);
    while(pCur->iRowid < targetRowid && pCur->curLineLength >= 0) {
      //printf("loop %d\n", pCur->curLineLength);
      size_t len = 0;
  
      pCur->curLineLength = getdelim(&pCur->curLineContents, &len, delim, pCur->fp);
      pCur->iRowid++;
    }
    //printf("rowid eq, pCur->iRowid=%d, pCur->curLineLength=%d\n", pCur->iRowid, pCur->curLineLength);
  }
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
  int hasDelim = 0;
  int hasRowidEq = 0;
  for(int i=0; i<pIdxInfo->nConstraint; i++){
    const struct sqlite3_index_constraint *pCons = &pIdxInfo->aConstraint[i];
    //printf("i=%d iColumn=%d, op=%d, usable=%d\n", i, pCons->iColumn, pCons->op, pCons->usable);
    switch(pCons->iColumn) {
      case LINES_READ_COLUMN_ROWID: {
        // TODO also support SQLITE_INDEX_CONSTRAINT_GT, SQLITE_INDEX_CONSTRAINT_LE, SQLITE_INDEX_CONSTRAINT_LIMIT, SQLITE_INDEX_CONSTRAINT_OFFSET
        // have new HEAD/TAIL idxNum when one of GT OR LT is given
        if(pCons->op==SQLITE_INDEX_CONSTRAINT_EQ && pCons->usable) {
            hasRowidEq = 1;
            // TODO this assumes a LINES_READ_COLUMN_DELIM constraint was given
            pIdxInfo->aConstraintUsage[i].argvIndex = 3;
            pIdxInfo->aConstraintUsage[i].omit = 1;
        }
        break;
      }
      case LINES_READ_COLUMN_PATH: {
        // TODO assert this is SQLITE_INDEX_CONSTRAINT_EQ, can't otherwise
        if(!pCons->usable) return SQLITE_CONSTRAINT;
        hasPath = 1;
        pIdxInfo->aConstraintUsage[i].argvIndex = 1;
        pIdxInfo->aConstraintUsage[i].omit = 1;
        break;
      }
      case LINES_READ_COLUMN_DELIM: {
        // TODO assert this is SQLITE_INDEX_CONSTRAINT_EQ, can't otherwise
        if(!pCons->usable) return SQLITE_CONSTRAINT;
        hasDelim = 1;
        pIdxInfo->aConstraintUsage[i].argvIndex = 2;
        pIdxInfo->aConstraintUsage[i].omit = 1;
        break;
      }
    }
  }
  if(!hasPath) {
    pVTab->zErrMsg = sqlite3_mprintf("path argument is required");
    return SQLITE_ERROR;
  }
  if(hasRowidEq) {
    pIdxInfo->idxNum = LINES_READ_INDEX_ROWID_EQ;
    pIdxInfo->estimatedCost = (double)1;
    pIdxInfo->estimatedRows = 1;
    //pIdxInfo->idxFlags |= SQLITE_INDEX_SCAN_UNIQUE;
    return SQLITE_OK;  
  }
  pIdxInfo->idxNum = LINES_READ_INDEX_FULL;
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
  if(rc == SQLITE_OK) rc = sqlite3_create_function(db, "lines_version", 0, SQLITE_UTF8|SQLITE_INNOCUOUS|SQLITE_DETERMINISTIC, 0, linesVersionFunc, 0, 0); 
  if(rc == SQLITE_OK) rc = sqlite3_create_function(db, "lines_debug", 0, SQLITE_UTF8|SQLITE_INNOCUOUS|SQLITE_DETERMINISTIC, 0, linesDebugFunc, 0, 0); 

  if(rc == SQLITE_OK) rc = sqlite3_create_module(db, "lines_read", &linesReadModule, 0);
  //if(rc == SQLITE_OK) rc = sqlite3_create_module(db, "lines_readgz", &linesReadGzModule, 0);
  return rc;
}
