pub mod lines_read;
use sqlite_loadable::prelude::*;
use sqlite_loadable::{api, define_scalar_function, define_table_function, FunctionFlags, Result};

pub fn lines_version(context: *mut sqlite3_context, _values: &[*mut sqlite3_value]) -> Result<()> {
    api::result_text(context, format!("xv{}", env!("CARGO_PKG_VERSION")))?;
    Ok(())
}

pub fn lines_debug(context: *mut sqlite3_context, _values: &[*mut sqlite3_value]) -> Result<()> {
    api::result_text(
        context,
        format!(
            "Version: v{}
Source: {}
",
            env!("CARGO_PKG_VERSION"),
            env!("GIT_HASH")
        ),
    )?;
    Ok(())
}

#[sqlite_entrypoint]
pub fn sqlite3_lines_init(db: *mut sqlite3) -> Result<()> {
    define_scalar_function(
        db,
        "lines_version",
        0,
        lines_version,
        FunctionFlags::DETERMINISTIC,
    )?;
    define_scalar_function(
        db,
        "lines_debug",
        0,
        lines_debug,
        FunctionFlags::DETERMINISTIC,
    )?;
    define_table_function::<lines_read::LinesReadTable>(db, "lines_read", None)?;
    Ok(())
}
