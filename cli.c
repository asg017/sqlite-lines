#include <sqlite3.h>
#include <stdio.h>
#include "lines.h"
#include <unistd.h>

// TODO
//  1. version
//  2. insert
//  3. --where, --groupby ?
//  4. --header?
//  5. CSV output proper?
//  6. JSON output?
//  7. --input or -i file
//  8. --dry-run flag
int main(int argc, char *argv[]) {
    sqlite3 *db;
    sqlite3_stmt *stmt;
    int rc;
    int opt;

    if(argc < 1) {
      fprintf(stderr, "USAGE: sqlite-lines select [where] [groupby] --header");
      return 1;
    }
    
    rc = sqlite3_auto_extension((void(*)())sqlite3_lines_init);
    
    if (rc != SQLITE_OK) {        
      fprintf(stderr, "Could not load sqlite3_lines_init: %s\n", sqlite3_errmsg(db));
      sqlite3_close(db);
      return 1;
    }

    char * file = "/dev/stdin";
    /*while ((opt = getopt(argc, argv, "i:")) != -1) {
      switch (opt) {
        case 'i':
          file = optarg;
          break;
        default: 
          fprintf(stderr, "Usage: %s [-t nsecs] [-n] name\n",argv[0]);
          return 1;
      }
    }*/

    rc = sqlite3_open(":memory:", &db);
    
    if (rc != SQLITE_OK) {        
      fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(db));
      sqlite3_close(db);
      return 1;
    }
    sqlite3_str *query = sqlite3_str_new(db);
    sqlite3_str_appendall(query, "with base as (SELECT line, line as d from lines_read(?1))");
    
    int argsCount = optind - argc;
    sqlite3_str_appendf(query, "select %s", argv[optind]);
    sqlite3_str_appendall(query, " from base");
    if(argc > 2)
      sqlite3_str_appendf(query, " where %s", argv[2]);
    if(argc > 3)
      sqlite3_str_appendf(query, " group by %s", argv[3]);
    
    char * q = sqlite3_str_finish(query);

    if(q==NULL) {
      fprintf(stderr, "Cannot allocate memory\n");
      sqlite3_close(db);
      return 1;
    }

    rc = sqlite3_prepare_v2(db, q, -1, &stmt, 0);    
    
    if (rc != SQLITE_OK) {
      fprintf(stderr, "Failed to fetch data: %s\n", sqlite3_errmsg(db));
      sqlite3_close(db);
      return 1;
    }
    
    rc = sqlite3_bind_text(stmt, 1, file, -1, SQLITE_TRANSIENT);
    if (rc != SQLITE_OK) {
      fprintf(stderr, "error binding: %s\n", sqlite3_errmsg(db));
      sqlite3_close(db);
      return 1;
    }

    int cols = sqlite3_column_count(stmt);
    // TODO handle errors, SQLITE_DONE, etc.
    while( SQLITE_ROW==sqlite3_step(stmt) ){
      for(int i = 0; i < cols; i++) {
        printf("%s", sqlite3_column_text(stmt, i));
        if(i != cols-1)
          printf(",");
      }
       printf("\n");
      
    }
    sqlite3_free(q);
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    return 0;
}