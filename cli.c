#include <sqlite3.h>
#include <stdio.h>
#include "lines.h"

int main(int argc, char *argv[]) {
    sqlite3 *db;
    sqlite3_stmt *res;
    int rc = sqlite3_auto_extension((void(*)())sqlite3_lines_init);

    if (rc != SQLITE_OK) {        
      fprintf(stderr, "Could not load sqlite3_lines_init: %s\n", sqlite3_errmsg(db));
      sqlite3_close(db);
      return 1;
    }

    rc = sqlite3_open(":memory:", &db);
    
    if (rc != SQLITE_OK) {        
      fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(db));
      sqlite3_close(db);
      return 1;
    }

    char * query = sqlite3_mprintf("with base as (SELECT contents as d from lines_read('/dev/stdin')) select %s from base", argv[1]);
    if(query==NULL) {
      fprintf(stderr, "Cannot allocate memory\n");
      sqlite3_close(db);
      return 1;
    }

    rc = sqlite3_prepare_v2(db, query, -1, &res, 0);    
    
    if (rc != SQLITE_OK) {
      fprintf(stderr, "Failed to fetch data: %s\n", sqlite3_errmsg(db));
      sqlite3_close(db);
      return 1;
    }    
    
    while( SQLITE_ROW==sqlite3_step(res) ){
      printf("%s\n", sqlite3_column_text(res, 0));
    }
    
    sqlite3_finalize(res);
    sqlite3_close(db);
    
    return 0;
}