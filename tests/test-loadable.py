import sqlite3
import unittest
import time
import os

EXT_PATH="./dist/lines0"

def connect():
  db = sqlite3.connect(":memory:")

  db.execute("create table base_functions as select name from pragma_function_list")
  db.execute("create table base_modules as select name from pragma_module_list")

  db.enable_load_extension(True)
  db.load_extension(EXT_PATH)

  db.execute("create temp table loaded_functions as select name from pragma_function_list where name not in (select name from base_functions) order by name")
  db.execute("create temp table loaded_modules as select name from pragma_module_list where name not in (select name from base_modules) order by name")

  db.row_factory = sqlite3.Row
  return db


db = connect()

def execute_all(sql, args=None):
  return list(map(lambda x: dict(x), db.execute(sql, args).fetchall()))

class TestLines(unittest.TestCase):
  def test_funcs(self):
    funcs = list(map(lambda a: a[0], db.execute("select name from loaded_functions").fetchall()))
    self.assertEqual(funcs, [
      'lines_debug',
      'lines_version',
    ])
  def test_modules(self):
    modules = list(map(lambda a: a[0], db.execute("select name from loaded_modules").fetchall()))
    self.assertEqual(modules, [
      "lines",
      "lines_read",
    ])
  def test_lines_version(self):
    v, = db.execute("select lines_version()").fetchone()
    self.assertEqual(v, "v0.0.-1")

  def test_lines_debug(self):
    debug, = db.execute("select lines_debug()").fetchone()
    self.assertEqual(debug.split('\n')[0], "Version: v0.0.-1")
    self.assertTrue(debug.split('\n')[1].startswith("Date: "))
  def test_lines(self):
    # TODO document should be non-null
    self.assertEqual(execute_all("select rowid, delimiter, document, line from lines(?)", ["a\nb"]), [
      {"rowid": 1, "delimiter": "\n", "document": None, "line": "a"},
      {"rowid": 2, "delimiter": "\n", "document": None, "line": "b"},
    ])

  def test_lines_read(self):
    d = db.execute("select rowid, line from lines_read(?)", ['test_files/test.txt']).fetchall()
    self.assertEqual(len(d), 3) 
    self.assertEqual(list(map(lambda x: dict(x), d)), [
      {"rowid": 1, "line": "line1"},
      {"rowid": 2, "line": "line numba 2"},
      {"rowid": 3, "line": "line 3 baby"},
    ])
  
  def test_lines_read_crlf(self):
    d = db.execute("select rowid, line from lines_read(?)", ['test_files/crlf.txt']).fetchall()
    self.assertEqual(len(d), 3) 
    self.assertEqual(list(map(lambda x: dict(x), d)), [
      {"rowid": 1, "line": "aaa"},
      {"rowid": 2, "line": "bbb"},
      {"rowid": 3, "line": "ccc"},
    ])

  def test_lines_read_delim(self):
    d = db.execute("select rowid, line from lines_read(?, ?);", ['test_files/pipe.txt', '|']).fetchall()
    self.assertEqual(len(d), 5) 
    self.assertEqual(list(map(lambda x: dict(x), d)), [
      {"rowid": 1, "line": "a"},
      {"rowid": 2, "line": "b"},
      {"rowid": 3, "line": "c"},
      {"rowid": 4, "line": "d"},
      {"rowid": 5, "line": "yo"},
    ])
  
  def test_lines_read_big(self):
    if os.environ.get('ENV') == "CI":
      self.skipTest("Skipping large file testing on CI environments"
      )
    
    s1 = time.process_time()
    d = db.execute("select count(*) as count from lines_read(?);", ['test_files/big.txt']).fetchall()
    e1 = time.process_time()
    self.assertEqual(d[0]["count"], 1000001) 

    s2 = time.process_time()
    d = db.execute("select count(*), line from lines_read(?, char(10)) where rowid = 0;", ['test_files/big.txt']).fetchall()
    e2 = time.process_time()
    self.assertEqual(d[0]["count(*)"], 1) 
    self.assertEqual(d[0]["line"], "1") 
    duration_ratio = (e2-s2) / (e1-s1)
    self.assertLess(duration_ratio, .01)
    
    d = db.execute("explain query plan select line from lines_read(?, char(10)) where rowid = 0;", ['test_files/big.txt']).fetchall()
    
    self.assertEqual(len(d), 1)
    self.assertEqual(d[0]["id"], 2)
    self.assertEqual(d[0]["parent"], 0)
    self.assertEqual(d[0]["notused"], 0)
    self.assertEqual(d[0]["detail"], "SCAN lines_read VIRTUAL TABLE INDEX 2:")
    
  def test_lines_read_big_1line(self):
    if os.environ.get('ENV') == "CI":
      self.skipTest("Skipping large file testing on CI environments"
      )
    
    # TODO should be caught and thrown as OperationalError at sqlite_lines-level (with sqlite3_limit) and not sqlite-level
    with self.assertRaisesRegex(sqlite3.DataError, 'string or blob too big'):
      db.execute("select length(line) from lines_read('test_files/big-line-line.txt');").fetchall()
  
if __name__ == '__main__':
    unittest.main()