from datasette import hookimpl
import sqlite_lines

from datasette_sqlite_lines.version import __version_info__, __version__ 

@hookimpl
def prepare_connection(conn, database, datasette):
    config = (
        datasette.plugin_config("datasette-sqlite-lines", database=database)
        or {}
    )
    
    conn.enable_load_extension(True)
    
    if config.get("UNSAFE_allow_filesystem_read"):
       sqlite_lines.load(conn)
    else:
      sqlite_lines.load_no_read(conn)

    conn.enable_load_extension(False)