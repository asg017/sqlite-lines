use sqlite_loadable::prelude::*;
use sqlite_loadable::{
    api,
    table::{ConstraintOperator, IndexInfo, VTab, VTabArguments, VTabCursor},
    BestIndexError, Result,
};

use sqlite_reader::{SqliteReader, READER_POINTER_NAME};

use std::{io::Read, marker::PhantomData, mem, os::raw::c_int};

use std::fs::File;
use std::io::BufRead;

use std::{
    io::{BufReader, Lines},
    iter::Peekable,
};

static CREATE_SQL: &str = "CREATE TABLE x(line text, path text hidden)";
enum Columns {
    Line,
    Path,
}
fn column(index: i32) -> Option<Columns> {
    match index {
        0 => Some(Columns::Line),
        1 => Some(Columns::Path),
        _ => None,
    }
}
#[repr(C)]
pub struct LinesReadTable {
    /// must be first
    base: sqlite3_vtab,
}

impl<'vtab> VTab<'vtab> for LinesReadTable {
    type Aux = ();
    type Cursor = LinesReadCursor<'vtab>;

    fn connect(
        _db: *mut sqlite3,
        _aux: Option<&()>,
        _args: VTabArguments,
    ) -> Result<(String, LinesReadTable)> {
        let base: sqlite3_vtab = unsafe { mem::zeroed() };
        let vtab = LinesReadTable { base };
        // TODO db.config(VTabConfig::Innocuous)?;
        Ok((CREATE_SQL.to_owned(), vtab))
    }
    fn destroy(&self) -> Result<()> {
        println!("destroy?");
        Ok(())
    }

    fn best_index(&self, mut info: IndexInfo) -> core::result::Result<(), BestIndexError> {
        let mut has_source = false;
        for mut constraint in info.constraints() {
            match column(constraint.column_idx()) {
                Some(Columns::Path) => {
                    if constraint.usable() && constraint.op() == Some(ConstraintOperator::EQ) {
                        constraint.set_omit(true);
                        constraint.set_argv_index(1);
                        has_source = true;
                    } else {
                        return Err(BestIndexError::Constraint);
                    }
                }

                _ => (),
            }
        }
        if !has_source {
            return Err(BestIndexError::Error);
        }
        info.set_estimated_cost(100000.0);
        info.set_estimated_rows(100000);
        info.set_idxnum(2);

        Ok(())
    }

    fn open(&mut self) -> Result<LinesReadCursor<'_>> {
        Ok(LinesReadCursor::new())
    }
}

type LinesIter = Option<Peekable<Lines<BufReader<Box<dyn Read>>>>>;
#[repr(C)]
pub struct LinesReadCursor<'vtab> {
    /// Base class. Must be first
    base: sqlite3_vtab_cursor,
    iter: LinesIter,
    curr: Option<String>,
    phantom: PhantomData<&'vtab LinesReadTable>,
}
impl LinesReadCursor<'_> {
    fn new<'vtab>() -> LinesReadCursor<'vtab> {
        let base: sqlite3_vtab_cursor = unsafe { mem::zeroed() };
        LinesReadCursor {
            base,
            iter: None,
            curr: None,
            phantom: PhantomData,
        }
    }
}

impl VTabCursor for LinesReadCursor<'_> {
    fn filter(
        &mut self,
        _idx_num: c_int,
        _idx_str: Option<&str>,
        values: &[*mut sqlite3_value],
    ) -> Result<()> {
        let input: Box<dyn Read> = match unsafe {
            api::value_pointer::<Box<dyn SqliteReader>>(values.get(0).unwrap(), READER_POINTER_NAME)
        } {
            None => {
                let path = api::value_text(values.get(0).unwrap()).unwrap();

                let file = File::open(path).unwrap();
                Box::new(file)
            }
            Some(reader) => unsafe { (*reader).generate().unwrap() },
        };
        self.iter = Some(
            BufReader::with_capacity(32 * 1024, input)
                .lines()
                .peekable(),
        );
        self.next()
    }

    fn next(&mut self) -> Result<()> {
        self.curr = self.iter.as_mut().unwrap().next().map(|x| x.unwrap());
        Ok(())
    }

    fn eof(&self) -> bool {
        //println!("eof {}", );
        self.curr.is_none()
    }

    fn column(&self, context: *mut sqlite3_context, i: c_int) -> Result<()> {
        match column(i) {
            Some(Columns::Line) => {
                api::result_text(context, self.curr.as_ref().unwrap()).unwrap();
            }
            Some(Columns::Path) => (),
            _ => (),
        }
        Ok(())
    }

    fn rowid(&self) -> Result<i64> {
        Ok(1)
    }
}
